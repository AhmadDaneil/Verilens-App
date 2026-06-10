// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../cubits/navigation/navigation_cubit.dart';
import '../cubits/navigation/navigation_state.dart';
import '../providers/settings_provider.dart';
import 'analyze_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _pages = [
    AnalyzeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().darkMode;

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navState) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.security, color: Color(0xFF1A73E8), size: 24),
                SizedBox(width: 8),
                Text(
                  'Verilens',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          body: _pages[navState.currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: navState.currentIndex,
            onDestinationSelected: (index) =>
                context.read<NavigationCubit>().changePage(index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.document_scanner_outlined),
                selectedIcon: Icon(Icons.document_scanner),
                label: 'Analyze',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}