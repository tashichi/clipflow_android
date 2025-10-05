import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/project.dart';
import '../managers/project_manager.dart';

class CameraScreen extends StatefulWidget {
  final Project project;
  final VoidCallback onBack;

  const CameraScreen({
    super.key,
    required this.project,
    required this.onBack,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 権限チェック
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      setState(() {
        _errorMessage = 'Camera and microphone permissions are required';
      });
      return;
    }

    // カメラ取得
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      setState(() {
        _errorMessage = 'No cameras found';
      });
      return;
    }

    // 背面カメラを選択（iOS版と同じ）
    final backCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: true, // iOS版と同じ：音声有効
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
    });

    try {
      await _controller!.startVideoRecording();
      
      // 重要: 録画開始後、少し待ってから1秒タイマーを開始
      await Future.delayed(const Duration(milliseconds: 200));  // 録画初期化待ち
      
      // 1秒録画
      await Future.delayed(const Duration(milliseconds: 800));  // 残り800ms（合計1秒）

      if (_isRecording) {
        await _stopRecording();
      }
    } catch (e) {
      print('Recording error: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      final videoFile = await _controller!.stopVideoRecording();
      
      // セグメントを保存（iOS版と同じロジック）
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'segment_$timestamp.mp4';
      final savedPath = '${appDir.path}/$fileName';
      
      await File(videoFile.path).copy(savedPath);
      await File(videoFile.path).delete(); // 一時ファイル削除

      // ファイルサイズ確認（追加）
      final fileSize = await File(savedPath).length();
      print('=== Segment saved ===');
      print('File: $fileName');
      print('Size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      print('==================');

      // VideoSegment作成
      final segment = VideoSegment(
        id: timestamp,
        uri: savedPath,
        timestamp: DateTime.now(),
        cameraPosition: 'back',
        order: widget.project.segments.length,
      );

      // プロジェクトに追加
      final projectManager = ProjectManager();
      await projectManager.loadProjects();
      final currentProject = projectManager.projects.firstWhere(
        (p) => p.id == widget.project.id,
      );
      currentProject.segments.add(segment);
      currentProject.lastModified = DateTime.now();
      await projectManager.saveProjects();

      setState(() {
        _isRecording = false;
      });

      // トースト表示（iOS版と同じ）
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Segment ${currentProject.segments.length} recorded (${(fileSize / 1024).toStringAsFixed(0)} KB)'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Stop recording error: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),
            
            // カメラプレビュー
            Expanded(
              child: _buildCameraPreview(),
            ),
            
            // 録画ボタン
            _buildRecordButton(),
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

  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CameraPreview(_controller!);
  }

  Widget _buildRecordButton() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: GestureDetector(
        onTap: _isRecording ? null : _startRecording,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRecording ? Colors.red.shade700 : Colors.red,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Text(
              _isRecording ? '...' : 'REC',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}