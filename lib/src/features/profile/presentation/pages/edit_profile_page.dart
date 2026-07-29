import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:eventa/src/features/home/presentation/pages/home_page.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:eventa/src/features/profile/domain/profile_interest_catalog.dart';
import 'package:eventa/src/features/profile/presentation/pages/places_quiz_page.dart';
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
  final _photoUrlController = TextEditingController();
  final Set<String> _selectedInterests = {};
  bool _readyForMeeting = true;
  bool _saving = false;
  String? _gender;
  String? _lookingFor;
  DateTime? _birthDate;
  String? _zodiacSign;
  Map<String, String> _quizAnswers = {};
  final List<String> _photoUrls = [];
  int _mainPhotoIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(now.year - 80, 1, 1),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (date == null) return;
    final zodiac = calculateZodiacSign(date);
    setState(() {
      _birthDate = date;
      _zodiacSign = zodiac;
    });
  }

  void _addPhotoUrl() {
    final url = _photoUrlController.text.trim();
    if (url.isEmpty || _photoUrls.length >= 10) return;
    setState(() {
      _photoUrls.add(url);
      _photoUrlController.clear();
      if (_photoUrls.length == 1) _mainPhotoIndex = 0;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один интерес')),
      );
      return;
    }
    if (_birthDate == null || calculateAge(_birthDate!) < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для доступа к дейтингу нужен возраст 18+')),
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
        gender: _gender,
        birthDate: _birthDate,
        lookingFor: _lookingFor,
        zodiacSign: _zodiacSign,
        placesQuizAnswers: _quizAnswers,
        profilePhotoUrls: List.of(_photoUrls),
        mainPhotoIndex: _mainPhotoIndex,
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Пол'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Мужской')),
                          DropdownMenuItem(value: 'female', child: Text('Женский')),
                          DropdownMenuItem(value: 'other', child: Text('Другой')),
                        ],
                        onChanged: (value) => setState(() => _gender = value),
                        validator:
                            (value) => value == null ? 'Выберите пол' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Дата рождения'),
                        subtitle: Text(
                          _birthDate == null
                              ? 'Выберите дату (18+)'
                              : '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year} · ${zodiacRuLabel(_zodiacSign)}',
                        ),
                        trailing: const Icon(Icons.calendar_month_outlined),
                        onTap: _pickBirthDate,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _lookingFor,
                        decoration: const InputDecoration(labelText: 'Кого ищу'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Мужчины')),
                          DropdownMenuItem(value: 'female', child: Text('Женщины')),
                          DropdownMenuItem(value: 'any', child: Text('Любой')),
                        ],
                        onChanged: (value) => setState(() => _lookingFor = value),
                        validator:
                            (value) => value == null ? 'Выберите предпочтение' : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Фото профиля (до 10)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _photoUrlController,
                              decoration: const InputDecoration(
                                hintText: 'Вставьте URL фото',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _photoUrls.length >= 10 ? null : _addPhotoUrl,
                            icon: const Icon(Icons.add_a_photo_outlined),
                          ),
                        ],
                      ),
                      if (_photoUrls.isNotEmpty)
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photoUrls.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final isMain = _mainPhotoIndex == index;
                              return GestureDetector(
                                onTap: () => setState(() => _mainPhotoIndex = index),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _photoUrls[index],
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              width: 84,
                                              height: 84,
                                              color: Colors.grey.shade300,
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.image_not_supported),
                                            ),
                                      ),
                                    ),
                                    if (isMain)
                                      const Positioned(
                                        right: 4,
                                        top: 4,
                                        child: Icon(Icons.star, color: Colors.amber),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.quiz_outlined),
                        title: const Text('Квиз по местам'),
                        subtitle: Text(
                          _quizAnswers.isEmpty
                              ? 'Не заполнен (нужен для дейтинга)'
                              : 'Заполнено: ${_quizAnswers.length} ответов',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final updated = await Navigator.of(context).push<UserProfile>(
                            MaterialPageRoute(builder: (_) => const PlacesQuizPage()),
                          );
                          if (updated == null || !mounted) return;
                          setState(() => _quizAnswers = updated.placesQuizAnswers);
                        },
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
