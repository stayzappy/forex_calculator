import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../screens/main_screen.dart';
import '../services/calculator_provider_service.dart';
import '../services/theme_provider_service.dart';
import '../models/firebase_remote_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: 'AIzaSyCfIYtvo8fX2szHC9IlfmSuHk0tCtUytPs',
        appId: '1:1023012900652:android:327d5752e12f3a4900a689',
        messagingSenderId: '1023012900652',
        projectId: 'forexcalculator-fc8a4'),
        name: 'forex_calculator',
  );
  await RemoteConfigService.instance.initialize();
  runApp(const ForexCalculatorApp());
}

class ForexCalculatorApp extends StatefulWidget {
  const ForexCalculatorApp({Key? key}) : super(key: key);

  @override
  _ForexCalculatorAppState createState() => _ForexCalculatorAppState();
}

class _ForexCalculatorAppState extends State<ForexCalculatorApp> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.loadSavedTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider(create: (_) => ForexServiceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Forex Calculator',
            theme: themeProvider.getThemeData(),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
