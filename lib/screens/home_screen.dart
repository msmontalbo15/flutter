import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/store/app_state.dart';
import '/store/auth/auth_reducer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    // Guard: If the widget was disposed during the await, stop here.
    if (!context.mounted) return;

    StoreProvider.of<AppState>(context).dispatch(LogoutAction());

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text('You are logged in 🎉', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
