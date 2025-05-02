import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulse_connect_app/features/auth/providers/auth_provider.dart';
import 'package:pulse_connect_app/features/polls/providers/poll_provider.dart';
import 'package:pulse_connect_app/core/services/poll_service.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  await FirebaseService.initialize();

  // Create PollService instance
  final pollService = PollService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PollProvider(pollService)),
      ],
      child: const PulseConnectApp(),
    ),
  );
}
