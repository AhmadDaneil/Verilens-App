// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark   = settings.darkMode;

    // Adaptive colours that work in both modes
    final cardColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color
        ?? AppColors.textPrimary;
    final textSecond = Theme.of(context).textTheme.bodyMedium?.color
        ?? AppColors.textSecond;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Appearance section ──────────────────────────────────────
            _SectionHeader(label: 'Appearance', textColor: textSecond),
            const SizedBox(height: 8),

            _SettingsCard(
              color: cardColor,
              child: Column(
                children: [
                  // Dark mode toggle
                  _SettingsRow(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    iconColor: AppColors.primary,
                    title: 'Dark Mode',
                    subtitle: isDark ? 'On' : 'Off',
                    textPrimary: textPrimary,
                    textSecond: textSecond,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeColor: AppColors.primary,
                      onChanged: (v) => context.read<SettingsProvider>().setDarkMode(v),
                    ),
                  ),

                  Divider(height: 1, color: Theme.of(context).dividerColor),

                  // Font size slider
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.text_fields,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Font Size',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: textPrimary)),
                                  Text(_fontLabel(settings.fontScale),
                                      style: TextStyle(
                                          fontSize: 12, color: textSecond)),
                                ],
                              ),
                            ),
                            // Live preview
                            Text(
                              'Aa',
                              style: TextStyle(
                                fontSize: 16 * settings.fontScale,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('A',
                                style: TextStyle(
                                    fontSize: 12, color: textSecond)),
                            Expanded(
                              child: Slider.adaptive(
                                value: settings.fontScale,
                                min: 0.8,
                                max: 1.4,
                                divisions: 6,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.primary.withOpacity(0.2),
                                onChanged: (v) =>
                                    context.read<SettingsProvider>().setFontScale(v),
                              ),
                            ),
                            Text('A',
                                style: TextStyle(
                                    fontSize: 20, color: textSecond)),
                          ],
                        ),
                        // Size labels under the slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              'XS', 'S', 'M', 'L', 'XL', 'XXL', 'Max'
                            ].map((l) => Text(l,
                                style: TextStyle(
                                    fontSize: 10, color: textSecond))).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Preview section ────────────────────────────────────────
            _SectionHeader(label: 'Preview', textColor: textSecond),
            const SizedBox(height: 8),

            _SettingsCard(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Headline Text',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This is how body text will appear across the app. '
                      'Adjust the slider above to find a comfortable reading size.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecond,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _PreviewChip(
                          label: 'REAL NEWS',
                          bg: AppColors.realLight,
                          fg: AppColors.real,
                        ),
                        const SizedBox(width: 8),
                        _PreviewChip(
                          label: 'FAKE NEWS',
                          bg: AppColors.fakeLight,
                          fg: AppColors.fake,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── About section ──────────────────────────────────────────
            _SectionHeader(label: 'About', textColor: textSecond),
            const SizedBox(height: 8),

            _SettingsCard(
              color: cardColor,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline,
                    iconColor: AppColors.primary,
                    title: 'Model',
                    subtitle: 'DistilBERT + Bi-LSTM hybrid',
                    textPrimary: textPrimary,
                    textSecond: textSecond,
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _SettingsRow(
                    icon: Icons.verified_outlined,
                    iconColor: AppColors.real,
                    title: 'Version',
                    subtitle: '1.0.0',
                    textPrimary: textPrimary,
                    textSecond: textSecond,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _fontLabel(double scale) {
    if (scale <= 0.8)  return 'Extra Small';
    if (scale <= 0.93) return 'Small';
    if (scale <= 1.07) return 'Normal';
    if (scale <= 1.2)  return 'Large';
    if (scale <= 1.33) return 'Extra Large';
    return 'Maximum';
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionHeader({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: textColor,
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _SettingsCard({required this.child, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecond;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecond,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: textSecond)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _PreviewChip(
      {required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );
}