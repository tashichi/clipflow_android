import 'package:flutter/material.dart';
import '../managers/project_manager.dart';
import '../models/project.dart';
import '../main.dart';

class ProjectListScreen extends StatefulWidget {
  final ProjectManager projectManager;
  final Function(Project, AppScreen) onProjectSelect;

  const ProjectListScreen({
    super.key,
    required this.projectManager,
    required this.onProjectSelect,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  Future<void> _createNewProject() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('New Project', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Project name',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final project = await widget.projectManager.createProject(result);
      setState(() {});
      // iOS版と同じ：作成後すぐにカメラ画面へ
      widget.onProjectSelect(project, AppScreen.camera);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（iOS版と同じ）
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              child: const Text(
                'ClipFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Free Version表示（iOS版と同じ）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Free Version',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // プロジェクトリスト
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (widget.projectManager.projects.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      const Text(
                        'Your Projects',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.projectManager.projects.map((project) {
                        return _buildProjectCard(project);
                      }).toList(),
                    ],
                    const SizedBox(height: 30),
                    _buildActionButtons(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プロジェクト情報
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.segments.length} segments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      'Created: ${_formatDate(project.createdAt)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ボタン（iOS版と同じ配置）
          Row(
            children: [
              // Rec ボタン
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onProjectSelect(project, AppScreen.camera);
                  },
                  icon: const Icon(Icons.camera, size: 16),
                  label: const Text('Rec'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Play ボタン
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: project.segments.isEmpty
                      ? null
                      : () {
                          widget.onProjectSelect(project, AppScreen.player);
                        },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                    minimumSize: const Size(0, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Export ボタン
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: project.segments.isEmpty
                      ? null
                      : () {
                          // TODO: Export機能
                        },
                  icon: const Icon(Icons.upload, size: 14),
                  label: const Text(
                    'Export',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _createNewProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_circle),
              SizedBox(width: 8),
              Text(
                'New Project',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (widget.projectManager.projects.isEmpty) ...[
          const SizedBox(height: 40),
          Icon(
            Icons.video_library,
            size: 60,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 12),
          const Text(
            'No Projects Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create your first project to start recording 1-second memories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }
}