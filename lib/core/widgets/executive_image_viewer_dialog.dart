import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/api_constants.dart';

class ExecutiveImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final Color accentColor;

  const ExecutiveImageViewerDialog({
    super.key,
    required this.imageUrl,
    this.title,
    this.accentColor = const Color(0xFF38BDF8),
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    Color accentColor = const Color(0xFF38BDF8),
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => ExecutiveImageViewerDialog(
        imageUrl: imageUrl,
        title: title,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: const Color(0xF0090D1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center Image / Error Content
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 20),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: accentColor,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, error, stackTrace) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(LucideIcons.imageOff, size: 28, color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Photograph Unavailable",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Unable to load full resolution photograph from server.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Floating Header Bar with Optional Title & Dedicated Close Button
            Positioned(
              top: 10,
              left: 16,
              right: 10,
              child: Row(
                children: [
                  if (title != null && title!.isNotEmpty)
                    Expanded(
                      child: Text(
                        title!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

