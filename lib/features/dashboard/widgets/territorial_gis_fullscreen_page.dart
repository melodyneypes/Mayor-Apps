import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/dashboard_model.dart';
import 'mapandan_boundary.dart';

class CategoryConfig {
  final Color pinColor;
  final IconData icon;
  final String label;

  const CategoryConfig({
    required this.pinColor,
    required this.icon,
    required this.label,
  });

  static CategoryConfig fromCategory(String category) {
    switch (category) {
      case "MUNICIPAL_FACILITY":
        return const CategoryConfig(
          pinColor: Color(0xFF2563EB),
          icon: LucideIcons.building2,
          label: "Municipal Facility",
        );
      case "PUBLIC_MARKET":
        return const CategoryConfig(
          pinColor: Color(0xFFD97706),
          icon: LucideIcons.shoppingBag,
          label: "Public Market",
        );
      case "HEALTH_CENTER":
        return const CategoryConfig(
          pinColor: Color(0xFF059669),
          icon: LucideIcons.heartPulse,
          label: "Rural Health Unit / Clinic",
        );
      case "POLICE_STATION":
        return const CategoryConfig(
          pinColor: Color(0xFF4F46E5),
          icon: LucideIcons.shieldAlert,
          label: "PNP / Police Station",
        );
      case "FIRE_STATION":
        return const CategoryConfig(
          pinColor: Color(0xFFDC2626),
          icon: LucideIcons.flame,
          label: "BFP / Fire Station",
        );
      case "RESCUE_MDRRMO":
        return const CategoryConfig(
          pinColor: Color(0xFFEA580C),
          icon: LucideIcons.siren,
          label: "Rescue / MDRRMO",
        );
      case "CEMETERY":
        return const CategoryConfig(
          pinColor: Color(0xFF9333EA),
          icon: LucideIcons.cross,
          label: "Cemetery / Memorial",
        );
      case "OTHER":
      default:
        return const CategoryConfig(
          pinColor: Color(0xFFE11D48),
          icon: LucideIcons.mapPin,
          label: "Landmark",
        );
    }
  }
}

void showPlaceDetailsModal(BuildContext context, MapPlaceItem place, CategoryConfig config) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.pinColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: config.pinColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(config.icon, color: config.pinColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.pinColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          config.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (place.description != null && place.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                place.description!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.compass, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Text(
                    "Lat: ${place.latitude.toStringAsFixed(6)} | Lng: ${place.longitude.toStringAsFixed(6)}",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class TerritorialGisFullScreenPage extends StatefulWidget {
  final List<MapPlaceItem> places;
  final LatLng initialCenter;
  final double initialZoom;

  const TerritorialGisFullScreenPage({
    super.key,
    required this.places,
    required this.initialCenter,
    this.initialZoom = 14.5,
  });

  @override
  State<TerritorialGisFullScreenPage> createState() => _TerritorialGisFullScreenPageState();
}

class _TerritorialGisFullScreenPageState extends State<TerritorialGisFullScreenPage> {
  static final LatLng _defaultMapandanCenter = LatLng(16.0260, 120.4505);
  late final MapController _mapController;
  MapPlaceItem? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 0.8);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 0.8);
  }

  void _recenter() {
    _mapController.move(_defaultMapandanCenter, 14.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-Screen Interactive GIS Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 11.0,
              maxZoom: 18.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Pure Esri High-Resolution Satellite Imagery Layer
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.emapandan.mayor_apps',
                maxNativeZoom: 18,
                maxZoom: 19,
              ),

              // Mapandan Territorial Boundary (Glowing Cyan Outer Halo Line)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: kMapandanBoundaryCoords,
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
                    strokeWidth: 6.0,
                  ),
                ],
              ),

              // Mapandan Territorial Boundary (Polygon Fill Tint & Crisp Border)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: kMapandanBoundaryCoords,
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.06),
                    borderColor: const Color(0xFF0284C7),
                    borderStrokeWidth: 2.2,
                  ),
                ],
              ),

              // Landmark Markers
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
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: config.pinColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: config.pinColor.withValues(alpha: isSelected ? 0.95 : 0.7),
                                  blurRadius: isSelected ? 20 : 14,
                                  spreadRadius: isSelected ? 4 : 1,
                                ),
                                const BoxShadow(
                                  color: Colors.black87,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              config.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xEB020617),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
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
                                fontSize: 9.5,
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

          // 2. Top Header Navigation Bar (Glassmorphic)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Exit Fullscreen Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xEE0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.arrowLeft, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  "Exit Full Screen",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Landmark Count Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xDD0F172A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 6),
                            Text(
                              "${widget.places.length} Landmarks",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Quick Map Controls (Zoom In, Zoom Out, Recenter)
          Positioned(
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControlButton(
                  icon: LucideIcons.plus,
                  tooltip: "Zoom In",
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  icon: LucideIcons.minus,
                  tooltip: "Zoom Out",
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 12),
                _buildMapControlButton(
                  icon: LucideIcons.crosshair,
                  tooltip: "Re-center Map",
                  iconColor: const Color(0xFF38BDF8),
                  onTap: _recenter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xEE0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}

