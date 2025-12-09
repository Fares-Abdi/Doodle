import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:doodle/screens/pages/scribble_lobby_screen.dart';
import 'services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();

  // Initialize WebSocket service
  WebSocketService();

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

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

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
        AppLocalizationsDelegate(),
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
