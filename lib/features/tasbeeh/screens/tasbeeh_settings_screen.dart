import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../state/tasbeeh_bloc.dart';

class TasbeehSettingsScreen extends StatelessWidget {
  const TasbeehSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(builder: (context, state) {
      final bloc = context.read<TasbeehBloc>();
      final settings = state.settings;

      return Scaffold(
        backgroundColor: TasbeehColors.background,
        appBar: AppBar(
          backgroundColor: TasbeehColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: TasbeehColors.steelBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: ShaderMask(
            shaderCallback: (b) =>
                TasbeehColors.primaryGradient.createShader(b),
            child: const Text(
              'Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: TasbeehColors.babyBlue),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SettingsSection(
              title: 'Feedback',
              children: [
                _SettingsTile(
                  icon: Icons.vibration_rounded,
                  title: 'Vibration',
                  subtitle: 'Vibrate on each count & milestone',
                  value: settings['vibrationEnabled'] ?? true,
                  onChanged: (v) => bloc.updateSetting('vibrationEnabled', v),
                ),
                _SettingsTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound',
                  subtitle: 'Play a click sound on each count',
                  value: settings['soundEnabled'] ?? false,
                  onChanged: (v) => bloc.updateSetting('soundEnabled', v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: 'Display',
              children: [
                _SettingsTile(
                  icon: Icons.translate_rounded,
                  title: 'Show Transliteration',
                  subtitle: 'Display romanized text below Arabic',
                  value: settings['showTransliteration'] ?? true,
                  onChanged: (v) =>
                      bloc.updateSetting('showTransliteration', v),
                ),
                _SettingsTile(
                  icon: Icons.subtitles_rounded,
                  title: 'Show Translation',
                  subtitle: 'Display English meaning',
                  value: settings['showTranslation'] ?? true,
                  onChanged: (v) => bloc.updateSetting('showTranslation', v),
                ),
                _SettingsTile(
                  icon: Icons.screen_lock_landscape_rounded,
                  title: 'Keep Screen On',
                  subtitle: 'Prevent screen from sleeping',
                  value: settings['keepScreenOn'] ?? true,
                  onChanged: (v) => bloc.updateSetting('keepScreenOn', v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: 'Behaviour',
              children: [
                _SettingsTile(
                  icon: Icons.refresh_rounded,
                  title: 'Auto Reset',
                  subtitle: 'Automatically reset after each round',
                  value: settings['autoReset'] ?? false,
                  onChanged: (v) => bloc.updateSetting('autoReset', v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: 'About',
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: TasbeehColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tasbeeh Counter',
                              style: TasbeehTextStyles.subheading.copyWith(
                                  color: TasbeehColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Version 1.0.0',
                              style: TasbeehTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TasbeehTextStyles.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: TasbeehColors.steelBlue,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: TasbeehColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TasbeehColors.babyBlue),
            boxShadow: [
              BoxShadow(
                color: TasbeehColors.standardBlue.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TasbeehColors.whisperBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TasbeehColors.babyBlue),
            ),
            child: Icon(icon, size: 20, color: TasbeehColors.steelBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TasbeehTextStyles.subheading.copyWith(
                  color: TasbeehColors.textPrimary,
                  fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: TasbeehTextStyles.caption),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: TasbeehColors.standardBlue,
            activeTrackColor: TasbeehColors.blueLight,
          ),
        ],
      ),
    );
  }
}