import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile editing form will be here.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // In a real app, you would save profile data here.
                final authBloc = context.read<AuthBloc>();
                await getIt<AuthRepository>().markProfileAsCreated();

                // Trigger a re-check of the auth state to navigate to HomePage
                authBloc.add(AuthCheckRequested());
              },
              child: const Text('Save and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
