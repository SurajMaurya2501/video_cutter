import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QualityToggleCard extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const QualityToggleCard({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<QualityToggleCard> createState() => _QualityToggleCardState();
}

class _QualityToggleCardState extends State<QualityToggleCard> {
  late bool _highQualityMode;
  final _animationDuration = const Duration(milliseconds: 300);
  final _toggleWidth = 200.0;
  final _toggleHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _highQualityMode = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed,
                    size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Processing Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _highQualityMode
                  ? 'Higher quality output with slower processing'
                  : 'Faster processing with medium quality',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              width: _toggleWidth,
              height: _toggleHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(_toggleHeight / 2),
              ),
              child: Stack(
                children: [
                  // Background labels with icons
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                color: !_highQualityMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fast',
                                style: TextStyle(
                                  color: !_highQualityMode
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.high_quality,
                                color: _highQualityMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'High Quality',
                                style: TextStyle(
                                  color: _highQualityMode
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Animated toggle thumb
                  AnimatedAlign(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    alignment: _highQualityMode
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: _toggleWidth / 2,
                      height: _toggleHeight - 4,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(_toggleHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _highQualityMode ? 'QUALITY' : 'SPEED',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Gesture detector for whole toggle
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(_toggleHeight / 2),
                        onTap: () {
                          setState(() {
                            _highQualityMode = !_highQualityMode;
                            widget.onChanged(_highQualityMode);
                          });
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: _animationDuration,
              child: Text(
                _highQualityMode
                    ? '✓ Better compression quality\n✓ Slower processing'
                    : '✓ Faster processing\n✓ Medium quality\n✓ Original file size',
                style: Theme.of(context).textTheme.bodySmall,
                key: ValueKey<bool>(_highQualityMode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
