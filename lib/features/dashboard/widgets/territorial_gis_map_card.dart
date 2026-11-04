import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/dashboard_model.dart';
import 'mapandan_boundary.dart';
import 'territorial_gis_fullscreen_page.dart';

class TerritorialGisMapCard extends StatefulWidget {
  final List<MapPlaceItem> places;

  const TerritorialGisMapCard({
    super.key,
    required this.places,
  });

  @override
  State<TerritorialGisMapCard> createState() => _TerritorialGisMapCardState();
}

class _TerritorialGisMapCardState extends State<TerritorialGisMapCard> {
  // Center of Mapandan, Pangasinan
  static final LatLng _mapandanCenter = LatLng(16.0260, 120.4505);

  late final MapController _mapController;
  MapPlaceItem? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _openFullScreenMap() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TerritorialGisFullScreenPage(
          places: widget.places,
          initialCenter: currentCenter,
          initialZoom: currentZoom > 11.0 ? currentZoom : 14.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching web with "View Map" Fullscreen Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TERRITORIAL LANDMARKS & GIS MAP",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getTextPrimary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Geographic registry of municipal facilities and verified landmarks",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // "View Map" Action Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openFullScreenMap,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.maximize2, size: 13, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 5),
                          Text(
                            "View Map",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map Container
          SizedBox(
            height: 380,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapandanCenter,
                    initialZoom: 14.2,
                    minZoom: 11.0,
                    maxZoom: 18.5,
                  ),
                  children: [
                    // 1. Pure Esri High-Resolution Satellite Imagery Layer
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.emapandan.mayor_apps',
                      maxZoom: 19,
                    ),

                    // 2. Mapandan Territorial Boundary (Glowing Cyan Outer Halo Line)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: kMapandanBoundaryCoords,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                          strokeWidth: 6.0,
                        ),
                      ],
                    ),

                    // 3. Mapandan Territorial Boundary (Polygon Fill Tint & Crisp Border)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: kMapandanBoundaryCoords,
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.05),
                          borderColor: const Color(0xFF0284C7),
                          borderStrokeWidth: 2.2,
                        ),
                      ],
                    ),

                    // 4. Landmark Markers (100% Matched to Web Icons & Colors)
                    MarkerLayer(
                      markers: widget.places.map((place) {
                        final config = CategoryConfig.fromCategory(place.category);
                        final isSelected = _selectedPlace?.id == place.id;

                        return Marker(
                          point: LatLng(place.latitude, place.longitude),
                          width: 160,
                          height: 75,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlace = place;
                              });
                              _mapController.move(
                                LatLng(place.latitude, place.longitude),
                                16.5,
                              );
                              showPlaceDetailsModal(context, place, config);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Glowing Circular Disc Badge (Matching Web)
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: config.pinColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: config.pinColor.withValues(alpha: isSelected ? 0.9 : 0.65),
                                        blurRadius: isSelected ? 18 : 12,
                                        spreadRadius: isSelected ? 3 : 1,
                                      ),
                                      const BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    config.icon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                // Underneath Dark Capsule Label Pill (Matching Web)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xEB020617),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.white70 : Colors.white24,
                                      width: 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    place.name.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Floating Action Controls: Expand & Re-center (Bottom-Right)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fullscreen Expand Icon Button on embedded map
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openFullScreenMap,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xEE0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.maximize2, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Re-center Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _mapController.move(_mapandanCenter, 14.2);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xEE0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.crosshair, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
