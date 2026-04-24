// lib/screens/delete_account_sheet.dart
//
// Bottom-sheet flow for "Delete Account & Data".
// Three stages: warning → confirmation (typed word) → progress + result.
// Navigates back to /disclaimer (re-onboarding) when finished so the app
// restarts cleanly from the very first gate.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/account_delete_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/disclaimer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/strava_provider.dart';
import '../services/account_delete_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/pace_button.dart';

enum _Stage { warn, confirm, running, done }

Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  _Stage _stage = _Stage.warn;
  final _confirmController = TextEditingController();
  String _progressStep = '';
  AccountDeleteResult? _result;

  // Word the user must type to confirm. Kept short and ASCII to avoid IME
  // friction on iOS.
  static const _confirmWord = 'DELETE';

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: AnimatedSize(
            duration: PaceDurations.normal,
            curve: Curves.easeOutCubic,
            child: switch (_stage) {
              _Stage.warn => _buildWarn(),
              _Stage.confirm => _buildConfirm(),
              _Stage.running => _buildRunning(),
              _Stage.done => _buildDone(),
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Stage 1: warning
  // -------------------------------------------------------------------
  Widget _buildWarn() {
    return Column(
      key: const ValueKey('warn'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF6B6B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete account & data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: PaceColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'This will permanently remove:',
          style: TextStyle(
            fontSize: 14,
            color: PaceColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _bullet('Your OpenRouter API key (from device Keychain)'),
        _bullet('Your Strava connection (deauthorized on Strava servers)'),
        _bullet('All training plans, sessions, and chat history'),
        _bullet('Your profile, goal, and app preferences'),
        const SizedBox(height: 16),
        const Text(
          'Calendar events already written to your iOS calendar are not automatically removed — you can delete them from the Calendar app if you wish.',
          style: TextStyle(
            fontSize: 12,
            color: PaceColors.textTertiary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _GhostButton(
                label: 'Cancel',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PaceButton(
                label: 'Continue',
                color: const Color(0xFFFF6B6B),
                glowColor: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                onPressed: () => setState(() => _stage = _Stage.confirm),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Stage 2: typed confirmation
  // -------------------------------------------------------------------
  Widget _buildConfirm() {
    final typed = _confirmController.text.trim().toUpperCase();
    final canProceed = typed == _confirmWord;

    return Column(
      key: const ValueKey('confirm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Confirm deletion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PaceColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Type DELETE to confirm. This cannot be undone.',
          style: TextStyle(
            fontSize: 13,
            color: PaceColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: PaceColors.textPrimary,
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: _confirmWord,
            hintStyle: const TextStyle(
              color: PaceColors.textMuted,
              letterSpacing: 2,
            ),
            filled: true,
            fillColor: const Color.fromRGBO(255, 255, 255, 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PaceRadii.button),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _GhostButton(
                label: 'Back',
                onTap: () => setState(() => _stage = _Stage.warn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PaceButton(
                label: 'Delete',
                color: const Color(0xFFFF6B6B),
                glowColor: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                enabled: canProceed,
                onPressed: canProceed ? _runDelete : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Stage 3: running
  // -------------------------------------------------------------------
  Widget _buildRunning() {
    return Column(
      key: const ValueKey('running'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Deleting your data…',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: PaceColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: PaceDurations.fast,
          child: Text(
            _progressStep,
            key: ValueKey(_progressStep),
            style: const TextStyle(
              fontSize: 13,
              color: PaceColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Stage 4: done
  // -------------------------------------------------------------------
  Widget _buildDone() {
    final result = _result;
    final success = result?.success ?? false;

    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (success
                      ? AccentPreset.volt.primary
                      : const Color(0xFFFFB020))
                  .withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Icon(
              success
                  ? Icons.check_rounded
                  : Icons.info_outline_rounded,
              size: 28,
              color: success
                  ? AccentPreset.volt.primary
                  : const Color(0xFFFFB020),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          success ? 'All data deleted' : 'Deleted with warnings',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PaceColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          success
              ? 'Your account and all local data have been removed from this device.'
              : 'Local data was removed, but some steps reported issues:\n\n${(result?.failures ?? []).join('\n')}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: PaceColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        PaceButton(
          label: 'Done',
          onPressed: () {
            Navigator.of(context).pop();
            // Send the user back to the very first gate so the app restarts
            // in a known-clean state (disclaimer → welcome → auth).
            context.go('/disclaimer');
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // The actual delete call
  // -------------------------------------------------------------------
  Future<void> _runDelete() async {
    setState(() {
      _stage = _Stage.running;
      _progressStep = 'Starting…';
    });

    final service = ref.read(accountDeleteServiceProvider);

    final result = await service.deleteEverything(
      onProgress: (step) {
        if (!mounted) return;
        setState(() => _progressStep = step);
      },
    );

    // Reset in-memory state for the providers we don't rebuild automatically.
    try {
      await ref.read(authProvider.notifier).clearKey();
    } catch (_) {}
    try {
      await ref.read(stravaProvider.notifier).disconnect();
    } catch (_) {}
    try {
      await ref.read(settingsProvider.notifier).resetSetup();
    } catch (_) {}
    try {
      await ref.read(disclaimerProvider.notifier).reset();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _result = result;
      _stage = _Stage.done;
    });
  }

  // -------------------------------------------------------------------
  // Tiny shared UI bits
  // -------------------------------------------------------------------
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(
              Icons.circle,
              size: 5,
              color: PaceColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: PaceColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PaceRadii.button),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.12),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: PaceColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
