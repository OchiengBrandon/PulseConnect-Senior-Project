import 'package:flutter/material.dart';

class PollDetailsScreen extends StatelessWidget {
  const PollDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poll Details')),
      body: const Center(child: Text('Poll Details Screen')),
    );
  }
}
