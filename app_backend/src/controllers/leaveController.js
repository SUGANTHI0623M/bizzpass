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
            query.startDate = {};
            if (startDate) query.startDate.$gte = new Date(startDate);
            if (endDate) query.startDate.$lte = new Date(endDate);
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
        const staff = await Staff.findById(staffId).populate('leaveTemplateId');

        const DEFAULT_TYPES = ['Casual', 'Sick', 'Earned', 'Unpaid', 'Paid', 'Maternity', 'Paternity', 'Other'];
        let templateTypes = [];

        if (staff && staff.leaveTemplateId) {
            const template = staff.leaveTemplateId;
            // Support various template structures
            if (template.leaveTypes && Array.isArray(template.leaveTypes)) {
                templateTypes = template.leaveTypes.map(t => ({
                    type: t.type,
                    limit: t.limit || t.days
                }));
            } else if (template.limits) {
                templateTypes = Object.keys(template.limits).map(k => ({
                    type: k,
                    limit: template.limits[k]
                }));
            }
        }

        // If staff has a template with leaveTypes, return template types + always include Paid and Unpaid
        // This ensures the app shows the exact template type names (e.g., "Casual Leave", "Sick Leave")
        // and always includes Paid/Unpaid options
        if (templateTypes.length > 0) {
            const now = new Date();
            const availableTypes = await Promise.all(templateTypes.map(async (templateType) => {
                const typeName = templateType.type;
                const limit = templateType.limit;

                if (limit === null || limit === undefined) {
                    // No restriction for this type
                    return {
                        type: typeName,
                        limit: null,
                        used: 0,
                        balance: 999, // Practically unlimited
                        isUnrestricted: true
                    };
                }

                // Use calculateAvailableLeaves to handle carryForward logic
                const leaveInfo = await calculateAvailableLeaves(staff, typeName, now);

                return {
                    type: typeName,
                    limit: leaveInfo.baseLimit,
                    carriedForward: leaveInfo.carriedForward,
                    totalAvailable: leaveInfo.totalAvailable,
                    used: leaveInfo.used,
                    balance: leaveInfo.balance,
                    isMonthly: leaveInfo.isMonthly,
                    carryForwardEnabled: leaveInfo.carryForwardEnabled,
                    isUnrestricted: false
                };
            }));

            // Always add Paid and Unpaid leave types (unrestricted)
            // Check if they're not already in template types
            const templateTypeNames = templateTypes.map(t => t.type.toLowerCase());
            if (!templateTypeNames.includes('paid')) {
                availableTypes.push({
                    type: 'Paid',
                    limit: null,
                    used: 0,
                    balance: 999,
                    isUnrestricted: true
                });
            }
            if (!templateTypeNames.includes('unpaid')) {
                availableTypes.push({
                    type: 'Unpaid',
                    limit: null,
                    used: 0,
                    balance: 999,
                    isUnrestricted: true
                });
            }

            return res.json({
                success: true,
                data: availableTypes
            });
        }

        // Fallback: If no template, return DEFAULT_TYPES with no restrictions
        const now = new Date();
        const availableTypes = await Promise.all(DEFAULT_TYPES.map(async (typeName) => {
            return {
                type: typeName,
                limit: null,
                used: 0,
                balance: 999, // Practically unlimited
                isUnrestricted: true
            };
        }));

        res.json({
            success: true,
            data: availableTypes
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: { message: error.message } });
    }
};

const createLeave = async (req, res) => {
    try {
        const { startDate, endDate, leaveType, reason } = req.body;
        const currentStaffId = req.staff._id;

        const staff = await Staff.findById(currentStaffId).populate('leaveTemplateId');

        if (!staff) {
            return res.status(400).json({ success: false, error: { message: 'Staff profile not found' } });
        }

        const days = calculateDays(startDate, endDate);

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
            // Exception: Always allow "Paid" and "Unpaid" leave types even if not in template
            const alwaysAllowedTypes = ['Paid', 'Unpaid'];
            const isAlwaysAllowed = alwaysAllowedTypes.some(allowedType => 
                leaveType.toLowerCase() === allowedType.toLowerCase()
            );

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
            reason
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
