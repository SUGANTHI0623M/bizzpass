const Leave = require('../models/Leave');
const Staff = require('../models/Staff');
const LeaveTemplate = require('../models/LeaveTemplate');
const mongoose = require('mongoose');
const { markAttendanceForApprovedLeave, calculateAvailableLeaves } = require('../utils/leaveAttendanceHelper');

// Helper for date calculation
const calculateDays = (start, end) => {
    const startDate = new Date(start);
    const endDate = new Date(end);
    const diffTime = Math.abs(endDate - startDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return diffDays;
};

const getLeaves = async (req, res) => {
    try {
        const currentStaff = req.staff; // From middleware

        const { status, leaveType, page = 1, limit = 10, search, startDate, endDate } = req.query;
        const query = {};

        // Scope to current employee
        if (currentStaff) {
            query.employeeId = currentStaff._id;
        } else {
            return res.json({
                success: true,
                data: { leaves: [], pagination: { total: 0, page, limit, pages: 0 } }
            });
        }

        if (status && status !== 'all' && status !== 'All Status') query.status = status;
        if (leaveType && leaveType !== 'all') query.leaveType = leaveType;

        if (search) {
            query.$or = [
                { leaveType: { $regex: search, $options: 'i' } },
                { reason: { $regex: search, $options: 'i' } }
            ];
        }

        if (startDate || endDate) {
            // Robust UTC parsing: ignore local time shifts
            const parseDate = (d, isEnd) => {
                const date = new Date(d);
                const utc = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
                if (isEnd) utc.setUTCHours(23, 59, 59, 999);
                else utc.setUTCHours(0, 0, 0, 0);
                return utc;
            };

            const rangeStart = startDate ? parseDate(startDate, false) : new Date(0);
            const rangeEnd = endDate ? parseDate(endDate, true) : new Date(8640000000000000);

            // Simple, robust overlap query
            query.startDate = { $lte: rangeEnd };
            query.endDate = { $gte: rangeStart };
        }

        const skip = (Number(page) - 1) * Number(limit);

        const leaves = await Leave.find(query)
            .populate('approvedBy', 'name email')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(Number(limit));

        const total = await Leave.countDocuments(query);

        res.json({
            success: true,
            data: {
                leaves,
                pagination: {
                    page: Number(page),
                    limit: Number(limit),
                    total,
                    pages: Math.ceil(total / Number(limit))
                }
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: { message: error.message } });
    }
};

const getLeaveTypes = async (req, res) => {
    try {
        const staffId = req.staff._id;
        const { month, year, startDate, endDate } = req.query;
        
        let rangeStart, rangeEnd;

        // Robust parsing: ignore local time shifts for boundaries
        const parseBoundaryDate = (d, isEnd) => {
            const date = new Date(d);
            if (isEnd) return new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999));
            return new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0));
        };

        if (startDate && endDate) {
            rangeStart = parseBoundaryDate(startDate, false);
            rangeEnd = parseBoundaryDate(endDate, true);
        } else {
            const now = new Date();
            const targetMonth = month ? parseInt(month) - 1 : now.getMonth();
            const targetYear = year ? parseInt(year) : now.getFullYear();
            rangeStart = new Date(Date.UTC(targetYear, targetMonth, 1, 0, 0, 0, 0));
            rangeEnd = new Date(Date.UTC(targetYear, targetMonth + 1, 0, 23, 59, 59, 999));
        }

        // 1. Fetch Approved leaves that overlap with the requested range
        const approvedLeaves = await Leave.find({
            employeeId: staffId,
            status: { $regex: /^approved$/i },
            startDate: { $lte: rangeEnd },
            endDate: { $gte: rangeStart }
        });

        // 2. Identify and group all leave types
        const staff = await Staff.findById(staffId).populate('leaveTemplateId');
        const typeGroups = new Map();
        
        // Robust normalization helper:
        // - trim extra spaces
        // - lowercase
        // - remove "leave" suffix (optional)
        // - remove all internal whitespace for strict matching
        const normalize = (str) => (str || '').toLowerCase().trim().replace(/\s*leave\s*$/i, '').replace(/\s+/g, '');

        // Define default cards to show in UI
        const defaultTypes = ['Casual Leave', 'Sick Leave', 'Half Day', 'Earned Leave', 'Unpaid Leave'];
        
        // Add template types if they exist
        if (staff?.leaveTemplateId?.leaveTypes) {
            staff.leaveTemplateId.leaveTypes.forEach(t => {
                if (t.type && !defaultTypes.some(dt => normalize(dt) === normalize(t.type))) {
                    defaultTypes.push(t.type);
                }
            });
        }

        // Initialize groups with original names
        defaultTypes.forEach(t => {
            const norm = normalize(t);
            if (!typeGroups.has(norm)) {
                typeGroups.set(norm, { originalName: t, takenCount: 0 });
            }
        });

        // 3. Process leaves and count days accurately within range
        approvedLeaves.forEach(l => {
            const norm = normalize(l.leaveType);
            if (!typeGroups.has(norm)) {
                typeGroups.set(norm, { originalName: l.leaveType, takenCount: 0 });
            }

            const group = typeGroups.get(norm);
            const lStart = new Date(l.startDate);
            const lEnd = new Date(l.endDate);

            // Use local components to be timezone-independent during the loop
            const current = new Date(Date.UTC(lStart.getFullYear(), lStart.getMonth(), lStart.getDate()));
            const end = new Date(Date.UTC(lEnd.getFullYear(), lEnd.getMonth(), lEnd.getDate()));

            while (current <= end) {
                // If this day of the leave falls within our filter range, count it
                if (current >= rangeStart && current <= rangeEnd) {
                    const typeNorm = normalize(l.leaveType);
                    // Special handling for Half Day type or leaves marked as 0.5 days
                    if (typeNorm === 'halfday' || l.days === 0.5) {
                        group.takenCount += 0.5;
                    } else {
                        group.takenCount += 1;
                    }
                }
                current.setUTCDate(current.getUTCDate() + 1);
            }
        });

        // Convert Map to response format
        const leaveSummary = Array.from(typeGroups.values()).map(g => ({
            type: g.originalName,
            takenCount: g.takenCount
        }));

        res.json({
            success: true,
            data: leaveSummary,
            range: { start: rangeStart, end: rangeEnd }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: { message: error.message } });
    }
};

const createLeave = async (req, res) => {
    try {
        const { startDate, endDate, leaveType, reason, session } = req.body;
        const currentStaffId = req.staff._id;

        const staff = await Staff.findById(currentStaffId).populate('leaveTemplateId');

        if (!staff) {
            return res.status(400).json({ success: false, error: { message: 'Staff profile not found' } });
        }

        // Calculate days - 0.5 for Half Day, otherwise standard calculation
        const days = leaveType === 'Half Day' ? 0.5 : calculateDays(startDate, endDate);

        // Validation for Half Day
        if (leaveType === 'Half Day') {
            if (!session || !['Session 1', 'Session 2'].includes(session)) {
                return res.status(400).json({ success: false, error: { message: 'Session (Session 1 or Session 2) is mandatory for Half Day leave' } });
            }
            // Ensure start and end date are the same for Half Day
            const startStr = new Date(startDate).toDateString();
            const endStr = new Date(endDate).toDateString();
            if (startStr !== endStr) {
                return res.status(400).json({ success: false, error: { message: 'Half Day leave can only be applied for a single date' } });
            }
        }

        let limit = null;
        let leaveConfig = null;

        // Validate leave type against template if staff has a template assigned
        if (staff.leaveTemplateId) {
            const template = staff.leaveTemplateId;
            let leaveTypeFound = false;

            // 1. Check leaveTypes array (primary check)
            if (template.leaveTypes && Array.isArray(template.leaveTypes) && template.leaveTypes.length > 0) {
                leaveConfig = template.leaveTypes.find(t => t.type && t.type.toLowerCase() === leaveType.toLowerCase());
                if (leaveConfig) {
                    limit = leaveConfig.limit || leaveConfig.days;
                    leaveTypeFound = true;
                }
            }

            // 2. Check limits object (fallback)
            if (!leaveTypeFound && template.limits && typeof template.limits === 'object') {
                const limitValue = template.limits[leaveType] || template.limits[leaveType.toLowerCase()];
                if (limitValue !== undefined && limitValue !== null) {
                    limit = limitValue;
                    leaveConfig = { type: leaveType, days: limitValue };
                    leaveTypeFound = true;
                }
            }

            // 3. Check individual fields (e.g., casualLimit) (fallback)
            if (!leaveTypeFound) {
                const fieldName = leaveType.toLowerCase() + 'Limit';
                const fieldValue = template[fieldName];
                if (fieldValue !== undefined && fieldValue !== null) {
                    limit = fieldValue;
                    leaveConfig = { type: leaveType, days: fieldValue };
                    leaveTypeFound = true;
                }
            }

            // IMPORTANT: If staff has a template with leaveTypes array, validate that the leave type exists
            // Exception: Always allow "Unpaid" leave types even if not in template
            const isAlwaysAllowed = /^\\s*unpaid(\\s+leave)?\\s*$/i.test(leaveType);

            // Only reject if template has leaveTypes array defined (not empty/null) AND leave type is not always allowed
            if (!leaveTypeFound && !isAlwaysAllowed && template.leaveTypes && Array.isArray(template.leaveTypes) && template.leaveTypes.length > 0) {
                const availableTypes = template.leaveTypes
                    .filter(t => t.type)
                    .map(t => t.type);
                
                return res.status(400).json({
                    success: false,
                    error: {
                        message: `${leaveType} leave is not available in your leave template. Please contact HR to update your leave template.`,
                        details: {
                            leaveType: leaveType,
                            availableTypes: availableTypes.length > 0 ? availableTypes : ['No leave types configured']
                        }
                    }
                });
            }

            // If it's an always-allowed type (Paid/Unpaid), set limit to null (unrestricted)
            if (isAlwaysAllowed && !leaveTypeFound) {
                limit = null;
            }
        }

        // If limit is not null, enforce it. If null and no template, allow without restriction
        if (limit !== null) {
            // Use the template type name for checking (handles "Casual Leave" vs "Casual")
            const templateTypeName = leaveConfig && leaveConfig.type ? leaveConfig.type : leaveType;
            
            // Use calculateAvailableLeaves to handle carryForward logic
            const leaveDate = new Date(startDate);
            const leaveInfo = await calculateAvailableLeaves(staff, templateTypeName, leaveDate);

            // Check if leave type exists in template and has a limit
            if (leaveInfo.baseLimit === null) {
                // This shouldn't happen if limit is not null, but handle edge case
                return res.status(400).json({
                    success: false,
                    error: {
                        message: `Leave type ${leaveType} not found in template or has no limit configured.`,
                    }
                });
            }

            // Strict validation: Check if balance is already 0 or would become negative
            // This prevents applying when limit is already fully used
            if (leaveInfo.balance <= 0) {
                const rangeType = leaveInfo.isMonthly ? 'month' : 'year';
                return res.status(400).json({
                    success: false,
                    error: {
                        message: `You have already used all available ${leaveType} leave for this ${rangeType}. Available: ${leaveInfo.totalAvailable} days, Used: ${leaveInfo.used} days.`,
                        details: {
                            baseLimit: leaveInfo.baseLimit,
                            carriedForward: leaveInfo.carriedForward,
                            totalAvailable: leaveInfo.totalAvailable,
                            used: leaveInfo.used,
                            requested: days,
                            balance: leaveInfo.balance,
                            range: rangeType
                        }
                    }
                });
            }

            // Check if requested days exceed available balance
            if (days > leaveInfo.balance) {
                const rangeType = leaveInfo.isMonthly ? 'month' : 'year';
                const message = leaveInfo.carryForwardEnabled
                    ? `Leave request exceeds available balance for ${leaveType}. Available: ${leaveInfo.balance} days, Requested: ${days} days. Max ${leaveInfo.totalAvailable} days per ${rangeType} (${leaveInfo.baseLimit} base + ${leaveInfo.carriedForward} carried forward).`
                    : `Leave request exceeds available balance for ${leaveType}. Available: ${leaveInfo.balance} days, Requested: ${days} days. Max ${leaveInfo.baseLimit} days allowed per ${rangeType}.`;

                return res.status(400).json({
                    success: false,
                    error: {
                        message: message,
                        details: {
                            baseLimit: leaveInfo.baseLimit,
                            carriedForward: leaveInfo.carriedForward,
                            totalAvailable: leaveInfo.totalAvailable,
                            used: leaveInfo.used,
                            requested: days,
                            balance: leaveInfo.balance,
                            range: rangeType
                        }
                    }
                });
            }

            // Final check: Ensure used + requested doesn't exceed total available
            if (leaveInfo.used + days > leaveInfo.totalAvailable) {
                const rangeType = leaveInfo.isMonthly ? 'month' : 'year';
                const message = leaveInfo.carryForwardEnabled
                    ? `Leave limit exceeded for ${leaveType}. Max ${leaveInfo.totalAvailable} days available (${leaveInfo.baseLimit} base + ${leaveInfo.carriedForward} carried forward) per ${rangeType}. Used: ${leaveInfo.used} days, Requested: ${days} days.`
                    : `Leave limit exceeded for ${leaveType}. Max ${leaveInfo.baseLimit} days allowed per ${rangeType}. Used: ${leaveInfo.used} days, Requested: ${days} days.`;

                return res.status(400).json({
                    success: false,
                    error: {
                        message: message,
                        details: {
                            baseLimit: leaveInfo.baseLimit,
                            carriedForward: leaveInfo.carriedForward,
                            totalAvailable: leaveInfo.totalAvailable,
                            used: leaveInfo.used,
                            requested: days,
                            balance: leaveInfo.balance,
                            range: rangeType
                        }
                    }
                });
            }
        }

        const leave = await Leave.create({
            employeeId: staff._id,
            businessId: staff.businessId,
            leaveType,
            startDate,
            endDate,
            days,
            reason,
            session: leaveType === 'Half Day' ? session : null
        });

        res.status(201).json({
            success: true,
            data: { leave }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: { message: error.message } });
    }
};


// @desc    Approve or Reject Leave
// @route   PATCH /api/requests/leave/:id/approve or /api/requests/leave/:id/reject
// @access  Private (Admin/HR)
const updateLeaveStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, rejectionReason } = req.body;
        const approverId = req.staff?._id || req.user?._id;

        if (!['Approved', 'Rejected'].includes(status)) {
            return res.status(400).json({
                success: false,
                error: { message: 'Invalid status. Must be "Approved" or "Rejected"' }
            });
        }

        const leave = await Leave.findById(id);
        if (!leave) {
            return res.status(404).json({
                success: false,
                error: { message: 'Leave not found' }
            });
        }

        // If approving, check limits one last time
        if (status === 'Approved') {
            const staff = await Staff.findById(leave.employeeId).populate('leaveTemplateId');
            if (staff && staff.leaveTemplateId) {
                const leaveInfo = await calculateAvailableLeaves(staff, leave.leaveType, leave.startDate);
                
                // When approving, we check if the ALREADY APPLIED leave (which is in Pending)
                // would still be within limits. calculateAvailableLeaves includes Pending leaves.
                // If used > totalAvailable, it means some leaves were approved in between that 
                // now make this one exceed the limit.
                if (leaveInfo.totalAvailable !== null && leaveInfo.used > leaveInfo.totalAvailable) {
                    return res.status(400).json({
                        success: false,
                        error: { 
                            message: `Cannot approve leave. ${leave.leaveType} limit exceeded for this ${leaveInfo.isMonthly ? 'month' : 'year'}.`,
                            details: leaveInfo
                        }
                    });
                }
            }
        }

        // Update leave status
        leave.status = status;
        leave.approvedBy = approverId;
        leave.approvedAt = new Date();
        if (status === 'Rejected' && rejectionReason) {
            leave.rejectionReason = rejectionReason;
        }

        await leave.save();

        // If approved, mark attendance as "Present" for all dates in the leave period
        if (status === 'Approved') {
            try {
                await markAttendanceForApprovedLeave(leave);
            } catch (error) {
                console.error('[updateLeaveStatus] Error marking attendance:', error);
                // Don't fail the request if attendance marking fails, but log it
            }
        }

        res.json({
            success: true,
            data: { leave }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: { message: error.message } });
    }
};

module.exports = {
    getLeaves,
    getLeaveTypes,
    createLeave,
    updateLeaveStatus
};
