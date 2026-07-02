import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mandor_screens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0; // 0 = threads, 1 = tasks, 2 = projects
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;

        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout(isTablet, _sidebarCollapsed);
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _buildContent(_selectedTab),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Threads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Projects',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isTablet, bool isCollapsed) {
    final drawerWidth = isCollapsed ? 80.0 : 256.0;
    final tabletDrawerWidth = isCollapsed ? 80.0 : 200.0;
    final finalDrawerWidth = isTablet ? tabletDrawerWidth : drawerWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mandor'),
        elevation: 2,
        leading: IconButton(
          icon: Icon(isCollapsed ? Icons.menu : Icons.menu_open),
          onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                height: 48,
                width: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) => setState(() => _selectedTab = index),
            extended: !isCollapsed,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.forum),
                label: Text('Threads'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_open),
                label: Text('Projects'),
              ),
            ],
          ),
          Expanded(
            child: _buildContent(_selectedTab),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return const ThreadsListScreen();
      case 1:
        return const TasksListScreen();
      case 2:
        return const ProjectsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
