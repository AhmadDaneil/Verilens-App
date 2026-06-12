// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubits/history/history_cubit.dart';
import '../cubits/history/history_state.dart';
import '../cubits/navigation/navigation_cubit.dart';
import '../cubits/navigation/navigation_state.dart';
import '../models/scan_result.dart';
import '../utils/app_colors.dart';
import 'result_screen.dart';
import 'package:scamshield_app/utils/history_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().loadHistory();
  }

  Future<void> _refresh() =>
      context.read<HistoryCubit>().loadHistory();

  @override
  Widget build(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color  ?? AppColors.textPrimary;
    final textSecond  = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan History',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textPrimary)),
                      Text('Your previous analyses',
                          style: TextStyle(fontSize: 14, color: textSecond)),
                    ],
                  ),
                  BlocBuilder<HistoryCubit, HistoryState>(
                    builder: (context, state) {
                      if (state is HistoryLoaded) {
                        return IconButton(
                          onPressed: () => _confirmClear(context),
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: AppColors.fake),
                          tooltip: 'Clear History',
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              // ── Content ─────────────────────────────────────────────
              Expanded(
                // BlocListener watches NavigationCubit — whenever the
                // user taps the History tab (index 1) we reload.
                child: BlocListener<NavigationCubit, NavigationState>(
                  listenWhen: (prev, curr) =>
                      curr.currentIndex == 1 && prev.currentIndex != 1,
                  listener: (context, _) =>
                      context.read<HistoryCubit>().loadHistory(),
                  child: BlocBuilder<HistoryCubit, HistoryState>(
                    builder: (context, state) {
                      if (state is HistoryLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        );
                      }
                      if (state is HistoryEmpty) {
                        return _buildEmptyState(context);
                      }
                      if (state is HistoryError) {
                        return _buildErrorState(context, state.message);
                      }
                      if (state is HistoryLoaded) {
                        return _buildHistoryList(context, state.results);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textSecond =
        Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    // Still wrap in RefreshIndicator so pull-to-refresh works on empty state
    return RefreshIndicator(
      key: _refreshKey,
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_outlined,
                    size: 80, color: Theme.of(context).dividerColor),
                const SizedBox(height: 16),
                Text('No scan history yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textSecond)),
                const SizedBox(height: 8),
                Text('Your analyzed texts will appear here',
                    style: TextStyle(fontSize: 14, color: textSecond)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward,
                        size: 14, color: textSecond),
                    const SizedBox(width: 4),
                    Text('Pull down to refresh',
                        style: TextStyle(fontSize: 12, color: textSecond)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final textSecond =
        Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecond;
    return RefreshIndicator(
      key: _refreshKey,
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 60, color: AppColors.fake),
                const SizedBox(height: 16),
                Text(message,
                    style: TextStyle(fontSize: 14, color: textSecond)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<ScanResult> results) {
    return RefreshIndicator(
      key: _refreshKey,
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView.separated(
        // Always scrollable so pull-to-refresh triggers even on short lists
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = results[index];
          return HistoryTile(
            result: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ResultScreen(result: item)),
            ),
            onDelete: () =>
                context.read<HistoryCubit>().deleteScan(item.id),
          ).animate().fadeIn(
                delay: Duration(milliseconds: index * 80));
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all scan history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<HistoryCubit>().clearHistory();
            },
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.fake)),
          ),
        ],
      ),
    );
  }
}