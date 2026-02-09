// ─── Data Models ─────────────────────────────────────────────────────────────

class Company {
  final int id;
  final String name,
      email,
      phone,
      city,
      state,
      subscriptionPlan,
      subscriptionStatus,
      subscriptionEndDate,
      licenseKey;
  final bool isActive;
  final int staffCount, branches;

  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.isActive,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.subscriptionEndDate,
    required this.staffCount,
    required this.branches,
    required this.licenseKey,
  });

  factory Company.fromJson(Map<String, dynamic> j) {
    return Company(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      city: (j['city'] as String?) ?? '',
      state: (j['state'] as String?) ?? '',
      subscriptionPlan: (j['subscriptionPlan'] as String?) ?? 'Starter',
      subscriptionStatus: (j['subscriptionStatus'] as String?) ?? 'active',
      subscriptionEndDate: (j['subscriptionEndDate'] as String?) ?? '',
      licenseKey: (j['licenseKey'] as String?) ?? '',
      isActive: (j['isActive'] as bool?) ?? true,
      staffCount: (j['staffCount'] as num?)?.toInt() ?? 0,
      branches: (j['branches'] as num?)?.toInt() ?? 0,
    );
  }
}

class Plan {
  final int id;
  final String planCode, planName, description, currency, maxBranches;
  final int price, durationMonths, maxUsers, trialDays;
  final List<String> features;
  final bool isActive;

  const Plan({
    required this.id,
    required this.planCode,
    required this.planName,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationMonths,
    required this.maxUsers,
    required this.maxBranches,
    required this.features,
    required this.trialDays,
    required this.isActive,
  });

  factory Plan.fromJson(Map<String, dynamic> j) {
    final f = j['features'];
    final list = f is List ? f.map((e) => e.toString()).toList() : <String>[];
    return Plan(
      id: (j['id'] as num?)?.toInt() ?? 0,
      planCode: (j['planCode'] as String?) ?? '',
      planName: (j['planName'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      price: (j['price'] as num?)?.toInt() ?? 0,
      currency: (j['currency'] as String?) ?? 'INR',
      durationMonths: (j['durationMonths'] as num?)?.toInt() ?? 12,
      maxUsers: (j['maxUsers'] as num?)?.toInt() ?? 0,
      maxBranches: (j['maxBranches'] as String?) ?? 'Unlimited',
      features: List<String>.from(list),
      trialDays: (j['trialDays'] as num?)?.toInt() ?? 0,
      isActive: (j['isActive'] as bool?) ?? true,
    );
  }
}

class License {
  final int id;
  final String licenseKey, plan, status;
  final String? company, validFrom, validUntil;
  final int maxUsers;
  final bool isTrial;

  const License({
    required this.id,
    required this.licenseKey,
    this.company,
    required this.plan,
    required this.maxUsers,
    required this.status,
    this.validFrom,
    this.validUntil,
    required this.isTrial,
  });

  factory License.fromJson(Map<String, dynamic> j) {
    return License(
      id: (j['id'] as num?)?.toInt() ?? 0,
      licenseKey: (j['licenseKey'] as String?) ?? '',
      company: j['company'] as String?,
      plan: (j['plan'] as String?) ?? '',
      maxUsers: (j['maxUsers'] as num?)?.toInt() ?? 0,
      status: (j['status'] as String?) ?? 'unassigned',
      validFrom: j['validFrom'] as String?,
      validUntil: j['validUntil'] as String?,
      isTrial: (j['isTrial'] as bool?) ?? false,
    );
  }
}

class Payment {
  final int id;
  final String company,
      status,
      gateway,
      method,
      razorpayId,
      paidAt,
      plan,
      currency;
  final int amount;

  const Payment({
    required this.id,
    required this.company,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gateway,
    required this.method,
    required this.razorpayId,
    required this.paidAt,
    required this.plan,
  });

  factory Payment.fromJson(Map<String, dynamic> j) {
    return Payment(
      id: (j['id'] as num?)?.toInt() ?? 0,
      company: (j['company'] as String?) ?? '',
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      currency: (j['currency'] as String?) ?? 'INR',
      status: ((j['status'] as String?) ?? 'captured').toLowerCase(),
      gateway: ((j['gateway'] as String?) ?? 'razorpay').toLowerCase(),
      method: ((j['method'] as String?) ?? 'upi').toUpperCase(),
      razorpayId: (j['razorpayId'] as String?) ?? '',
      paidAt: (j['paidAt'] as String?) ?? '',
      plan: (j['plan'] as String?) ?? '',
    );
  }
}

class Staff {
  final int id;
  final String employeeId,
      name,
      email,
      phone,
      company,
      designation,
      department,
      status,
      joiningDate;
  final int? roleId;
  final String? roleName;
  final int? branchId;
  final String? branchName;

  const Staff({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.designation,
    required this.department,
    required this.status,
    required this.joiningDate,
    this.roleId,
    this.roleName,
    this.branchId,
    this.branchName,
  });

  factory Staff.fromJson(Map<String, dynamic> j) {
    return Staff(
      id: (j['id'] as num?)?.toInt() ?? 0,
      employeeId: (j['employeeId'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      company: (j['company'] as String?) ?? '',
      designation: (j['designation'] as String?) ?? '',
      department: (j['department'] as String?) ?? '',
      status: ((j['status'] as String?) ?? 'active').toLowerCase(),
      joiningDate: (j['joiningDate'] as String?) ?? '',
      roleId: (j['roleId'] as num?)?.toInt(),
      roleName: j['roleName'] as String?,
      branchId: (j['branchId'] as num?)?.toInt(),
      branchName: j['branchName'] as String?,
    );
  }
}

class Visitor {
  final int id;
  final String name,
      companyVisiting,
      visitorCompany,
      purpose,
      host,
      status,
      badge;
  final String? checkIn;

  const Visitor({
    required this.id,
    required this.name,
    required this.companyVisiting,
    required this.visitorCompany,
    required this.purpose,
    required this.host,
    required this.status,
    required this.badge,
    this.checkIn,
  });

  factory Visitor.fromJson(Map<String, dynamic> j) {
    return Visitor(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      companyVisiting: (j['companyVisiting'] as String?) ?? '',
      visitorCompany: (j['visitorCompany'] as String?) ?? '',
      purpose: (j['purpose'] as String?) ?? '',
      host: (j['host'] as String?) ?? '',
      status: (j['status'] as String?) ?? 'expected',
      badge: (j['badge'] as String?) ?? '',
      checkIn: j['checkIn'] as String?,
    );
  }
}

class AttendanceRecord {
  final int id;
  final String employee, company, status;
  final String? punchIn, punchOut;
  final double workHours;
  final int lateMinutes;

  const AttendanceRecord({
    required this.id,
    required this.employee,
    required this.company,
    this.punchIn,
    this.punchOut,
    required this.status,
    required this.workHours,
    required this.lateMinutes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    return AttendanceRecord(
      id: (j['id'] as num?)?.toInt() ?? 0,
      employee: (j['employee'] as String?) ?? '',
      company: (j['company'] as String?) ?? '',
      punchIn: j['punchIn'] as String?,
      punchOut: j['punchOut'] as String?,
      status: ((j['status'] as String?) ?? 'absent').toLowerCase(),
      workHours: (j['workHours'] as num?)?.toDouble() ?? 0,
      lateMinutes: (j['lateMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppNotification {
  final int id;
  final String type, title, company, channel, status, priority, createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.company,
    required this.channel,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: (j['type'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      company: (j['company'] as String?) ?? '',
      channel: ((j['channel'] as String?) ?? 'email').toLowerCase(),
      status: ((j['status'] as String?) ?? 'pending').toLowerCase(),
      priority: ((j['priority'] as String?) ?? 'normal').toLowerCase(),
      createdAt: (j['createdAt'] as String?) ?? '',
    );
  }
}

// ─── Mock Data ───────────────────────────────────────────────────────────────

const List<Company> companies = [
  Company(
      id: 1,
      name: "TechNova Solutions",
      email: "admin@technova.in",
      phone: "+91 98765 43210",
      city: "Mumbai",
      state: "Maharashtra",
      isActive: true,
      subscriptionPlan: "Enterprise",
      subscriptionStatus: "active",
      subscriptionEndDate: "2026-06-15",
      staffCount: 142,
      branches: 4,
      licenseKey: "BP-ENT-2025-0A1B"),
  Company(
      id: 2,
      name: "GreenLeaf Agritech",
      email: "ops@greenleaf.co",
      phone: "+91 87654 32109",
      city: "Pune",
      state: "Maharashtra",
      isActive: true,
      subscriptionPlan: "Professional",
      subscriptionStatus: "active",
      subscriptionEndDate: "2025-09-30",
      staffCount: 58,
      branches: 2,
      licenseKey: "BP-PRO-2025-1C2D"),
  Company(
      id: 3,
      name: "Meridian Logistics",
      email: "hr@meridian.in",
      phone: "+91 76543 21098",
      city: "Chennai",
      state: "Tamil Nadu",
      isActive: true,
      subscriptionPlan: "Starter",
      subscriptionStatus: "expiring_soon",
      subscriptionEndDate: "2025-03-15",
      staffCount: 23,
      branches: 1,
      licenseKey: "BP-STR-2025-3E4F"),
  Company(
      id: 4,
      name: "Pinnacle Edutech",
      email: "info@pinnacle.edu",
      phone: "+91 65432 10987",
      city: "Bangalore",
      state: "Karnataka",
      isActive: false,
      subscriptionPlan: "Professional",
      subscriptionStatus: "expired",
      subscriptionEndDate: "2025-01-20",
      staffCount: 76,
      branches: 3,
      licenseKey: "BP-PRO-2024-5G6H"),
  Company(
      id: 5,
      name: "Dharma Healthcare",
      email: "admin@dharma.health",
      phone: "+91 54321 09876",
      city: "Hyderabad",
      state: "Telangana",
      isActive: true,
      subscriptionPlan: "Enterprise",
      subscriptionStatus: "active",
      subscriptionEndDate: "2026-12-31",
      staffCount: 210,
      branches: 7,
      licenseKey: "BP-ENT-2025-7I8J"),
  Company(
      id: 6,
      name: "Artisan Foods Pvt Ltd",
      email: "ceo@artisanfoods.in",
      phone: "+91 43210 98765",
      city: "Delhi",
      state: "Delhi",
      isActive: true,
      subscriptionPlan: "Starter",
      subscriptionStatus: "active",
      subscriptionEndDate: "2025-08-10",
      staffCount: 15,
      branches: 1,
      licenseKey: "BP-STR-2025-9K0L"),
  Company(
      id: 7,
      name: "Vyom Infrastructure",
      email: "pm@vyom.build",
      phone: "+91 32109 87654",
      city: "Ahmedabad",
      state: "Gujarat",
      isActive: true,
      subscriptionPlan: "Professional",
      subscriptionStatus: "active",
      subscriptionEndDate: "2025-11-22",
      staffCount: 89,
      branches: 3,
      licenseKey: "BP-PRO-2025-1M2N"),
  Company(
      id: 8,
      name: "Nexus Finserv",
      email: "compliance@nex.fin",
      phone: "+91 21098 76543",
      city: "Mumbai",
      state: "Maharashtra",
      isActive: false,
      subscriptionPlan: "Enterprise",
      subscriptionStatus: "suspended",
      subscriptionEndDate: "2025-04-01",
      staffCount: 165,
      branches: 5,
      licenseKey: "BP-ENT-2024-3O4P"),
];

const List<License> licenses = [
  License(
      id: 1,
      licenseKey: "BP-ENT-2025-0A1B",
      company: "TechNova Solutions",
      plan: "Enterprise",
      maxUsers: 200,
      status: "active",
      validFrom: "2025-06-15",
      validUntil: "2026-06-15",
      isTrial: false),
  License(
      id: 2,
      licenseKey: "BP-PRO-2025-1C2D",
      company: "GreenLeaf Agritech",
      plan: "Professional",
      maxUsers: 100,
      status: "active",
      validFrom: "2024-09-30",
      validUntil: "2025-09-30",
      isTrial: false),
  License(
      id: 3,
      licenseKey: "BP-STR-2025-3E4F",
      company: "Meridian Logistics",
      plan: "Starter",
      maxUsers: 30,
      status: "active",
      validFrom: "2024-03-15",
      validUntil: "2025-03-15",
      isTrial: false),
  License(
      id: 4,
      licenseKey: "BP-PRO-2024-5G6H",
      company: "Pinnacle Edutech",
      plan: "Professional",
      maxUsers: 100,
      status: "expired",
      validFrom: "2024-01-20",
      validUntil: "2025-01-20",
      isTrial: false),
  License(
      id: 5,
      licenseKey: "BP-ENT-2025-7I8J",
      company: "Dharma Healthcare",
      plan: "Enterprise",
      maxUsers: 300,
      status: "active",
      validFrom: "2025-01-01",
      validUntil: "2026-12-31",
      isTrial: false),
  License(
      id: 6,
      licenseKey: "BP-TRL-2025-XXYY",
      company: null,
      plan: "Starter",
      maxUsers: 25,
      status: "unassigned",
      validFrom: null,
      validUntil: null,
      isTrial: true),
  License(
      id: 7,
      licenseKey: "BP-ENT-2024-3O4P",
      company: "Nexus Finserv",
      plan: "Enterprise",
      maxUsers: 200,
      status: "suspended",
      validFrom: "2024-04-01",
      validUntil: "2025-04-01",
      isTrial: false),
];

const List<Payment> payments = [
  Payment(
      id: 1,
      company: "TechNova Solutions",
      amount: 149999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "UPI",
      razorpayId: "pay_Nk2x8Qs9TgZ",
      paidAt: "2025-06-14",
      plan: "Enterprise"),
  Payment(
      id: 2,
      company: "GreenLeaf Agritech",
      amount: 59999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "Card",
      razorpayId: "pay_Mj7w5Pr8SfY",
      paidAt: "2024-09-29",
      plan: "Professional"),
  Payment(
      id: 3,
      company: "Dharma Healthcare",
      amount: 249999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "Netbanking",
      razorpayId: "pay_Ol3v4Ks6RhX",
      paidAt: "2025-01-01",
      plan: "Enterprise"),
  Payment(
      id: 4,
      company: "Meridian Logistics",
      amount: 19999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "UPI",
      razorpayId: "pay_Li9u3Jr5QgW",
      paidAt: "2024-03-14",
      plan: "Starter"),
  Payment(
      id: 5,
      company: "Pinnacle Edutech",
      amount: 59999,
      currency: "INR",
      status: "refunded",
      gateway: "razorpay",
      method: "Card",
      razorpayId: "pay_Kh8t2Iq4PfV",
      paidAt: "2024-01-19",
      plan: "Professional"),
  Payment(
      id: 6,
      company: "Vyom Infrastructure",
      amount: 59999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "UPI",
      razorpayId: "pay_Pm4x7Lt9UiB",
      paidAt: "2024-11-21",
      plan: "Professional"),
];

const List<Staff> staffData = [
  Staff(
      id: 1,
      employeeId: "TN-001",
      name: "Arjun Mehta",
      email: "arjun@technova.in",
      phone: "+91 98111 22334",
      company: "TechNova Solutions",
      designation: "Sr. Developer",
      department: "Engineering",
      status: "active",
      joiningDate: "2023-04-10"),
  Staff(
      id: 2,
      employeeId: "TN-002",
      name: "Priya Sharma",
      email: "priya@technova.in",
      phone: "+91 98222 33445",
      company: "TechNova Solutions",
      designation: "Product Manager",
      department: "Product",
      status: "active",
      joiningDate: "2022-08-15"),
  Staff(
      id: 3,
      employeeId: "GL-001",
      name: "Rohit Patel",
      email: "rohit@greenleaf.co",
      phone: "+91 87333 44556",
      company: "GreenLeaf Agritech",
      designation: "Operations Head",
      department: "Operations",
      status: "active",
      joiningDate: "2023-01-05"),
  Staff(
      id: 4,
      employeeId: "DH-001",
      name: "Dr. Kavitha Rao",
      email: "kavitha@dharma.health",
      phone: "+91 76444 55667",
      company: "Dharma Healthcare",
      designation: "Chief Medical Officer",
      department: "Medical",
      status: "active",
      joiningDate: "2021-06-20"),
  Staff(
      id: 5,
      employeeId: "ML-001",
      name: "Suresh Kumar",
      email: "suresh@meridian.in",
      phone: "+91 65555 66778",
      company: "Meridian Logistics",
      designation: "Fleet Manager",
      department: "Logistics",
      status: "active",
      joiningDate: "2024-02-01"),
  Staff(
      id: 6,
      employeeId: "PE-001",
      name: "Ananya Joshi",
      email: "ananya@pinnacle.edu",
      phone: "+91 54666 77889",
      company: "Pinnacle Edutech",
      designation: "Content Director",
      department: "Content",
      status: "inactive",
      joiningDate: "2022-11-10"),
  Staff(
      id: 7,
      employeeId: "NF-001",
      name: "Vikram Singh",
      email: "vikram@nex.fin",
      phone: "+91 43777 88990",
      company: "Nexus Finserv",
      designation: "Compliance Officer",
      department: "Compliance",
      status: "inactive",
      joiningDate: "2023-07-25"),
  Staff(
      id: 8,
      employeeId: "TN-003",
      name: "Deepa Nair",
      email: "deepa@technova.in",
      phone: "+91 98888 99001",
      company: "TechNova Solutions",
      designation: "UX Designer",
      department: "Design",
      status: "active",
      joiningDate: "2024-01-15"),
];

const List<Visitor> visitors = [
  Visitor(
      id: 1,
      name: "Rajesh Khanna",
      companyVisiting: "TechNova Solutions",
      visitorCompany: "Infosys",
      purpose: "Client Meeting",
      host: "Arjun Mehta",
      status: "checked_in",
      checkIn: "2025-02-08 09:30",
      badge: "V-0142"),
  Visitor(
      id: 2,
      name: "Meera Iyer",
      companyVisiting: "Dharma Healthcare",
      visitorCompany: "Apollo Hospitals",
      purpose: "Partnership Discussion",
      host: "Dr. Kavitha Rao",
      status: "expected",
      checkIn: null,
      badge: "V-0143"),
  Visitor(
      id: 3,
      name: "Amit Desai",
      companyVisiting: "GreenLeaf Agritech",
      visitorCompany: "Bayer CropScience",
      purpose: "Product Demo",
      host: "Rohit Patel",
      status: "checked_out",
      checkIn: "2025-02-07 14:00",
      badge: "V-0141"),
  Visitor(
      id: 4,
      name: "Sunita Reddy",
      companyVisiting: "TechNova Solutions",
      visitorCompany: "Self",
      purpose: "Interview",
      host: "Priya Sharma",
      status: "checked_in",
      checkIn: "2025-02-08 10:15",
      badge: "V-0144"),
];

const List<AttendanceRecord> attendanceToday = [
  AttendanceRecord(
      id: 1,
      employee: "Arjun Mehta",
      company: "TechNova Solutions",
      punchIn: "09:02",
      punchOut: null,
      status: "present",
      workHours: 5.2,
      lateMinutes: 2),
  AttendanceRecord(
      id: 2,
      employee: "Priya Sharma",
      company: "TechNova Solutions",
      punchIn: "08:45",
      punchOut: null,
      status: "present",
      workHours: 5.5,
      lateMinutes: 0),
  AttendanceRecord(
      id: 3,
      employee: "Rohit Patel",
      company: "GreenLeaf Agritech",
      punchIn: "09:15",
      punchOut: null,
      status: "late",
      workHours: 5.0,
      lateMinutes: 15),
  AttendanceRecord(
      id: 4,
      employee: "Dr. Kavitha Rao",
      company: "Dharma Healthcare",
      punchIn: "07:30",
      punchOut: null,
      status: "present",
      workHours: 6.8,
      lateMinutes: 0),
  AttendanceRecord(
      id: 5,
      employee: "Suresh Kumar",
      company: "Meridian Logistics",
      punchIn: null,
      punchOut: null,
      status: "absent",
      workHours: 0,
      lateMinutes: 0),
  AttendanceRecord(
      id: 6,
      employee: "Deepa Nair",
      company: "TechNova Solutions",
      punchIn: "09:30",
      punchOut: null,
      status: "late",
      workHours: 4.8,
      lateMinutes: 30),
];

const List<AppNotification> notifications = [
  AppNotification(
      id: 1,
      type: "license_expiry_reminder",
      title: "License expiring in 35 days",
      company: "Meridian Logistics",
      channel: "email",
      status: "sent",
      priority: "high",
      createdAt: "2025-02-08"),
  AppNotification(
      id: 2,
      type: "payment_confirmation",
      title: "Payment received — ₹1,49,999",
      company: "TechNova Solutions",
      channel: "email",
      status: "delivered",
      priority: "normal",
      createdAt: "2025-02-07"),
  AppNotification(
      id: 3,
      type: "license_suspended",
      title: "License suspended — payment overdue",
      company: "Nexus Finserv",
      channel: "email",
      status: "sent",
      priority: "urgent",
      createdAt: "2025-02-06"),
  AppNotification(
      id: 4,
      type: "visitor_arrival",
      title: "Visitor Rajesh Khanna checked in",
      company: "TechNova Solutions",
      channel: "in_app",
      status: "read",
      priority: "low",
      createdAt: "2025-02-08"),
];
