// 🔒 STATUS: EDITED (Light Theme Implementation for UI Consistency)
import 'package:flutter/material.dart';
import '../../data/academy_content.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  Widget _buildBlock(AcademyBlock block) {
    const textColor = Colors.black87;

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
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color goldAccents = Color(0xFFFFB800);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, color: goldAccents, size: 24),
            SizedBox(width: 8),
            Text(
              'המדריך לחירות פיננסית',
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
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
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: ColorScheme.light(
                  primary: Colors.amber.shade700,
                ),
              ),
              child: ExpansionTile(
                iconColor: Colors.amber.shade700,
                collapsedIconColor: Colors.blueGrey,
                title: Text(
                  chapter.title,
                  style: const TextStyle(
                    color: Colors.black87,
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