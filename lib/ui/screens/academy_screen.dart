// 🔒 STATUS: EDITED (Fixed Linter errors - Added const to ColorScheme and side to RoundedRectangleBorder)
import 'package:flutter/material.dart';
import '../../data/academy_content.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  Widget _buildBlock(AcademyBlock block) {
    const textColor = Colors.white70;

    switch (block.type) {
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            block.text,
            style: const TextStyle(color: textColor, fontSize: 15, height: 1.6),
          ),
        );
      case BlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•', style: TextStyle(color: Color(0xFFFFB800), fontSize: 18, height: 1.2)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.text,
                  style: const TextStyle(color: textColor, fontSize: 15, height: 1.6),
                ),
              ),
            ],
          ),
        );
      case BlockType.boldSubtitle:
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            block.text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color deepSlate = Color(0xFF121212);
    const Color goldAccents = Color(0xFFFFB800);

    return Scaffold(
      backgroundColor: deepSlate,
      appBar: AppBar(
        backgroundColor: deepSlate,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, color: goldAccents, size: 24),
            SizedBox(width: 8),
            Text(
              'המדריך לחירות פיננסית',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: academyChapters.length,
        itemBuilder: (context, index) {
          final chapter = academyChapters[index];
          
          return Card(
            color: Colors.blueGrey[900],
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blueGrey[800]!),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: const ColorScheme.dark(
                  primary: goldAccents, // Sets expansion icon color when expanded
                ),
              ),
              child: ExpansionTile(
                iconColor: goldAccents,
                collapsedIconColor: Colors.blueGrey[400],
                title: Text(
                  chapter.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: chapter.content.map((block) => _buildBlock(block)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}