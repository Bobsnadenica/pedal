import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/login_page.dart';
import 'pages/front_page.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PedalApp());
}

class PedalApp extends StatelessWidget {
  const PedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionService()),
      ],
      child: MaterialApp(
        title: 'P.E.D.A.L.',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginPage(),
          '/front': (_) => const FrontPage(),
        },
      ),
    );
  }
}