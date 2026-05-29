import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.caption,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String unit;
  final String caption;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    style: textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0,
                    ),
                    children: [
                      TextSpan(text: value),
                      TextSpan(
                        text: ' $unit',
                        style: textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  caption,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
