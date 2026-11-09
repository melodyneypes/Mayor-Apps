import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_service_model.dart';

class TuluyanDirectoryModal extends ConsumerStatefulWidget {
  const TuluyanDirectoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TuluyanDirectoryModal(),
    );
  }

  @override
  ConsumerState<TuluyanDirectoryModal> createState() => _TuluyanDirectoryModalState();
}

class _TuluyanDirectoryModalState extends ConsumerState<TuluyanDirectoryModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  final List<AccommodationItemModel> _accommodations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchAccommodations(page: 1);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadNextPage();
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
          _accommodations.clear();
        });
        _fetchAccommodations(page: 1);
      }
    });
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetchAccommodations(page: _currentPage + 1);
  }

  Future<void> _fetchAccommodations({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel();
        _cancelToken = CancelToken();
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': 15,
      };

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final res = await apiClient.dio.get(
        AppConstants.tuluyanEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (res.data != null && res.data['success'] == true) {
        final rawList = res.data['accommodations'] as List? ?? [];
        final totalCount = (res.data['totalCount'] as num?)?.toInt() ?? 0;
        final hasMore = res.data['hasMore'] == true;

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _totalCount = totalCount;
          _hasMore = hasMore;
          if (page == 1) _accommodations.clear();
          _accommodations.addAll(rawList.map((e) => AccommodationItemModel.fromJson(e)).toList());
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception(res.data?['error'] ?? "Failed to load accommodations.");
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.message ?? "Network error.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showDetailSheet(AccommodationItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TuluyanDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hotel_rounded, color: Color(0xFF0EA5E9), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "TULUYAN HUB",
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.2,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Municipal Lodgings, Staycations & Accommodations",
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.getTextSecondary(context), size: 20),
                ),
              ],
            ),
          ),

          // Search Bar
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
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search name, type, barangay, or address...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextSecondary(context), fontWeight: FontWeight.w500),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.getTextSecondary(context), size: 18),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 16, color: AppColors.getTextSecondary(context)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentPage = 1;
                              _hasMore = true;
                              _accommodations.clear();
                            });
                            _fetchAccommodations(page: 1);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
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
              Text("Unable to load accommodations", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context))),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => _fetchAccommodations(page: 1),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                child: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_accommodations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hotel_class_rounded, color: Color(0xFF0EA5E9), size: 36),
            const SizedBox(height: 10),
            Text("No accommodations found", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context))),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _accommodations.length + (_hasMore ? 1 : (_accommodations.isNotEmpty ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index == _accommodations.length) {
          if (_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9), strokeWidth: 2)),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "— End of Tuluyan Directory (${_accommodations.length} loaded) —",
                  style: GoogleFonts.inter(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.getTextSecondary(context)),
                ),
              ),
            );
          }
        }

        final item = _accommodations[index];
        return GestureDetector(
          onTap: () => _showDetailSheet(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: AppColors.getSurfaceElevated(context),
                    child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.hotel_rounded, size: 20, color: Color(0xFF0EA5E9)),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.hotel_rounded, size: 20, color: Color(0xFF0EA5E9)),
                          ),
                  ),
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
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF0EA5E9)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${item.address} • ${item.barangay}",
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.getTextSecondary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.priceRange != null && item.priceRange!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Rate: ${item.priceRange}",
                          style: GoogleFonts.inter(fontSize: 9.5, fontStyle: FontStyle.italic, color: const Color(0xFF10B981)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.getTextSecondary(context)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TuluyanDetailSheet extends StatelessWidget {
  final AccommodationItemModel item;
  const _TuluyanDetailSheet({required this.item});

  Future<void> _openGoogleMaps(BuildContext context) async {
    if (item.googleMapsUrl == null || item.googleMapsUrl!.trim().isEmpty) return;

    final targetUri = Uri.parse(item.googleMapsUrl!.trim());

    try {
      final launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              "Could not open Google Maps.",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              "Unable to open navigation link.",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.getSurfaceElevated(context),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => _buildTuluyanBannerPlaceholder(context),
                    )
                  : _buildTuluyanBannerPlaceholder(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(item.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context))),
          const SizedBox(height: 4),
          Text("${item.type} • ${item.barangay}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(item.description.isNotEmpty ? item.description : "Official lodging and accommodation facility in Mapandan.", style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextSecondary(context))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.getSurfaceElevated(context), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ACCOMMODATION DETAILS", style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.getTextSecondary(context))),
                const SizedBox(height: 6),
                Text(item.address, style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w600)),
                if (item.priceRange != null) ...[
                  const SizedBox(height: 4),
                  Text("Estimated Rate: ${item.priceRange}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981))),
                ],
                if (item.amenities != null) ...[
                  const SizedBox(height: 4),
                  Text("Amenities: ${item.amenities}", style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context))),
                ],
                if (item.contactNumber != null) ...[
                  const SizedBox(height: 4),
                  Text("Contact: ${item.contactNumber}", style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context))),
                ],
              ],
            ),
          ),
          if (item.googleMapsUrl != null && item.googleMapsUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(context),
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text("OPEN IN GOOGLE MAPS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTuluyanBannerPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0284C7).withValues(alpha: 0.25),
            const Color(0xFF0F172A),
          ],
        ),
        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.25)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.hotel_rounded,
              size: 130,
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.hotel_rounded, size: 28, color: Color(0xFF0EA5E9)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                ),
                child: Text(
                  "EMAPANDAN TULUYAN & LODGING",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
