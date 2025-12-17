import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:doodle/screens/pages/scribble_lobby_screen.dart';
import 'services/websocket_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebSocket service
  WebSocketService();

  // Initialize Audio service
  final audioService = AudioService();
  await audioService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final initialRoute = await _determineInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _determineInitialRoute() async {
  // Always go directly to lobby - no login required
  return '/lobby';
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({
    Key? key,
    required this.initialRoute,
  }) : super(key: key);

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale _locale = const Locale('en', '');
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App is paused (going to background)
        _audioService.pauseMusic();
        break;
      case AppLifecycleState.resumed:
        // App is resumed (coming to foreground)
        // Don't resume here - let individual screens handle resuming their appropriate music
        // This prevents the lobby from overriding game music
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated
        _audioService.stopAll();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        _audioService.pauseMusic();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (not currently in focus)
        break;
    }
  }

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doodle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Poppins',
            ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
    
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ar', ''), // Arabic
        Locale('fr', ''), // French
      ],
      locale: _locale,
      initialRoute: widget.initialRoute, // Use dynamic initial route
      routes: _buildRoutes(),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/lobby': (context) => ScribbleLobbyScreen(),
    };
  }
}
