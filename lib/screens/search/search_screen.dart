import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/item.dart';
import '../../services/item_repository.dart';
import '../../widgets/item_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.repository, super.key});
  final ItemRepository repository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  ItemType? _filter;
  List<Item> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.repository.fetchRecent(
        query: _query.text,
        type: _filter,
      );
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _error = 'Search is unavailable right now.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search listings',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        )),
                const SizedBox(height: 8),
                const Text(
                  'Search by title, description, brand, location, or reference number.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _query,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filter == null,
                      onSelected: (_) {
                        setState(() => _filter = null);
                        _search();
                      },
                    ),
                    FilterChip(
                      label: const Text('Lost'),
                      selected: _filter == ItemType.lost,
                      onSelected: (_) {
                        setState(() => _filter = ItemType.lost);
                        _search();
                      },
                    ),
                    FilterChip(
                      label: const Text('Found'),
                      selected: _filter == ItemType.found,
                      onSelected: (_) {
                        setState(() => _filter = ItemType.found);
                        _search();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  _SearchState(title: _error!)
                else if (_results.isEmpty)
                  const _SearchState(
                    title: 'No listings match your search.',
                    subtitle: 'Try a broader keyword or remove a filter.',
                  )
                else
                  ..._results.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ItemCard(item: item, onTap: () {}),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchState extends StatelessWidget {
  const _SearchState({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, color: AppTheme.muted, size: 32),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
