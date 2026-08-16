import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/gender_onboarding_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GenderOnboardingPage extends StatelessWidget {
  const GenderOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GenderOnboardingProvider(
        userProvider: context.read<UserProvider>(),
        authProvider: context.read<AuthProvider>(),
      ),
      child: const _GenderOnboardingView(),
    );
  }
}

class _GenderOnboardingView extends StatelessWidget {
  const _GenderOnboardingView();

  @override
  Widget build(BuildContext context) {
    return Consumer<GenderOnboardingProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Config.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Lengkapi Profil'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Config.primary,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pilih jenis kelamin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: Config.bold,
                            color: Config.textHead,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Data ini diperlukan untuk melengkapi profil Anda dan tidak dapat diubah setelah disimpan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.45,
                            color: Config.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAccountInfo(context),
                        const SizedBox(height: 24),
                        _GenderOption(
                          gender: PersonGender.male,
                          selected: provider.gender == PersonGender.male,
                          onTap: () => provider.selectGender(PersonGender.male),
                        ),
                        const SizedBox(height: 12),
                        _GenderOption(
                          gender: PersonGender.female,
                          selected: provider.gender == PersonGender.female,
                          onTap: () =>
                              provider.selectGender(PersonGender.female),
                        ),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: provider.canSubmit
                              ? () async {
                                  final saved = await provider.submit();
                                  if (saved && context.mounted) {
                                    context.goNamed('home');
                                  }
                                }
                              : null,
                          child: provider.isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan dan Lanjutkan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountInfo(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Config.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Config.secondarySoft,
            child: Icon(Icons.account_circle_outlined, color: Config.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akun yang sedang digunakan',
                  style: TextStyle(fontSize: 12, color: Config.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.fullName?.trim().isNotEmpty == true
                      ? user!.fullName!
                      : 'Nama belum tersedia',
                  style: const TextStyle(
                    fontWeight: Config.semiBold,
                    color: Config.textHead,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIT: ${user?.nit?.trim().isNotEmpty == true ? user!.nit : '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Config.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  final PersonGender gender;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Config.secondarySoft : Config.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Config.primary : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              gender == PersonGender.male
                  ? Icons.male_outlined
                  : Icons.female_outlined,
              color: selected ? Config.primary : Config.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(gender.label)),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? Config.primary : Config.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
