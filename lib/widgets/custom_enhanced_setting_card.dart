import 'package:flutter/material.dart';

class CustomEnhancedSettingCard extends StatelessWidget {
  final BuildContext context;
  final bool isDarkMode;
  final TextEditingController secondsController;
  const CustomEnhancedSettingCard(
      {required this.context,
      required this.secondsController,
      required this.isDarkMode,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.indigoAccent),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: secondsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chunk duration (seconds)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                prefixIcon: Icon(Icons.timer, color: Colors.indigoAccent),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
