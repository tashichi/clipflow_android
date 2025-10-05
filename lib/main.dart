import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'managers/project_manager.dart';
import 'models/project.dart';
import 'screens/project_list_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/player_screen.dart';

void main() {
  // 縦画面固定
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ClipFlowApp());
}

class ClipFlowApp extends StatelessWidget {
  const ClipFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipFlow',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const MainView(),
    );
  }
}

// iOS版のMainViewと同じ構造
class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  // iOS版の@StateObjectと同じ
  final ProjectManager _projectManager = ProjectManager();
  
  // iOS版の@Stateと同じ
  Project? _selectedProject;
  AppScreen _currentScreen = AppScreen.projects;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    await _projectManager.loadProjects();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // iOS版のfullScreenCoverと同じ画面遷移
    switch (_currentScreen) {
      case AppScreen.projects:
        return ProjectListScreen(
          projectManager: _projectManager,
          onProjectSelect: (project, screen) async {
            // プロジェクト選択時も最新データをリロード
            await _projectManager.loadProjects();
            final updatedProject = _projectManager.projects.firstWhere(
              (p) => p.id == project.id,
            );
            setState(() {
              _selectedProject = updatedProject;
              _currentScreen = screen;
            });
          },
        );
      case AppScreen.camera:
        return CameraScreen(
          project: _selectedProject!,
          onBack: () async {
            // カメラ画面から戻る時に最新データをリロード
            await _projectManager.loadProjects();
            // 最新のプロジェクトを取得
            final updatedProject = _projectManager.projects.firstWhere(
              (p) => p.id == _selectedProject!.id,
            );
            setState(() {
              _selectedProject = updatedProject;
              _currentScreen = AppScreen.projects;
            });
          },
        );
      case AppScreen.player:
        return PlayerScreen(
          project: _selectedProject!,
          onBack: () async {
            // プレイヤー画面から戻る時に最新データをリロード
            await _projectManager.loadProjects();
            final updatedProject = _projectManager.projects.firstWhere(
              (p) => p.id == _selectedProject!.id,
            );
            setState(() {
              _selectedProject = updatedProject;
              _currentScreen = AppScreen.projects;
            });
          },
        );
    }
  }
}

// iOS版のenum AppScreenと同じ
enum AppScreen {
  projects,
  camera,
  player,
}