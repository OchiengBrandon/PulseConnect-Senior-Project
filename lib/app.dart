import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/routes.dart';
import 'core/config/themes.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/polls/screens/polls_screen.dart';

class PulseConnectApp extends StatelessWidget {
  const PulseConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseConnect',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      routes: AppRoutes.routes,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Return login screen if not authenticated, otherwise the polls screen
          return authProvider.isAuthenticated
              ? const PollsScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
