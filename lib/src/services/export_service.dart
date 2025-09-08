import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:path/path.dart' as p;

import '../models/editor_state.dart';
 
class ExportResult {
  ExportResult({required this.success, this.outputPath, this.log});
  final bool success;
  final String? outputPath;
  final String? log;
}

class ExportService {
  static Future<ExportResult> exportEdited({
    required String sourcePath,
    required List<VideoSegment> segments,
    required String outputPath,
  }) async {
    if (segments.isEmpty) {
      return ExportResult(success: false, log: 'No playable segments');
    }

    // Single segment: try stream copy with -ss/-to, fallback to reencode
    if (segments.length == 1) {
      final VideoSegment s = segments.first;
      final String copyCmd = '-y -ss ${s.start} -to ${s.end} -i "${sourcePath}" -c copy -map 0:v:0 -map 0:a? "${outputPath}"';
      final bool okCopy = await _run(copyCmd);
      if (okCopy) return ExportResult(success: true, outputPath: outputPath);
      final String reencodeCmd = '-y -ss ${s.start} -to ${s.end} -i "${sourcePath}" -c:v libx264 -crf 20 -preset veryfast -c:a aac -b:a 128k "${outputPath}"';
      final bool okRe = await _run(reencodeCmd);
      return ExportResult(success: okRe, outputPath: okRe ? outputPath : null);
    }

    // Multi segment: create concat with temp trimmed files, try copy then fallback
    final Directory tmpDir = Directory(p.join(File(outputPath).parent.path, 'parts_${DateTime.now().millisecondsSinceEpoch}'));
    await tmpDir.create(recursive: true);
    final List<String> partPaths = <String>[];
    for (int i = 0; i < segments.length; i++) {
      final VideoSegment s = segments[i];
      final String part = p.join(tmpDir.path, 'part_$i.mp4');
      final String trimCopy = '-y -ss ${s.start} -to ${s.end} -i "${sourcePath}" -c copy -map 0:v:0 -map 0:a? "$part"';
      final bool ok = await _run(trimCopy);
      if (!ok) {
        final String trimRe = '-y -ss ${s.start} -to ${s.end} -i "${sourcePath}" -c:v libx264 -crf 20 -preset veryfast -c:a aac -b:a 128k "$part"';
        final bool ok2 = await _run(trimRe);
        if (!ok2) return ExportResult(success: false, log: 'Trim failed');
      }
      partPaths.add(part);
    }

    final String listPath = p.join(tmpDir.path, 'list.txt');
    final String listContent = partPaths.map((String pth) => "file '$pth'").join('\n');
    await File(listPath).writeAsString(listContent);

    // concat
    final String concatCopy = '-y -f concat -safe 0 -i "$listPath" -c copy "$outputPath"';
    final bool okConcat = await _run(concatCopy);
    if (okConcat) return ExportResult(success: true, outputPath: outputPath);

    final String concatRe = '-y -f concat -safe 0 -i "$listPath" -c:v libx264 -crf 20 -preset veryfast -c:a aac -b:a 128k "$outputPath"';
    final bool okConcatRe = await _run(concatRe);
    return ExportResult(success: okConcatRe, outputPath: okConcatRe ? outputPath : null);
  }

  static Future<bool> _run(String cmd) async {
    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();
    return ReturnCode.isSuccess(returnCode);
  }
}





