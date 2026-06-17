import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'cubits/scan/scan_cubit.dart';
import 'cubits/history/history_cubit.dart';
import 'cubits/navigation/navigation_cubit.dart';
import 'services/model_service.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final modelService    = ModelService();
  final databaseService = DatabaseService();
  final settings        = SettingsProvider();

  await databaseService.init();
  await settings.load();          // load saved dark mode + font scale

  if (!modelService.isLoaded) {
    await modelService.loadModel();
  }

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: ScamShieldApp(
        modelService: modelService,
        databaseService: databaseService,
      ),
    ),
  );
}

class ScamShieldApp extends StatelessWidget {
  final ModelService modelService;
  final DatabaseService databaseService;

  const ScamShieldApp({
    super.key,
    required this.modelService,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(
          create: (_) => ScanCubit(
            modelService: modelService,
            databaseService: databaseService,
          ),
        ),
        BlocProvider(
          create: (_) => HistoryCubit(databaseService: databaseService),
        ),
      ],
      child: MaterialApp(
        title: 'ScamShield',
        debugShowCheckedModeBanner: false,
        theme:      AppTheme.lightTheme,
        darkTheme:  AppTheme.darkTheme,
        themeMode:  settings.themeMode,       // driven by SettingsProvider
        // Font scale wraps the whole app via MediaQuery
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child!,
        ),
        home: SplashScreen(modelService: modelService),
      ),
    );
  }
}