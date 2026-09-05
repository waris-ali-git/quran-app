import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/language_cubit.dart';
import '../services/supported_languages.dart';
import 'translated_text.dart';
import '../../shared/widgets/custom_button.dart';

class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key});

  void _showFloatingLanguageCard(BuildContext context, String currentLangCode) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Language Selector',
      barrierColor: Colors.black.withValues(alpha: 0.05),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 60, right: 16),
            child: Material(
              color: Colors.transparent,
              child: _LanguageGlassPopup(currentLangCode: currentLangCode),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, String>(
      builder: (context, currentLang) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _showFloatingLanguageCard(context, currentLang),
            child: const LiquidGlassContainer(
              width: 48,
              height: 48,
              borderRadius: 14,
              child: Icon(Icons.language, color: Color(0xFF1C1C1E)),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageGlassPopup extends StatefulWidget {
  final String currentLangCode;

  const _LanguageGlassPopup({required this.currentLangCode});

  @override
  State<_LanguageGlassPopup> createState() => _LanguageGlassPopupState();
}

class _LanguageGlassPopupState extends State<_LanguageGlassPopup> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = supportedLanguages.entries.where((entry) {
      return entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return LiquidGlassContainer(
      width: 280,
      height: 450,
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const TranslatedText(
            'Select Language',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Language List
          Expanded(
            child: filteredLanguages.isEmpty
                ? const Center(child: TranslatedText('No results'))
                : ListView.builder(
                    itemCount: filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final entry = filteredLanguages[index];
                      final isSelected = entry.value == widget.currentLangCode;

                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blueAccent : const Color(0xFF1C1C1E),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, size: 18, color: Colors.blueAccent)
                            : null,
                        onTap: () {
                          context.read<LanguageCubit>().setLanguage(entry.value);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
