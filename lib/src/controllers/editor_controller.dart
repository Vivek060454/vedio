import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/editor_state.dart';
import '../services/export_service.dart';
import '../services/thumbnail_service.dart';


class EditorController extends GetxController {
  final Rx<EditorState> state = EditorState.empty().obs;

  final Rx<VideoPlayerController?> player = Rx<VideoPlayerController?>(null);
  final RxBool isPlaying = false.obs;
  final RxDouble playheadSeconds = 0.0.obs;

  Future<void> onImportPressed() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final String? path = result.files.single.path;
    if (path == null) return;

    await loadVideo(File(path));
  }
  
  
  
  

  Future<void> loadVideo(File file) async {
    await disposePlayer();
    final VideoPlayerController controller = VideoPlayerController.file(file);
    await controller.initialize();
    await controller.setLooping(false);
    player.value = controller;
    _attachPlayerListener(controller);

    final double duration = controller.value.duration.inMilliseconds / 1000.0;
    state.value = EditorState.fromSingleSource(file.path, duration);

    
    
    
    await ThumbnailService.generateTimelineThumbnails(
      videoPath: file.path,
      durationSeconds: duration,
      onGenerated: (List<File> thumbs) {
        state.update((EditorState? s) {
          if (s == null) return;
          s.timelineThumbnails = thumbs;
        });
      },
    );
    update();
  }

  Future<void> disposePlayer() async {
    final VideoPlayerController? c = player.value;
    player.value = null;
    if (c != null) {
      await c.pause();
      await c.dispose();
    }
  }

  void _attachPlayerListener(VideoPlayerController c) {
    c.addListener(() {
      final Duration pos = c.value.position;
      final double t = pos.inMilliseconds / 1000.0;
      // Update selected segment based on playhead
      state.update((EditorState? s) {
        if (s == null) return;
        final int idx = _segmentIndexAt(s, t);
        if (idx != -1 && idx != s.selectedIndex) s.selectedIndex = idx;
        // If within a deleted segment, seek to the next playable start
        if (idx != -1 && s.segments[idx].deleted) {
          final double? nextStart = _nextPlayableStartAfter(s, s.segments[idx].end);
          if (nextStart != null) {
            c.seekTo(Duration(milliseconds: (nextStart * 1000).toInt()));
          } else {
            // end of playback
            c.pause();
          }
        }
      });
    });
  }

  int _segmentIndexAt(EditorState s, double t) {
    for (int i = 0; i < s.segments.length; i++) {
      final VideoSegment seg = s.segments[i];
      if (t >= seg.start && t <= seg.end) return i;
    }
    return -1;
  }

  double? _nextPlayableStartAfter(EditorState s, double t) {
    for (final VideoSegment seg in s.segments) {
      if (seg.end <= t) continue;
      if (!seg.deleted) return seg.start;
    }
    return null;
  }

  Widget buildPlayer(BuildContext context) {
    final VideoPlayerController? c = player.value;
    if (c == null || !c.value.isInitialized) {
      return const Text('Import a video to start');
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          VideoPlayer(c),
          VideoProgressIndicator(c, allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: Colors.deepPurple)),
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(children: <Widget>[
              IconButton(
                icon: Icon(isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
                onPressed: () async {
                  if (isPlaying.value) {
                    await c.pause();
                    isPlaying.value = false;
                  } else {
                    await c.play();
                    isPlaying.value = true;
                  }
                },
              ),
            ]),
          )
        ],
      ),
    );
  }

  Widget buildTimeline(BuildContext context) {
    final EditorState s = state.value;
    if (!s.hasSource) {
      return const SizedBox(height: 100, child: Center(child: Text('Timeline')));
    }
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (BuildContext context, int index) {
                if (index >= s.timelineThumbnails.length) return const SizedBox();
                final File f = s.timelineThumbnails[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(f, height: 100),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemCount: s.timelineThumbnails.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Text('Segments: ${s.segments.length} (deleted skipped)')
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onSplitPressed() {
    final VideoPlayerController? c = player.value;
    if (c == null) return;
    final double t = c.value.position.inMilliseconds / 1000.0;
    state.update((EditorState? s) => s?.splitAt(t));
    update();
  }

  void onDeletePressed() {
    state.update((EditorState? s) => s?.toggleDeleteSelected());
    update();
  }

  Future<void> onExportPressed() async {
    final EditorState s = state.value;
    if (!s.hasSource) return;
    final Directory outDir = await getTemporaryDirectory();
    final String outPath = p.join(outDir.path, 'export_${DateTime.now().millisecondsSinceEpoch}.mp4');

    final ExportResult result = await ExportService.exportEdited(
      sourcePath: s.sourcePath!,
      segments: s.playableSegments,
      outputPath: outPath,
    );

    Get.snackbar('Export', result.success ? 'Saved: ${result.outputPath}' : 'Failed');
  }
}


