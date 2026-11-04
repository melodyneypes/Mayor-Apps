import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_service_model.dart';

class HotlinesDirectoryModal extends ConsumerStatefulWidget {
  const HotlinesDirectoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HotlinesDirectoryModal(),
    );
  }

  @override
  ConsumerState<HotlinesDirectoryModal> createState() => _HotlinesDirectoryModalState();
}

class _HotlinesDirectoryModalState extends ConsumerState<HotlinesDirectoryModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  String _selectedCategory = 'ALL';
  final List<HotlineItemModel> _hotlines = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _categories = const [
    'ALL',
    'Emergency',
    'Medical',
    'Police',
    'Fire',
    'Disaster',
    'Utilities',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHotlines();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _fetchHotlines();
    });
  }

  Future<void> _fetchHotlines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final search = _searchController.text.trim();

      final queryParams = <String, dynamic>{};
      if (_selectedCategory != 'ALL') {
        queryParams['category'] = _selectedCategory;
      }
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      _cancelToken?.cancel();
      _cancelToken = CancelToken();

      final res = await apiClient.dio.get(
        AppConstants.hotlinesEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (!mounted) return;

      if (res.data != null && res.data['success'] == true) {
        final rawList = res.data['hotlines'] as List? ?? [];
        setState(() {
          _hotlines.clear();
          _hotlines.addAll(rawList.map((e) => HotlineItemModel.fromJson(e)).toList());
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.data?['error'] ?? "Failed to load hotlines.";
        });
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? "Network error loading hotlines.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _copyNumber(String name, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          "$name hotline ($number) copied!",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              "Unable to launch dialer for $number",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        );
      }
    }
  }

  void _showHotlineDetailSheet(HotlineItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HotlineDetailSheet(
        item: item,
        onCopy: () => _copyNumber(item.name, item.primaryNumber),
        onCall: () => _callNumber(item.primaryNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.call_rounded, color: Color(0xFF8B5CF6), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "EMERGENCY HOTLINES",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.getTextPrimary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!_isLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_hotlines.length}",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Official 24/7 Police, Fire, Rescue & Public Safety Contacts",
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
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search agency, department, or phone...",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.getTextSecondary(context), size: 18),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 16, color: AppColors.getTextSecondary(context)),
                          onPressed: () {
                            _searchController.clear();
                            _fetchHotlines();
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

          // Category Chips
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
                    cat == 'ALL' ? 'All Hotlines' : cat,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF8B5CF6),
                  backgroundColor: AppColors.getSurface(context),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF8B5CF6) : AppColors.getBorder(context),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _fetchHotlines();
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Content List
          Expanded(
            child: _buildListContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
              const SizedBox(height: 10),
              Text(
                "Unable to load emergency directory",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context)),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _fetchHotlines,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                child: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_hotlines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_disabled_rounded, size: 40, color: AppColors.getTextSecondary(context)),
            const SizedBox(height: 10),
            Text(
              "No emergency hotlines found",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try selecting another category or clear search filter.",
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _hotlines.length,
      itemBuilder: (context, index) {
        final item = _hotlines[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showHotlineDetailSheet(item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.call_rounded, size: 18, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.getTextPrimary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.primaryNumber,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        if (item.address != null && item.address!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.address!,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: AppColors.getTextSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Copy shortcut button
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF8B5CF6)),
                    onPressed: () => _copyNumber(item.name, item.primaryNumber),
                    tooltip: "Copy number",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HotlineDetailSheet extends StatelessWidget {
  final HotlineItemModel item;
  final VoidCallback onCopy;
  final VoidCallback onCall;

  const _HotlineDetailSheet({
    required this.item,
    required this.onCopy,
    required this.onCall,
  });

  String _getServiceDescription(String category, String name) {
    final cat = category.toUpperCase();
    if (cat.contains('FIRE') || name.toUpperCase().contains('FIRE')) {
      return "Handles local fire suppression, rescue operations, fire safety inspections, and emergency hazard response across Mapandan.";
    } else if (cat.contains('POLICE') || name.toUpperCase().contains('PNP') || name.toUpperCase().contains('POLICE')) {
      return "Provides 24/7 law enforcement, peace and order maintenance, crime investigation, and rapid community emergency response.";
    } else if (cat.contains('DISASTER') || cat.contains('RESCUE') || name.toUpperCase().contains('MDRRMO')) {
      return "Spearheads municipal disaster risk reduction, severe weather monitoring, evacuation operations, and medical ambulance emergency transport.";
    } else if (cat.contains('MEDICAL') || cat.contains('HOSPITAL') || name.toUpperCase().contains('HEALTH')) {
      return "Delivers primary healthcare, maternal and child medical assistance, outpatient emergency treatment, and clinical consultations.";
    } else if (cat.contains('UTILITIES') || name.toUpperCase().contains('WATER') || name.toUpperCase().contains('PANELCO')) {
      return "Manages vital municipal utility infrastructure, power outage restorations, water distribution assistance, and hazard troubleshooting.";
    } else if (name.toUpperCase().contains('MAYOR')) {
      return "Coordinates municipal governance, executive emergency directives, citizen administrative assistance, and public safety command.";
    }
    return "Official registered government and public safety agency dedicated to municipal service and rapid citizen support.";
  }

  @override
  Widget build(BuildContext context) {
    final hasBothNumbers = (item.mobileNumber != null && item.mobileNumber!.trim().isNotEmpty) &&
        (item.telephone != null && item.telephone!.trim().isNotEmpty);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: ListView(
        children: [
          // Drag Handle
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

          // Header Icon & Un-truncated Department Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: const Icon(LucideIcons.phoneCall, color: Color(0xFF8B5CF6), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getTextPrimary(context),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Responsive Category & 24/7 Availability Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF8B5CF6),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "24/7 ACTIVE HOTLINE",
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Primary Call & Copy Action Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.phone, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      "PRIMARY DISPATCH NUMBER",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextSecondary(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.primaryNumber,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Call Now Action
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(LucideIcons.phoneCall, size: 16),
                        label: const Text("CALL NOW"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Copy Number Action
                    Expanded(
                      flex: 5,
                      child: OutlinedButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text("COPY NUMBER"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (hasBothNumbers) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceElevated(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.phone, size: 15, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Landline / Tel: ${item.telephone}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF8B5CF6)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.telephone!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF8B5CF6),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: Text("Landline copied to clipboard!", style: GoogleFonts.inter(fontSize: 12)),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Complete Address & Jurisdiction Location Card
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
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    Text(
                      "COMPLETE LOCATION & JURISDICTION",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getTextSecondary(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (item.address != null && item.address!.trim().isNotEmpty)
                      ? item.address!
                      : "Poblacion, Mapandan, Pangasinan (Municipal Command Area)",
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Municipality of Mapandan, 2429 Pangasinan, Philippines",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Description & Scope of Services
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
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      "SCOPE OF ASSISTANCE & SERVICES",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getTextSecondary(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getServiceDescription(item.category, item.name),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
