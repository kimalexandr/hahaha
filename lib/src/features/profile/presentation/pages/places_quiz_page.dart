import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:flutter/material.dart';

class PlacesQuizPage extends StatefulWidget {
  const PlacesQuizPage({super.key});

  @override
  State<PlacesQuizPage> createState() => _PlacesQuizPageState();
}

class _PlacesQuizPageState extends State<PlacesQuizPage> {
  final Map<String, Set<String>> _answers = {};
  int _step = 0;
  bool _saving = false;

  Map<String, Object> get _question => placesQuizQuestions[_step];
  List<String> get _options => List<String>.from(_question['options'] as List);
  String get _questionId => _question['id'] as String;
  String get _questionText => _question['text'] as String;
  bool get _isLast => _step == placesQuizQuestions.length - 1;
  Set<String> get _selected => _answers.putIfAbsent(_questionId, () => <String>{});

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final me = await ProfilePersistence().read(uid);
    if (me == null || !mounted) return;
    setState(() {
      for (final entry in me.placesQuizAnswers.entries) {
        _answers[entry.key] = entry.value.toSet();
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
      final persistence = ProfilePersistence();
      final existing = await persistence.read(uid);
      if (existing == null) throw StateError('profile_not_found');
      final serialized = <String, List<String>>{
        for (final e in _answers.entries)
          if (e.value.isNotEmpty) e.key: e.value.toList()..sort(),
      };
      final updated = existing.copyWith(placesQuizAnswers: serialized);
      await persistence.save(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить ответы квиза')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(String option, bool selected) {
    setState(() {
      final set = _selected;
      if (selected) {
        set.add(option);
      } else {
        set.remove(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final progress = (_step + 1) / placesQuizQuestions.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Квиз по местам')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Text(
              'Вопрос ${_step + 1} из ${placesQuizQuestions.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Можно выбрать несколько вариантов',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _questionText,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final option = _options[index];
                  final isOn = selected.contains(option);
                  return CheckboxListTile(
                    value: isOn,
                    title: Text(option),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _toggle(option, value == true),
                  );
                },
              ),
            ),
            if (selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Выбрано: ${selected.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step -= 1),
                      child: const Text('Назад'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        selected.isEmpty || _saving
                            ? null
                            : () {
                              if (_isLast) {
                                _finish();
                              } else {
                                setState(() => _step += 1);
                              }
                            },
                    child:
                        _saving
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(_isLast ? 'Завершить' : 'Далее'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
