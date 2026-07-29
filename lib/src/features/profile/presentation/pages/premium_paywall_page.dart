import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/premium_limits.dart';
import 'package:flutter/material.dart';

/// Экран покупки Premium (MVP: имитация оплаты без StoreKit/Billing).
class PremiumPaywallPage extends StatefulWidget {
  const PremiumPaywallPage({super.key, this.reason});

  final String? reason;

  @override
  State<PremiumPaywallPage> createState() => _PremiumPaywallPageState();
}

class _PremiumPaywallPageState extends State<PremiumPaywallPage> {
  bool _paying = false;

  Future<void> _buy() async {
    setState(() => _paying = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
      final persistence = ProfilePersistence();
      final me = await persistence.read(uid);
      if (me == null) throw StateError('no_profile');
      final updated = me.copyWith(
        isPremium: true,
        premiumUntil: DateTime.now().add(const Duration(days: 30)),
      );
      await persistence.save(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium активирован на 30 дней')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось оформить Premium')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = PremiumLimits.premiumPriceTenge;
    return Scaffold(
      appBar: AppBar(title: const Text('Eventa Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.reason != null) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(widget.reason!),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Больше свободы в Eventa',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const _Benefit(text: 'Безлимитные приглашения в чат'),
          const _Benefit(text: 'Безлимитное создание групп и встреч'),
          const _Benefit(text: 'Полный просмотр чужих профилей без размытия'),
          const _Benefit(text: 'Бейдж Premium в анкете'),
          const SizedBox(height: 8),
          Text(
            'Бесплатно: до ${PremiumLimits.freeInvitesPerWeek} приглашений '
            'и до ${PremiumLimits.freeCreatesPerWeek} своих групп в неделю.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '$price ₸ / месяц',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Отмена в любой момент (MVP-оплата демо)'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _paying ? null : _buy,
                      child:
                          _paying
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Оплатить Premium'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

Future<bool> openPremiumPaywall(BuildContext context, {String? reason}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => PremiumPaywallPage(reason: reason)),
  );
  return result == true;
}
