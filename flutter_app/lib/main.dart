import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url:       dotenv.env['SUPABASE_URL']!,
    anonKey:   dotenv.env['SUPABASE_ANON_KEY']!,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  runApp(const ProviderScope(child: AutoXApp()));
}

class AutoXApp extends ConsumerWidget {
  const AutoXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router     = ref.watch(appRouterProvider);
    final themeMode  = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title:            'AUTOX Marketplace',
      debugShowCheckedModeBanner: false,
      theme:            AppTheme.light(),
      darkTheme:        AppTheme.dark(),
      themeMode:        themeMode,
      routerConfig:     router,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: child!,
        );
      },
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context, Widget child, ScrollableDetails details) => child;
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
