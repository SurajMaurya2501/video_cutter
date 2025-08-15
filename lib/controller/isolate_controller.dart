import 'dart:io';

import 'package:archive/archive.dart';

class IsolateController {
  // This function runs in another isolate
  Future<void> zipInIsolate(String folderPath) async {
    final dir = Directory(folderPath);
    final zipFile = File('$folderPath.zip');

    // Example using archive package
    final archive = Archive();
    for (final file in dir.listSync()) {
      if (file is File) {
        archive.addFile(ArchiveFile(
          file.uri.pathSegments.last,
          file.lengthSync(),
          file.readAsBytesSync(),
        ));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipData!);
  }
}
