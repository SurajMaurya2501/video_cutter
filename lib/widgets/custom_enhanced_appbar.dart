import 'package:flutter/material.dart';
import 'package:video_cutter/main.dart';

class CustomEnhancedAppbar extends StatelessWidget {
  final BuildContext context;
  final bool isDarkMode;
  final ThemeProvider themeProvider;
  const CustomEnhancedAppbar(
      {required this.context,
      required this.isDarkMode,
      required this.themeProvider,
      super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      floating: true,
      elevation: 4,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.indigo[900]!, Colors.black]
                : [Colors.indigoAccent, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      title: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: const Text(
          'MovieSlicer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
      ),
      centerTitle: true,
      foregroundColor: isDarkMode ? Colors.white : Colors.black,
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => _showAppInfoDialog(context),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: Colors.indigoAccent,
              thumbColor: WidgetStatePropertyAll(
                  isDarkMode ? Colors.white : Colors.indigoAccent),
            ),
          ),
        ),
      ],
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About MovieSlicer'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A powerful tool for splitting videos into chunks.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
