import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ai_expense_logger/services/export_service.dart';

Future<ExportFormat?> showExportBottomSheet(BuildContext context) {
  return showModalBottomSheet<ExportFormat>(
    context: context,
    backgroundColor: Colors.transparent, // Transparent for glass effect
    barrierColor: Colors.black.withOpacity(0.3), // Dim background
    isScrollControlled: true,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Frosted blur
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // Glass transparent layer
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(
                color: Colors.white.withOpacity(0.25), // Glass border shine
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Drag Handle
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                /// Title
                Text(
                  "Export Data",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),

                const SizedBox(height: 25),

                _GlassTile(
                  icon: Icons.picture_as_pdf_outlined,
                  label: "Export as PDF",
                  color: Colors.redAccent,
                  onTap: () => Navigator.pop(context, ExportFormat.pdf),
                ),
                _GlassTile(
                  icon: Icons.description_outlined,
                  label: "Export as CSV",
                  color: Colors.orange,
                  onTap: () => Navigator.pop(context, ExportFormat.csv),
                ),
                _GlassTile(
                  icon: Icons.table_chart_outlined,
                  label: "Export as Excel",
                  color: Colors.green,
                  onTap: () => Navigator.pop(context, ExportFormat.excel),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _GlassTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlassTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.12), // semi-transparent tile
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            /// Icon with glow
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Icon(icon, size: 26, color: Colors.white),
            ),

            const SizedBox(width: 18),

            /// Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ),

            Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
