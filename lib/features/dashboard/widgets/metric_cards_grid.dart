import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mayor_apps/core/api/api_constants.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import 'available_jobs_modal.dart';
import 'citizen_reports_modal.dart';
import 'citizen_report_filter_modal.dart';
import 'projects_audit_modal.dart';
import 'project_filter_modal.dart';
import 'residents_directory_modal.dart';
import 'resident_filter_modal.dart';

class MetricCardsGrid extends ConsumerWidget {
  final MetricCounts counts;

  const MetricCardsGrid({super.key, required this.counts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to real-time resident count & animation pulse trigger
    final liveResidentCount = ref.watch(realtimeResidentCountProvider) ?? counts.residents;
    final pulseTrigger = ref.watch(residentPulseTriggerProvider);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      childAspectRatio: 1.55,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Real-Time Total Residents Card -> Opens Residents Directory Modal
        _buildCompactCard(
          context,
          title: "TOTAL RESIDENTS",
          valueWidget: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              liveResidentCount.toString(),
              key: ValueKey<int>(liveResidentCount),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.getTextPrimary(context),
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
          subtitle: "Approved Profiles",
          indicatorColor: AppColors.accentBlue,
          isLivePulse: pulseTrigger > 0,
          onTap: () {
            final now = DateTime.now();
            ResidentsDirectoryModal.show(
              context,
              initialFilter: ResidentFilterCriteria(
                startDate: now.subtract(const Duration(days: 365)),
                endDate: now,
                gender: 'ALL',
                civilStatus: 'ALL',
                sector: 'ALL',
                activePreset: 'ALL',
              ),
              selectedBarangay: "ALL",
            );
          },
        ),

        // 2. Available Jobs Card -> Opens Available Jobs Modal
        _buildCompactCard(
          context,
          title: "AVAILABLE JOBS",
          valueWidget: Text(
            counts.jobs.toString(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.getTextPrimary(context),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          subtitle: "Active Opportunities",
          indicatorColor: AppColors.accentGreen,
          onTap: () {
            AvailableJobsModal.show(context);
          },
        ),

        // 3. Incident Reports Card -> Opens Citizen Reports Modal
        _buildCompactCard(
          context,
          title: "INCIDENT REPORTS",
          valueWidget: Text(
            counts.reports.toString(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.getTextPrimary(context),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          subtitle: "Pending Review",
          indicatorColor: AppColors.primary,
          onTap: () {
            CitizenReportsModal.show(
              context,
              initialFilter: const CitizenReportFilterCriteria(),
              selectedBarangay: "ALL",
            );
          },
        ),

        // 4. LGU Projects Card -> Opens Projects Audit Modal
        _buildCompactCard(
          context,
          title: "LGU PROJECTS",
          valueWidget: Text(
            counts.projects.toString(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.getTextPrimary(context),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          subtitle: "In Progress",
          indicatorColor: AppColors.accentPurple,
          onTap: () {
            ProjectsAuditModal.show(
              context,
              initialFilter: const ProjectFilterCriteria(),
              selectedBarangay: "ALL",
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactCard(
    BuildContext context, {
    required String title,
    required Widget valueWidget,
    required String subtitle,
    required Color indicatorColor,
    required VoidCallback onTap,
    bool isLivePulse = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLivePulse ? AppColors.accentGreen : AppColors.getBorder(context),
          width: isLivePulse ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isLivePulse ? 8 : 6,
                      height: isLivePulse ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLivePulse ? AppColors.accentGreen : indicatorColor,
                        boxShadow: isLivePulse
                            ? [
                                BoxShadow(
                                  color: AppColors.accentGreen.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isLivePulse ? AppColors.accentGreen : AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLivePulse)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          "LIVE",
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentGreen,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    Icon(
                      LucideIcons.arrowUpRight,
                      size: 13,
                      color: isLivePulse ? AppColors.accentGreen : AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                    ),
                  ],
                ),
                valueWidget,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextSecondary(context).withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "TAP TO VIEW",
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: indicatorColor.withValues(alpha: 0.85),
                      ),
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
