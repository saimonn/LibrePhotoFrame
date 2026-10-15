import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'slide_duration_scale.dart';

class SlideshowSection extends StatelessWidget {
  final int slideDurationStep;
  final double transitionDurationSeconds;
  final bool blurBorders;
  final String photoFit;
  final bool pairPhotos;
  final String photoOrder;
  final String screenOrientation;
  final ValueChanged<int> onSlideDurationChanged;
  final ValueChanged<double> onTransitionDurationChanged;
  final ValueChanged<bool> onBlurBordersChanged;
  final ValueChanged<String> onPhotoFitChanged;
  final ValueChanged<bool> onPairPhotosChanged;
  final ValueChanged<String> onPhotoOrderChanged;
  final ValueChanged<String> onScreenOrientationChanged;
  final Widget Function() buildPhotoFitSelector;
  final Widget Function() buildPhotoOrderSelector;
  final Widget Function() buildScreenOrientationSelector;

  const SlideshowSection({
    super.key,
    required this.slideDurationStep,
    required this.transitionDurationSeconds,
    required this.blurBorders,
    required this.photoFit,
    required this.pairPhotos,
    required this.photoOrder,
    required this.screenOrientation,
    required this.onSlideDurationChanged,
    required this.onTransitionDurationChanged,
    required this.onBlurBordersChanged,
    required this.onPhotoFitChanged,
    required this.onPairPhotosChanged,
    required this.onPhotoOrderChanged,
    required this.onScreenOrientationChanged,
    required this.buildPhotoFitSelector,
    required this.buildPhotoOrderSelector,
    required this.buildScreenOrientationSelector,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.sectionSlideshow),
        const SizedBox(height: 8),

        Builder(
          builder: (context) {
            return _buildSliderSetting(
              context: context,
              icon: Icons.timer,
              title: l10n.slideDuration,
              value: slideDurationStep.toDouble(),
              min: 0,
              max: SlideDurationScale.lastStep.toDouble(),
              divisions: SlideDurationScale.lastStep,
              unit: _formatSlideDuration(l10n, slideDurationStep).unit,
              formatValue: (v) =>
                  '${_formatSlideDuration(l10n, v.round()).value}',
              onChanged: (value) {
                onSlideDurationChanged(value.round());
              },
            );
          },
        ),

        const SizedBox(height: 16),

        _buildSliderSetting(
          context: context,
          icon: Icons.blur_on,
          title: l10n.transitionDuration,
          value: transitionDurationSeconds,
          min: 0.5,
          max: 5.0,
          divisions: 9,
          unit: l10n.unitSeconds,
          formatValue: (v) => v.toStringAsFixed(1),
          onChanged: onTransitionDurationChanged,
        ),

        const SizedBox(height: 16),

        if (photoFit != 'cover' && photoFit != 'fill') ...[
          SwitchListTile(
            title: Text(l10n.blurBorders),
            subtitle: Text(l10n.blurBordersSubtitle),
            secondary: const Icon(Icons.blur_linear),
            value: blurBorders,
            onChanged: onBlurBordersChanged,
          ),
          const SizedBox(height: 16),
        ],

        buildPhotoFitSelector(),

        const SizedBox(height: 16),

        SwitchListTile(
          title: Text(l10n.pairPhotos),
          subtitle: Text(l10n.pairPhotosSubtitle),
          secondary: const Icon(Icons.view_column),
          value: pairPhotos,
          onChanged: onPairPhotosChanged,
        ),

        const SizedBox(height: 16),

        buildPhotoOrderSelector(),

        const SizedBox(height: 16),

        buildScreenOrientationSelector(),
      ],
    );
  }

  /// Splits a duration into the value and unit shown next to the slider:
  /// seconds below a minute, minutes below an hour, whole hours above.
  ({int value, String unit}) _formatSlideDuration(
    AppLocalizations l10n,
    int step,
  ) {
    final seconds = SlideDurationScale.secondsAt(step);
    if (seconds < 60) return (value: seconds, unit: l10n.unitSeconds);
    if (seconds < 3600) return (value: seconds ~/ 60, unit: l10n.unitMinutes);
    return (value: seconds ~/ 3600, unit: l10n.unitHours);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSliderSetting({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
    String Function(double)? formatValue,
  }) {
    final displayValue = formatValue != null ? formatValue(value) : '${value.round()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            Text(
              '$displayValue $unit',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
