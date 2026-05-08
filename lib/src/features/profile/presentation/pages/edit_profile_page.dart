import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:eventa/src/features/home/presentation/pages/home_page.dart';
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
                try {
                  // In a real app, you would save profile data here.
                  final authBloc = context.read<AuthBloc>();
                  await getIt<AuthRepository>().markProfileAsCreated();
                  if (!context.mounted) return;

                  // Keep auth state in sync before navigation.
                  authBloc.add(AuthCheckRequested());

                  // Move forward immediately after profile creation.
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Не удалось сохранить профиль. Попробуйте еще раз.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
