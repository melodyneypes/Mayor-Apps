import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/job_opportunity_model.dart';

class AvailableJobsModal extends StatefulWidget {
  final List<JobOpportunityModel>? jobs;

  const AvailableJobsModal({super.key, this.jobs});

  static Future<void> show(BuildContext context, {List<JobOpportunityModel>? jobs}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvailableJobsModal(jobs: jobs),
    );
  }

  @override
  State<AvailableJobsModal> createState() => _AvailableJobsModalState();
}

class _AvailableJobsModalState extends State<AvailableJobsModal> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  late final List<JobOpportunityModel> _allJobs;

  final List<String> _categories = const [
    'ALL',
    'PERMANENT',
    'CONTRACTUAL',
    'URGENT',
  ];

  @override
  void initState() {
    super.initState();
    _allJobs = widget.jobs ?? JobOpportunityModel.defaultOpportunities;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JobOpportunityModel> get _filteredJobs {
    return _allJobs.where((job) {
      // Category filter
      if (_selectedCategory == 'PERMANENT' && job.employmentType != 'PERMANENT') {
        return false;
      }
      if (_selectedCategory == 'CONTRACTUAL' && job.employmentType != 'CONTRACTUAL') {
        return false;
      }
      if (_selectedCategory == 'URGENT' && job.status != 'URGENT') {
        return false;
      }

      // Search query filter (checks title, officeName, officeCode, eligibility)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = job.title.toLowerCase().contains(q);
        final matchOffice = job.officeName.toLowerCase().contains(q) || job.officeCode.toLowerCase().contains(q);
        final matchEligibility = job.eligibility.toLowerCase().contains(q);
        return matchTitle || matchOffice || matchEligibility;
      }
      return true;
    }).toList();
  }

  void _showJobDetailSheet(JobOpportunityModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JobDetailSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _filteredJobs;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.isDark(context) ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.briefcase, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "AVAILABLE JOBS",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.getTextPrimary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${_allJobs.length} Active",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Official LGU Mapandan Public Employment Opportunities",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.getTextSecondary(context)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search position, department, or eligibility...",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.getTextSecondary(context), size: 18),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 16, color: AppColors.getTextSecondary(context)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat == 'ALL' ? 'All Positions' : cat,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF10B981),
                  backgroundColor: AppColors.getSurface(context),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF10B981) : AppColors.getBorder(context),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Job Opportunities List
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.briefcase, size: 40, color: AppColors.getTextSecondary(context)),
                        const SizedBox(height: 10),
                        Text(
                          "No positions match your search",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Try adjusting your filters or keyword query.",
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final item = jobs[index];
                      return _buildJobCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobOpportunityModel item) {
    final isUrgent = item.status == 'URGENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : AppColors.getBorder(context),
          width: isUrgent ? 1.2 : 1.0,
        ),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobDetailSheet(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        item.employmentType,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceElevated(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      child: Text(
                        item.officeCode,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isUrgent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 11, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              "PRIORITY",
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      "Apply by ${item.deadline}",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Position Title
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 4),

                // Department / Office
                Text(
                  item.officeName,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Footer Info Row (Salary & View Details CTA)
                Row(
                  children: [
                    const Icon(LucideIcons.banknote, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Text(
                      item.salaryGrade,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "VIEW DETAILS",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobDetailSheet extends StatelessWidget {
  final JobOpportunityModel job;

  const _JobDetailSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: ListView(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.isDark(context) ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Text(
                  job.employmentType,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceElevated(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Text(
                  "${job.vacancies} ${job.vacancies == 1 ? 'Opening' : 'Openings'}",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "Deadline: ${job.deadline}",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Full Position Title
          Text(
            job.title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.getTextPrimary(context),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),

          // Office
          Text(
            "${job.officeName} (${job.officeCode})",
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
          ),

          const SizedBox(height: 16),

          // Salary & Compensation Card (Clean without decorative icon)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.15),
                  AppColors.isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFECFDF5),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "COMPENSATION & RATE",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.isDark(context) ? const Color(0xFF34D399) : const Color(0xFF059669),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.salaryGrade,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CSC Qualification Standards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceElevated(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CSC QUALIFICATION STANDARDS",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.getTextSecondary(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                _buildQualificationRow(context, "Education", job.education),
                const SizedBox(height: 10),
                _buildQualificationRow(context, "Experience", job.experience),
                const SizedBox(height: 10),
                _buildQualificationRow(context, "Training", job.training),
                const SizedBox(height: 10),
                _buildQualificationRow(context, "Eligibility", job.eligibility),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Scope & Duties
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceElevated(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DUTIES & RESPONSIBILITIES",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.getTextSecondary(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  job.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                    height: 1.45,
                  ),
                ),
                if (job.duties.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...job.duties.map((duty) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                duty,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.getTextPrimary(context),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationRow(BuildContext context, String label, String value) {
    final isDark = AppColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimary(context),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

