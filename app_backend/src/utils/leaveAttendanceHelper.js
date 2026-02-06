const Attendance = require('../models/Attendance');
const Leave = require('../models/Leave');
const Staff = require('../models/Staff');
const Company = require('../models/Company');
const LeaveTemplate = require('../models/LeaveTemplate');

/**
 * Get shift timings from company settings
 * @param {Object} company - Company document
 * @param {Object} staff - Staff document (optional, for staff-specific shift)
 * @returns {Object} - { startTime, endTime } in HH:mm format
 */
const getShiftTimings = (company, staff = null) => {
    // Default shift timings
    let startTime = '09:30';
    let endTime = '18:30';

    // Check company settings for shifts
    if (company && company.settings && company.settings.attendance && company.settings.attendance.shifts) {
        const shifts = company.settings.attendance.shifts;
        if (Array.isArray(shifts) && shifts.length > 0) {
            // Use first shift as default (or match staff's shiftName if provided)
            const shift = staff && staff.shiftName
                ? shifts.find(s => s.name === staff.shiftName) || shifts[0]
                : shifts[0];
            
            if (shift.startTime) startTime = shift.startTime;
            if (shift.endTime) endTime = shift.endTime;
        }
    }

    return { startTime, endTime };
};

/**
 * Calculate work hours from shift timings
 * @param {String} startTime - Shift start time in HH:mm format
 * @param {String} endTime - Shift end time in HH:mm format
 * @returns {Number} - Work hours (in hours, e.g., 8.5 for 8 hours 30 minutes)
 */
const calculateWorkHoursFromShift = (startTime, endTime) => {
    try {
        const [startHours, startMins] = startTime.split(':').map(Number);
        const [endHours, endMins] = endTime.split(':').map(Number);
        
        const startMinutes = startHours * 60 + startMins;
        const endMinutes = endHours * 60 + endMins;
        const diffMinutes = endMinutes - startMinutes;
        
        return diffMinutes / 60.0; // Convert to hours
    } catch (error) {
        console.error('[LeaveAttendanceHelper] Error calculating work hours:', error);
        return 8.0; // Default 8 hours
    }
};

/**
 * Mark attendance as "Present" for all dates covered by an approved leave
 * This is called when a leave is approved
 * Checks leaveTemplate to ensure leave is valid and within limits
 * @param {Object} leave - The approved leave document
 */
const markAttendanceForApprovedLeave = async (leave) => {
    try {
        if (!leave || !/^approved$/i.test(leave.status)) {
            return;
        }

        const { employeeId, startDate, endDate, businessId, leaveType, days } = leave;
        
        // Fetch staff with leaveTemplateId populated
        const staff = await Staff.findById(employeeId).populate('leaveTemplateId');
        if (!staff) {
            console.error(`[LeaveAttendanceHelper] Staff not found: ${employeeId}`);
            return;
        }

        // Check if staff has a leaveTemplateId
        if (!staff.leaveTemplateId) {
            console.log(`[LeaveAttendanceHelper] Staff ${employeeId} has no leaveTemplateId, skipping attendance marking`);
            return;
        }

        // Get leaveTemplate
        const leaveTemplate = await LeaveTemplate.findById(staff.leaveTemplateId);
        if (!leaveTemplate) {
            console.error(`[LeaveAttendanceHelper] LeaveTemplate not found: ${staff.leaveTemplateId}`);
            return;
        }

        // Check if leaveType exists in template
        if (!leaveTemplate.leaveTypes || !Array.isArray(leaveTemplate.leaveTypes)) {
            console.log(`[LeaveAttendanceHelper] LeaveTemplate has no leaveTypes array`);
            return;
        }

        const leaveConfig = leaveTemplate.leaveTypes.find(
            t => t.type && t.type.toLowerCase() === leaveType.toLowerCase()
        );

        if (!leaveConfig) {
            console.log(`[LeaveAttendanceHelper] LeaveType "${leaveType}" not found in template`);
            return;
        }

        // Check if user has already exceeded their leave limit (including pending leaves)
        const leaveDate = new Date(startDate);
        // Use the calculateAvailableLeaves function defined in this file
        const leaveInfo = await calculateAvailableLeaves(staff, leaveType, leaveDate);
        
        // Check if there are pending leaves that would exceed the limit
        // We need to check if current approved + pending leaves exceed the limit
        // Handle both "Casual" and "Casual Leave" formats
        const leaveTypeLower = leaveType.toLowerCase().trim();
        const isCasual = leaveTypeLower === 'casual' || leaveTypeLower.startsWith('casual');
        const targetYear = leaveDate.getFullYear();
        const targetMonth = leaveDate.getMonth();
        const rangeStart = isCasual
            ? new Date(targetYear, targetMonth, 1)
            : new Date(targetYear, 0, 1);
        const rangeEnd = isCasual
            ? new Date(targetYear, targetMonth + 1, 0, 23, 59, 59)
            : new Date(targetYear, 11, 31, 23, 59, 59);

        // Get all pending leaves of this type in the period
        const pendingLeaves = await Leave.find({
            employeeId: employeeId,
            _id: { $ne: leave._id }, // Exclude current leave
            leaveType: { $regex: new RegExp(`^${leaveType}$`, 'i') },
            status: 'Pending',
            $or: [
                { startDate: { $gte: rangeStart, $lte: rangeEnd } },
                { endDate: { $gte: rangeStart, $lte: rangeEnd } },
                { startDate: { $lte: rangeStart }, endDate: { $gte: rangeEnd } }
            ]
        });

        const pendingDays = pendingLeaves.reduce((sum, l) => sum + l.days, 0);
        
        // If total (used + current + pending) exceeds limit, don't mark as present
        if (leaveInfo.totalAvailable !== null && (leaveInfo.used + days + pendingDays) > leaveInfo.totalAvailable) {
            console.log(`[LeaveAttendanceHelper] Leave limit would be exceeded. Used: ${leaveInfo.used}, Current: ${days}, Pending: ${pendingDays}, Total Available: ${leaveInfo.totalAvailable}`);
            return;
        }

        // Get company for shift timings
        const company = await Company.findById(businessId);
        const { startTime, endTime } = getShiftTimings(company, staff);
        const workHours = calculateWorkHoursFromShift(startTime, endTime);

        // Generate all dates between startDate and endDate (inclusive)
        const dates = [];
        const start = new Date(startDate);
        const end = new Date(endDate);
        
        // Set time to start of day to avoid timezone issues
        start.setHours(0, 0, 0, 0);
        end.setHours(0, 0, 0, 0);
        
        const currentDate = new Date(start);
        while (currentDate <= end) {
            dates.push(new Date(currentDate));
            currentDate.setDate(currentDate.getDate() + 1);
        }

        // Mark attendance as "Present" for each date with shift timings
        for (const date of dates) {
            // Check if attendance record already exists
            const startOfDay = new Date(date);
            startOfDay.setHours(0, 0, 0, 0);
            const endOfDay = new Date(date);
            endOfDay.setHours(23, 59, 59, 999);

            // Create punch in/out times based on shift timings
            const [startHours, startMins] = startTime.split(':').map(Number);
            const [endHours, endMins] = endTime.split(':').map(Number);
            
            const punchIn = new Date(date);
            punchIn.setHours(startHours, startMins, 0, 0);
            
            const punchOut = new Date(date);
            punchOut.setHours(endHours, endMins, 0, 0);

            let attendance = await Attendance.findOne({
                employeeId: employeeId,
                date: { $gte: startOfDay, $lte: endOfDay }
            });

            if (attendance) {
                // Update existing attendance record
                attendance.status = leave.leaveType === 'Half Day' ? 'Half Day' : 'On Leave';
                // Clear punch times only for full day leaves
                if (leave.leaveType !== 'Half Day') {
                    attendance.punchIn = undefined;
                    attendance.punchOut = undefined;
                    attendance.workHours = 0;
                }
                attendance.approvedBy = leave.approvedBy;
                attendance.approvedAt = leave.approvedAt || new Date();
                attendance.remarks = (attendance.remarks || '') + (leave.leaveType === 'Half Day' ? ` [Half Day - ${leave.session}]` : '');
                await attendance.save();
            } else {
                // Create new attendance record
                await Attendance.create({
                    employeeId: employeeId,
                    user: employeeId, // For backward compatibility
                    date: startOfDay,
                    status: leave.leaveType === 'Half Day' ? 'Half Day' : 'On Leave',
                    approvedBy: leave.approvedBy,
                    approvedAt: leave.approvedAt || new Date(),
                    businessId: businessId,
                    workHours: 0,
                    remarks: leave.leaveType === 'Half Day' ? `Half Day - ${leave.session}` : ''
                });
            }
        }

        console.log(`[LeaveAttendanceHelper] Marked attendance as On Leave for ${dates.length} days for leave ${leave._id}`);
    } catch (error) {
        console.error('[LeaveAttendanceHelper] Error marking attendance for approved leave:', error);
        throw error;
    }
};

/**
 * Revert attendance for a deleted or cancelled leave
 * @param {Object} leave - The leave document
 */
const revertAttendanceForDeletedLeave = async (leave) => {
    try {
        if (!leave) return;

        const { employeeId, startDate, endDate } = leave;
        
        // Generate all dates between startDate and endDate (inclusive)
        const dates = [];
        const start = new Date(startDate);
        const end = new Date(endDate);
        
        start.setHours(0, 0, 0, 0);
        end.setHours(0, 0, 0, 0);
        
        const currentDate = new Date(start);
        while (currentDate <= end) {
            dates.push(new Date(currentDate));
            currentDate.setDate(currentDate.getDate() + 1);
        }

        for (const date of dates) {
            const startOfDay = new Date(date);
            startOfDay.setHours(0, 0, 0, 0);
            const endOfDay = new Date(date);
            endOfDay.setHours(23, 59, 59, 999);

            const attendance = await Attendance.findOne({
                employeeId: employeeId,
                date: { $gte: startOfDay, $lte: endOfDay }
            });

            if (attendance && (attendance.status === 'On Leave' || attendance.status === 'Half Day')) {
                // If it was "On Leave" or "Half Day", delete the record or mark as Absent/Pending
                // Deleting is cleaner if there was no actual punch-in/out
                if (!attendance.punchIn && !attendance.punchOut) {
                     // If it was purely generated from leave, delete it
                     await Attendance.deleteOne({ _id: attendance._id });
                } else {
                    // If there was actual activity, revert status
                    // If they have punchIn, it should probably be 'Present' or 'Pending'
                    // For now, let's use 'Pending' as it's the default for working days
                    attendance.status = 'Pending';
                    attendance.remarks = (attendance.remarks || '')
                        .replace(/On Leave/i, '')
                        .replace(/\[Half Day - Session [12]\]/i, '')
                        .replace(/Half Day - Session [12]/i, '')
                        .trim();
                    attendance.approvedBy = undefined;
                    attendance.approvedAt = undefined;
                    await attendance.save();
                }
            }
        }
        console.log(`[LeaveAttendanceHelper] Reverted attendance for ${dates.length} days for leave ${leave._id}`);
    } catch (error) {
        console.error('[LeaveAttendanceHelper] Error reverting attendance for deleted leave:', error);
    }
};

/**
 * Calculate available leaves considering carryForward logic
 * @param {Object} staff - Staff document with populated leaveTemplateId
 * @param {String} leaveType - Type of leave (e.g., 'Casual', 'Sick')
 * @param {Date} targetDate - Date for which to calculate available leaves (defaults to current month)
 * @returns {Object} - { baseLimit, carriedForward, totalAvailable, used, balance }
 */
const calculateAvailableLeaves = async (staff, leaveType, targetDate = new Date()) => {
    if (!staff || !staff.leaveTemplateId) {
        return { baseLimit: null, carriedForward: 0, totalAvailable: null, used: 0, balance: 999 };
    }

    const template = staff.leaveTemplateId;
    let baseLimit = null;
    let carryForward = false;

    // Find leave config from template
    if (template.leaveTypes && Array.isArray(template.leaveTypes)) {
        const leaveConfig = template.leaveTypes.find(
            t => t.type && t.type.toLowerCase() === leaveType.toLowerCase()
        );
        if (leaveConfig) {
            baseLimit = leaveConfig.days || leaveConfig.limit || null;
            carryForward = leaveConfig.carryForward === true;
        }
    }

    if (baseLimit === null) {
        return { baseLimit: null, carriedForward: 0, totalAvailable: null, used: 0, balance: 999 };
    }

        // Determine if this is a monthly (Casual) or yearly (Sick) leave
        // Handle both "Casual" and "Casual Leave" formats
        const leaveTypeLower = leaveType.toLowerCase().trim();
        const isCasual = leaveTypeLower === 'casual' || leaveTypeLower.startsWith('casual');
    const targetYear = targetDate.getFullYear();
    const targetMonth = targetDate.getMonth();

    // Calculate range for current period
    const rangeStart = isCasual
        ? new Date(targetYear, targetMonth, 1)
        : new Date(targetYear, 0, 1);
    const rangeEnd = isCasual
        ? new Date(targetYear, targetMonth + 1, 0, 23, 59, 59)
        : new Date(targetYear, 11, 31, 23, 59, 59);

    // Build a flexible regex that handles:
    // 1. Case-insensitivity
    // 2. Optional "Leave" suffix
    // 3. Leading/trailing whitespace
    const flexibleRegex = new RegExp(`^\\s*${normalizedType}(\\s+leave)?\\s*$`, 'i');
    
    // Get ALL relevant leaves in current period (Approved and Pending)
    const relevantLeaves = await Leave.find({
        employeeId: staff._id,
        leaveType: { $regex: flexibleRegex },
        status: { $regex: /^(approved|pending)$/i },
        $or: [
            { startDate: { $gte: rangeStart, $lte: rangeEnd } },
            { endDate: { $gte: rangeStart, $lte: rangeEnd } },
            { startDate: { $lte: rangeStart }, endDate: { $gte: rangeEnd } }
        ]
    });

    let approvedDays = 0;
    let pendingDays = 0;

    relevantLeaves.forEach(l => {
        const lStart = new Date(l.startDate);
        const lEnd = new Date(l.endDate);
        
        // Calculate overlap with target period
        const overlapStart = lStart > rangeStart ? lStart : rangeStart;
        const overlapEnd = lEnd < rangeEnd ? lEnd : rangeEnd;
        
        if (overlapEnd >= overlapStart) {
            // Normalize to midnight for accurate day counting
            const oStart = new Date(overlapStart.getFullYear(), overlapStart.getMonth(), overlapStart.getDate());
            const oEnd = new Date(overlapEnd.getFullYear(), overlapEnd.getMonth(), overlapEnd.getDate());
            const diffTime = Math.abs(oEnd - oStart);
            const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;
            
            if (/^approved$/i.test(l.status)) {
                approvedDays += diffDays;
            } else if (/^pending$/i.test(l.status)) {
                pendingDays += diffDays;
            }
        }
    });

    const used = approvedDays;
    const pending = pendingDays;

    // Calculate carried forward leaves if carryForward is enabled
    let carriedForward = 0;
    if (carryForward) {
        // For monthly leaves (Casual), check previous month
        // For yearly leaves (Sick), check previous year
        if (isCasual) {
            // Previous month
            const prevMonth = targetMonth === 0 ? 11 : targetMonth - 1;
            const prevYear = targetMonth === 0 ? targetYear - 1 : targetYear;
            const prevRangeStart = new Date(prevYear, prevMonth, 1);
            const prevRangeEnd = new Date(prevYear, prevMonth + 1, 0, 23, 59, 59);

            const prevMonthLeaves = await Leave.find({
                employeeId: staff._id,
                leaveType: { $regex: flexibleRegex },
                status: { $regex: /^approved$/i },
                $or: [
                    { startDate: { $gte: prevRangeStart, $lte: prevRangeEnd } },
                    { endDate: { $gte: prevRangeStart, $lte: prevRangeEnd } },
                    { startDate: { $lte: prevRangeStart }, endDate: { $gte: prevRangeEnd } }
                ]
            });

            let prevApprovedDays = 0;
            prevMonthLeaves.forEach(l => {
                const lStart = new Date(l.startDate);
                const lEnd = new Date(l.endDate);
                const overlapStart = lStart > prevRangeStart ? lStart : prevRangeStart;
                const overlapEnd = lEnd < prevRangeEnd ? lEnd : prevRangeEnd;
                if (overlapEnd >= overlapStart) {
                    const oStart = new Date(overlapStart.getFullYear(), overlapStart.getMonth(), overlapStart.getDate());
                    const oEnd = new Date(overlapEnd.getFullYear(), overlapEnd.getMonth(), overlapEnd.getDate());
                    prevApprovedDays += Math.round(Math.abs(oEnd - oStart) / (1000 * 60 * 60 * 24)) + 1;
                }
            });
            carriedForward = Math.max(0, baseLimit - prevApprovedDays);
        } else {
            // Previous year
            const prevYear = targetYear - 1;
            const prevRangeStart = new Date(prevYear, 0, 1);
            const prevRangeEnd = new Date(prevYear, 11, 31, 23, 59, 59);

            const prevYearLeaves = await Leave.find({
                employeeId: staff._id,
                leaveType: { $regex: flexibleRegex },
                status: { $regex: /^approved$/i },
                $or: [
                    { startDate: { $gte: prevRangeStart, $lte: prevRangeEnd } },
                    { endDate: { $gte: prevRangeStart, $lte: prevRangeEnd } },
                    { startDate: { $lte: prevRangeStart }, endDate: { $gte: prevRangeEnd } }
                ]
            });

            let prevApprovedDays = 0;
            prevYearLeaves.forEach(l => {
                const lStart = new Date(l.startDate);
                const lEnd = new Date(l.endDate);
                const overlapStart = lStart > prevRangeStart ? lStart : prevRangeStart;
                const overlapEnd = lEnd < prevRangeEnd ? lEnd : prevRangeEnd;
                if (overlapEnd >= overlapStart) {
                    const oStart = new Date(overlapStart.getFullYear(), overlapStart.getMonth(), overlapStart.getDate());
                    const oEnd = new Date(overlapEnd.getFullYear(), overlapEnd.getMonth(), overlapEnd.getDate());
                    prevApprovedDays += Math.round(Math.abs(oEnd - oStart) / (1000 * 60 * 60 * 24)) + 1;
                }
            });
            carriedForward = Math.max(0, baseLimit - prevApprovedDays);
        }
    }

    const totalAvailable = baseLimit + carriedForward;
    // Balance check should consider BOTH approved and pending to prevent over-drafting
    const balance = Math.max(0, totalAvailable - (used + pending));

    return {
        baseLimit,
        carriedForward,
        totalAvailable,
        used, // ONLY approved (this is what "Taken" usually shows)
        pending, // separately returned
        balance,
        isMonthly: isCasual,
        carryForwardEnabled: carryForward
    };
};

module.exports = {
    markAttendanceForApprovedLeave,
    calculateAvailableLeaves,
    revertAttendanceForDeletedLeave
};
