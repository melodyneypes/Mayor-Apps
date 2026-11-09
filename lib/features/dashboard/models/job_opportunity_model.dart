class JobOpportunityModel {
  final String id;
  final String title;
  final String officeName;
  final String officeCode;
  final String employmentType; // PERMANENT, CONTRACTUAL, CASUAL, JOB_ORDER
  final String salaryGrade; // e.g. "SG 12 (₱31,000 / mo)"
  final int vacancies;
  final String location;
  final String deadline;
  final String postingDate;
  final String status; // ACTIVE, URGENT, CLOSING_SOON
  final String education;
  final String experience;
  final String training;
  final String eligibility;
  final String description;
  final List<String> duties;

  const JobOpportunityModel({
    required this.id,
    required this.title,
    required this.officeName,
    required this.officeCode,
    required this.employmentType,
    required this.salaryGrade,
    required this.vacancies,
    required this.location,
    required this.deadline,
    required this.postingDate,
    this.status = 'ACTIVE',
    required this.education,
    required this.experience,
    required this.training,
    required this.eligibility,
    required this.description,
    this.duties = const [],
  });

  factory JobOpportunityModel.fromJson(Map<String, dynamic> json) {
    return JobOpportunityModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Municipal Staff Position',
      officeName: json['officeName']?.toString() ?? 'LGU Mapandan',
      officeCode: json['officeCode']?.toString() ?? 'LGU',
      employmentType: json['employmentType']?.toString() ?? 'PERMANENT',
      salaryGrade: json['salaryGrade']?.toString() ?? 'Competitive SG',
      vacancies: (json['vacancies'] as num?)?.toInt() ?? 1,
      location: json['location']?.toString() ?? 'Municipal Town Hall, Poblacion, Mapandan',
      deadline: json['deadline']?.toString() ?? 'Open until filled',
      postingDate: json['postingDate']?.toString() ?? 'Nov 2026',
      status: json['status']?.toString() ?? 'ACTIVE',
      education: json['education']?.toString() ?? "Bachelor's degree relevant to the job",
      experience: json['experience']?.toString() ?? '1 year of relevant experience',
      training: json['training']?.toString() ?? '4 hours of relevant training',
      eligibility: json['eligibility']?.toString() ?? 'Career Service (Professional) / Second Level Eligibility',
      description: json['description']?.toString() ?? 'Key municipal government service position supporting local administration.',
      duties: (json['duties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  // Pre-configured official Mapandan LGU Career Opportunities matching the 3 Active Count
  static List<JobOpportunityModel> get defaultOpportunities => const [
    JobOpportunityModel(
      id: 'JOB-2026-001',
      title: 'Administrative Aide IV (Bookkeeper / Records)',
      officeName: 'Office of the Municipal Mayor',
      officeCode: 'MAYOR',
      employmentType: 'PERMANENT',
      salaryGrade: 'Salary Grade 4 (₱16,800 / mo)',
      vacancies: 1,
      location: '2nd Floor, Municipal Town Hall, Poblacion',
      deadline: 'Nov 28, 2026',
      postingDate: 'Nov 01, 2026',
      status: 'ACTIVE',
      education: 'Completion of two-year studies in college or High School Graduate with relevant vocational course',
      experience: '1 year of relevant clerical or bookkeeping experience',
      training: '4 hours of relevant training in government records management',
      eligibility: 'Career Service (Sub-Professional) / First Level Eligibility',
      description: 'Responsible for maintaining executive correspondence, official dispatch records, and administrative assistance in the Office of the Municipal Mayor.',
      duties: [
        'Organize and index executive municipal resolutions, directives, and correspondence.',
        'Process incoming citizen petitions and endorsement transmittals.',
        'Prepare monthly operational compliance logs for executive review.',
      ],
    ),
    JobOpportunityModel(
      id: 'JOB-2026-002',
      title: 'Municipal Civil Engineer II (Infrastructure)',
      officeName: 'Municipal Engineering Office',
      officeCode: 'ENG',
      employmentType: 'PERMANENT',
      salaryGrade: 'Salary Grade 16 (₱41,500 / mo)',
      vacancies: 1,
      location: 'Engineering Building, Poblacion, Mapandan',
      deadline: 'Nov 20, 2026',
      postingDate: 'Oct 25, 2026',
      status: 'URGENT',
      education: "Bachelor's degree in Civil Engineering",
      experience: '1 year of relevant experience in municipal infrastructure & public works inspection',
      training: '4 hours of relevant training in structural inspection / DPWH standards',
      eligibility: 'RA 1080 (Licensed Civil Engineer)',
      description: 'Supervises on-site project implementations, municipal road concreting, drainage improvements, and building permit structural audits.',
      duties: [
        'Inspect ongoing municipal infrastructure projects and monitor contractor milestones.',
        'Evaluate building permit applications for structural and architectural compliance.',
        'Draft engineering estimates and program of works for LGU capital projects.',
      ],
    ),
    JobOpportunityModel(
      id: 'JOB-2026-003',
      title: 'Emergency Medical Technician / Rescue Responder',
      officeName: 'Municipal Disaster Risk Reduction & Management Office',
      officeCode: 'MDRRMO',
      employmentType: 'CONTRACTUAL',
      salaryGrade: 'Salary Grade 8 (₱21,200 / mo)',
      vacancies: 1,
      location: 'MDRRMO Emergency Operations Center, Mapandan',
      deadline: 'Dec 05, 2026',
      postingDate: 'Nov 03, 2026',
      status: 'ACTIVE',
      education: 'Completion of 2 years in College or Allied Health diploma (Nursing / EMT)',
      experience: '1 year of emergency response, pre-hospital care, or ambulance dispatch',
      training: 'EMT-B (Emergency Medical Technician - Basic) or BLS/ACLS Certified',
      eligibility: 'CSC Sub-Professional / EMT Certification / DOH Accredited',
      description: 'Provides rapid emergency pre-hospital care, medical evacuation, and 24/7 disaster response operations throughout the municipality.',
      duties: [
        'Deliver immediate medical first response during vehicular accidents and trauma cases.',
        'Operate municipal rescue equipment and emergency medical transport vehicles.',
        'Maintain daily disaster operational logs and emergency equipment readiness.',
      ],
    ),
  ];
}

