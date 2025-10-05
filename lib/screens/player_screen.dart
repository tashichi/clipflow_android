import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/project.dart';
import '../managers/project_manager.dart';

class PlayerScreen extends StatefulWidget {
  final Project project;
  final VoidCallback onBack;

  const PlayerScreen({
    super.key,
    required this.project,
    required this.onBack,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  final ProjectManager _projectManager = ProjectManager();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // iOS版と同じ：createCompositionで統合動画を作成
      print('Creating composition for project: ${widget.project.name}');
      final compositionPath = await _projectManager.createComposition(widget.project);

      if (compositionPath == null) {
        setState(() {
          _errorMessage = 'Failed to create video composition';
          _isLoading = false;
        });
        return;
      }

      // 統合された動画を再生
      _controller = VideoPlayerController.file(File(compositionPath));
      await _controller!.initialize();
      
      setState(() {
        _isLoading = false;
      });

      // 自動再生開始（iOS版と同じ）
      _controller!.play();
      
      // ループ再生（iOS版と同じ）
      _controller!.setLooping(true);

    } catch (e) {
      print('Player initialization error: $e');
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildVideoPlayer(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${widget.project.segments.length} segments',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_isLoading || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // iOS版と同じ：統合された動画を再生
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildControls() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox(height: 100);
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
            onPressed: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
          ),
        ],
      ),
    );
  }
}