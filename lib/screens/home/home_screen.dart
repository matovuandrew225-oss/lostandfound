import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/item.dart';
import '../../services/api_client.dart';
import '../../services/item_repository.dart';
import '../../widgets/item_card.dart';
import '../profile/profile_screen.dart';
import '../reports/report_form_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = ItemRepository(ApiClient.instance);
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchRecent();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Listings could not be loaded right now.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openReport(ItemType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(type: type),
      ),
    ).then((_) => _loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeContent(
        items: _items,
        loading: _loading,
        error: _error,
        onRefresh: _loadItems,
        onReport: _openReport,
        onSearch: () => setState(() => _selectedIndex = 1),
      ),
      SearchScreen(repository: _repository),
      const _ReportsPlaceholder(),
      const _NotificationsPlaceholder(),
      const ProfileScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'LOST & FOUND',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => setState(() => _selectedIndex = 3),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _selectedIndex = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _selectedIndex = value),
                  destinations: _destinations,
                ),
        );
      },
    );
  }
}

const _destinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.search),
    label: 'Search',
  ),
  NavigationDestination(
    icon: Icon(Icons.assignment_outlined),
    selectedIcon: Icon(Icons.assignment),
    label: 'Reports',
  ),
  NavigationDestination(
    icon: Icon(Icons.notifications_none),
    selectedIcon: Icon(Icons.notifications),
    label: 'Alerts',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: 'Profile',
  ),
];

const _railDestinations = [
  NavigationRailDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: Text('Home'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.search),
    label: Text('Search'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.assignment_outlined),
    selectedIcon: Icon(Icons.assignment),
    label: Text('Reports'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.notifications_none),
    selectedIcon: Icon(Icons.notifications),
    label: Text('Alerts'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: Text('Profile'),
  ),
];

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onReport,
    required this.onSearch,
  });

  final List<Item> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(ItemType) onReport;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.instance.currentUser;
    final name = user?.fullName ?? 'there';
    final lost = items.where((item) => item.isLost).toList();
    final found = items.where((item) => !item.isLost).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Text(
                    'Good day, $name.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Let’s help your campus community reconnect.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: onSearch,
                    borderRadius: BorderRadius.circular(10),
                    child: IgnorePointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search items, locations, or reference numbers',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: onSearch,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          label: 'Report lost item',
                          detail: 'Tell the community what you need back.',
                          icon: Icons.search_rounded,
                          color: AppTheme.navy,
                          onTap: () => onReport(ItemType.lost),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          label: 'Report found item',
                          detail: 'Help an owner find what they lost.',
                          icon: Icons.volunteer_activism_outlined,
                          color: AppTheme.burgundy,
                          onTap: () => onReport(ItemType.found),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (error != null)
                    _StateMessage(
                      icon: Icons.cloud_off_outlined,
                      title: error!,
                      action: TextButton(
                        onPressed: onRefresh,
                        child: const Text('Try again'),
                      ),
                    )
                  else if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (items.isEmpty)
                    const _StateMessage(
                      icon: Icons.inventory_2_outlined,
                      title: 'No active listings yet',
                      subtitle: 'Be the first person to report a lost or found item.',
                    )
                  else ...[
                    _SectionHeader(title: 'Recent lost items', count: lost.length),
                    const SizedBox(height: 12),
                    if (lost.isEmpty)
                      const _CompactEmpty(text: 'No recent lost items')
                    else
                      ...lost.take(3).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ItemCard(item: item, onTap: () {}),
                            ),
                          ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Recent found items', count: found.length),
                    const SizedBox(height: 12),
                    if (found.isEmpty)
                      const _CompactEmpty(text: 'No recent found items')
                    else
                      ...found.take(3).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ItemCard(item: item, onTap: () {}),
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 27),
              const SizedBox(height: 20),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                maxLines: 2,
                style: const TextStyle(color: Color(0xFFD8E1EB), height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(color: AppTheme.muted)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('View all')),
      ],
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(text, style: const TextStyle(color: AppTheme.muted)),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
            ],
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

class _ReportsPlaceholder extends StatelessWidget {
  const _ReportsPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Your reports will appear here.'),
      );
}

class _NotificationsPlaceholder extends StatelessWidget {
  const _NotificationsPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('You’re all caught up.'),
      );
}
