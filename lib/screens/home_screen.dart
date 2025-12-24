import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home screen with navigation grid to all tools.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tools = [
      _Tool(
        title: 'Farben',
        description: 'Stroop effect trainer. Flashes colors and words.',
        route: '/farben',
        icon: Icons.palette,
      ),
      _Tool(
        title: 'Kettenrechner',
        description: 'Mental math chain calculator. Solve operations.',
        route: '/kettenrechner',
        icon: Icons.calculate,
      ),
      _Tool(
        title: 'Timers',
        description: 'Interval timers and loop presets for training.',
        route: '/timers',
        icon: Icons.timer,
      ),
      _Tool(
        title: 'Intervall',
        description: 'Set custom intervals for audio beep reminders.',
        route: '/intervall',
        icon: Icons.notifications_active,
      ),
      _Tool(
        title: 'Sound Counter',
        description: 'Count sounds using microphone threshold detection.',
        route: '/sound-counter',
        icon: Icons.mic,
      ),
      _Tool(
        title: 'Motion Counter',
        description: 'Count motion crossings using camera tripwire.',
        route: '/motion-counter',
        icon: Icons.videocam,
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.grid_view, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Training Erik',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid: 2-3 columns based on width
            final crossAxisCount = constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolCard(tool: tool);
              },
            );
          },
        ),
      ),
    );
  }
}

class _Tool {
  final String title;
  final String description;
  final String route;
  final IconData icon;

  const _Tool({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });
}

class _ToolCard extends StatelessWidget {
  final _Tool tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.go(tool.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tool.icon,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    tool.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  tool.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
