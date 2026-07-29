import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:eventa/src/features/home/presentation/pages/home_page.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:eventa/src/features/profile/domain/profile_interest_catalog.dart';
import 'package:eventa/src/features/profile/presentation/pages/phone_verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final Set<String> _selectedInterests = {};
  bool _readyForMeeting = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один интерес')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = getIt<AuthRepository>();
      final uid = await auth.currentUserId() ?? 'user-1';
      final profile = UserProfile(
        id: uid,
        createdAt: DateTime.now(),
        ownerId: uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        role: 'user',
        city: _cityController.text.trim(),
        interests: _selectedInterests.toList()..sort(),
        readyForMeeting: _readyForMeeting,
      );
      await auth.completeProfile(profile);
      if (!mounted) return;

      context.read<AuthBloc>().add(AuthCheckRequested());
      await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const PhoneVerifyPage()));
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить профиль. Попробуйте еще раз.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ваш профиль')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Расскажите о себе',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Имя, город и интересы нужны, чтобы подбирать встречи и компанию.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Имя'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Укажите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Город'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Укажите город';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(labelText: 'О себе'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Интересы (минимум 1)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            ProfileInterestCatalog.all.map((interest) {
                              final selected = _selectedInterests.contains(
                                interest,
                              );
                              return FilterChip(
                                label: Text(interest),
                                selected: selected,
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedInterests.add(interest);
                                    } else {
                                      _selectedInterests.remove(interest);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Готов к встречам'),
                        subtitle: const Text(
                          'Показывать вас в подборе компании к заведениям',
                        ),
                        value: _readyForMeeting,
                        onChanged:
                            (value) => setState(() => _readyForMeeting = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_saving)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Сохранить и продолжить'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
