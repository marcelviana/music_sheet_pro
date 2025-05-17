import 'package:flutter/material.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Em breve!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'O gerenciamento de setlists estará disponível em breve.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}