import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/video_composer_service.dart';

class ProjectManager {
  static const String _projectsKey = 'projects';
  List<Project> projects = [];

  // プロジェクト読み込み
  Future<void> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? projectsJson = prefs.getString(_projectsKey);
    
    if (projectsJson != null) {
      final List<dynamic> decoded = json.decode(projectsJson);
      projects = decoded.map((p) => Project.fromJson(p)).toList();
    }
  }

  // プロジェクト保存
  Future<void> saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_projectsKey, encoded);
  }

  // 新規プロジェクト作成
  Future<Project> createProject(String name) async {
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      segments: [],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    projects.add(project);
    await saveProjects();
    return project;
  }

  // プロジェクト削除
  Future<void> deleteProject(Project project) async {
    projects.remove(project);
    await saveProjects();
  }

  // プロジェクト名変更
  Future<void> renameProject(Project project, String newName) async {
    project.name = newName;
    project.lastModified = DateTime.now();
    await saveProjects();
  }
  // iOS版のcreateComposition関数と同じ：複数セグメントを1つに統合
  // ネイティブコード（Kotlin）で実装
  Future<String?> createComposition(Project project) async {
    if (project.segments.isEmpty) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${appDir.path}/composition_$timestamp.mp4';

      final List<String> inputPaths = project.segments.map((s) => s.uri).toList();

      print('=== Composition Debug ===');
      print('Segments count: ${inputPaths.length}');
      for (int i = 0; i < inputPaths.length; i++) {
        print('Segment $i: ${inputPaths[i]}');
        print('File exists: ${File(inputPaths[i]).existsSync()}');
      }
      print('Output path: $outputPath');
      
      final success = await VideoComposerService.composeVideos(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      print('Composition result: $success');

      if (success) {
        print('Composition created: $outputPath');
        return outputPath;
      } else {
        print('Composition failed');
        return null;
      }
    } catch (e) {
      print('createComposition error: $e');
      return null;
    }
  }
}
