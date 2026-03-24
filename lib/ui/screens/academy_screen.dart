// 🔒 STATUS: EDITED (Active Content View & Horizontal Chips Implementation, fixed spread operator lint)
import 'package:flutter/material.dart';
import '../../data/academy_content.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  int _selectedIndex = 0;

  Widget _buildBlock(AcademyBlock block) {
    const textColor = Colors.black87;

    switch (block.type) {
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            block.text,
            style: const TextStyle(color: textColor, fontSize: 16, height: 1.6),
          ),
        );
      case BlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•', style: TextStyle(color: Color(0xFFFFB800), fontSize: 20, height: 1.2)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.text,
                  style: const TextStyle(color: textColor, fontSize: 16, height: 1.6),
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
            style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold, height: 1.5),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color goldAccents = Color(0xFFFFB800);
    final activeChapter = academyChapters[_selectedIndex];

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
      body: Column(
        children: [
          // Horizontal Chips Navigation
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(academyChapters.length, (index) {
                  final isSelected = _selectedIndex == index;
                  // Shorten title for chip if it's too long, or use full title
                  final shortTitle = academyChapters[index].title.split(':').first;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        shortTitle,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.amber.shade700,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        }
                      },
                      elevation: isSelected ? 2 : 0,
                      pressElevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          
          // Separator line
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),

          // Active Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView(
                key: ValueKey<int>(_selectedIndex),
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Full Chapter Title
                  Text(
                    activeChapter.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Blocks - Removed .toList() to fix unnecessary_to_list_in_spreads lint
                  ...activeChapter.content.map((block) => _buildBlock(block)),
                  
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}