import 'package:flutter/material.dart';

class CustomProcessingCard extends StatelessWidget {
  final BuildContext context;
  final bool isDarkMode;
  final bool isProcessing;
  final Animation<double> pulseAnimation;
  final bool shouldCancel;
  final bool isCreatingZip;
  final String currentOperation;
  final double progress;
  final VoidCallback? splitAndZip;
  final Function(double progress) getRemainingTime;
  final VoidCallback? cancelProcess;
  const CustomProcessingCard(
      {required this.context,
      required this.currentOperation,
      required this.isCreatingZip,
      required this.isDarkMode,
      required this.isProcessing,
      required this.progress,
      required this.pulseAnimation,
      required this.shouldCancel,
      required this.splitAndZip,
      required this.getRemainingTime,
      required this.cancelProcess,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isProcessing
                    ? null
                    : LinearGradient(
                        colors: [Colors.indigoAccent, Colors.purpleAccent],
                      ),
              ),
              child: ScaleTransition(
                scale:
                    isProcessing ? pulseAnimation : AlwaysStoppedAnimation(1.0),
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : splitAndZip,
                  icon: isProcessing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.content_cut, color: Colors.white),
                  label: Text(
                    shouldCancel
                        ? 'Cancelling...'
                        : isProcessing
                            ? isCreatingZip
                                ? 'Creating ZIP...'
                                : currentOperation
                            : 'Split & Export',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: isProcessing
                        ? (isDarkMode ? Colors.grey[700] : Colors.grey[200])
                        : Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            if (isProcessing) ...[
              const SizedBox(height: 20),
              Column(
                children: [
                  // Progress bar with gradient
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCreatingZip
                                        ? [Colors.amber, Colors.orange]
                                        : shouldCancel
                                            ? [Colors.red, Colors.redAccent]
                                            : [
                                                Colors.indigoAccent,
                                                Colors.purpleAccent
                                              ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 28),
                        onPressed: !shouldCancel ? cancelProcess : null,
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        isCreatingZip
                            ? 'Compressing chunks...'
                            : shouldCancel
                                ? 'Cancelling process...'
                                : 'Splitting video...',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              shouldCancel ? Colors.red : Colors.indigoAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!shouldCancel)
                        Text(
                          getRemainingTime(progress),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  if (isCreatingZip) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.archive, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Finalizing ZIP file...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
