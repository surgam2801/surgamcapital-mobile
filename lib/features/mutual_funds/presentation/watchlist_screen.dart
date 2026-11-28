import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/mutual_fund_providers.dart';
import '../domain/mutual_fund_scheme.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  late Future<List<MutualFundScheme>> _watchlist;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _watchlist = ref.read(mutualFundRepositoryProvider).watchlist();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My watchlist')),
    body: AppAdaptiveBody(
      selectedIndex: -1,
      child: FutureBuilder<List<MutualFundScheme>>(
        future: _watchlist,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is AppException
                ? (snapshot.error! as AppException).message
                : 'Unable to load your watchlist.';
            return _state(
              message,
              action: 'Retry',
              onPressed: () => setState(_reload),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return _state(
              'Your watchlist is empty. Save schemes to keep them handy for research.',
              action: 'Explore schemes',
              onPressed: () => context.go(AppRoutes.schemeDiscovery),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (items.any((scheme) => scheme.mockData))
                const Card(
                  color: Color(0xFFFFF4DF),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'DEMO DATA ONLY — synthetic test data; not actual schemes or market performance.',
                    ),
                  ),
                ),
              for (final scheme in items)
                Card(
                  child: ListTile(
                    title: Text(scheme.schemeName),
                    subtitle: Text(
                      '${scheme.amcName} · ${scheme.category} · NAV ${scheme.latestNav?.toStringAsFixed(4) ?? 'N/A'}',
                    ),
                    onTap: () =>
                        context.push('${AppRoutes.schemeDetail}/${scheme.id}'),
                    trailing: IconButton(
                      tooltip: 'Remove from watchlist',
                      icon: const Icon(Icons.bookmark_remove_outlined),
                      onPressed: () async {
                        try {
                          await ref
                              .read(mutualFundRepositoryProvider)
                              .removeFromWatchlist(scheme.id);
                          if (context.mounted) setState(_reload);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Widget _state(String message, {String? action, VoidCallback? onPressed}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 12),
                FilledButton(onPressed: onPressed, child: Text(action)),
              ],
            ],
          ),
        ),
      );
}
