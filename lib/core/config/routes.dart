import 'package:flutter/material.dart';
import 'package:pulse_connect_app/features/polls/screens/create_poll_screen.dart';
import 'package:pulse_connect_app/features/polls/screens/polls_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/polls/screens/poll_details_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';

/// App-wide route definitions.
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String polls = '/polls';
  static const String createPoll = '/create-poll';
  static const String pollDetails = '/poll-details';

  /// Route map for the app.
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) => const EditProfileScreen(),
    polls: (context) => const PollsScreen(),
    createPoll: (context) => const CreatePollScreen(),
    pollDetails: (context) => const PollDetailsScreen(),
  };
}
