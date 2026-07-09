import 'package:flutter/material.dart';
import '../models/models.dart';

class ProjectInfoScreen extends StatelessWidget {
  final Project project;

  const ProjectInfoScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.name ?? 'Project Info'), elevation: 2),
      body: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repository', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            SelectableText(
              project.repoUrl ?? 'No URL configured',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text('Local Path', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            SelectableText(
              project.localPath ?? 'No path configured',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
