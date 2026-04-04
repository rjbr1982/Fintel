// 🔒 STATUS: FROZEN. DO NOT MODIFY WITHOUT EXPLICIT OVERRIDE.
import 'dart:io';

void main() async {
  final buffer = StringBuffer();
  buffer.writeln('=== FINTEL BRAIN CAPSULE ===');
  buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');

  final filesToInclude = [
    'project_status.md',
    'AI_CONTEXT.md',
    'pubspec.yaml',
  ];

  for (final fileName in filesToInclude) {
    final file = File(fileName);
    if (await file.exists()) {
      buffer.writeln('--- FILE: $fileName ---');
      buffer.writeln(await file.readAsString());
      buffer.writeln('\n');
    }
  }

  final libDir = Directory('lib');
  if (await libDir.exists()) {
    final List<FileSystemEntity> entities = await libDir.list(recursive: true).toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        buffer.writeln('--- FILE: ${entity.path} ---');
        buffer.writeln(await entity.readAsString());
        buffer.writeln('\n');
      }
    }
  }

  final assetsDir = Directory('assets');
  if (!await assetsDir.exists()) {
    await assetsDir.create();
  }

  final outputFile = File('assets/fintel_brain_capsule.txt');
  await outputFile.writeAsString(buffer.toString());
  
  // Using stdout.writeln instead of print to strictly comply with zero-warnings policy
  stdout.writeln('✅ Brain Capsule generated successfully at assets/fintel_brain_capsule.txt');
}