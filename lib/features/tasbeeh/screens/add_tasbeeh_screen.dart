import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants.dart';
import '../state/tasbeeh_bloc.dart';
import '../models/counter.dart';

class AddTasbeehScreen extends StatefulWidget {
  final TasbeehCounter? editCounter;

  const AddTasbeehScreen({super.key, this.editCounter});

  @override
  State<AddTasbeehScreen> createState() => _AddTasbeehScreenState();
}

class _AddTasbeehScreenState extends State<AddTasbeehScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _arabicCtrl;
  late TextEditingController _transliterationCtrl;
  late TextEditingController _translationCtrl;
  late TextEditingController _targetCtrl;
  String _selectedCategory = 'Custom';

  @override
  void initState() {
    super.initState();
    final e = widget.editCounter;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _arabicCtrl = TextEditingController(text: e?.arabicText ?? '');
    _transliterationCtrl = TextEditingController(text: e?.transliteration ?? '');
    _translationCtrl = TextEditingController(text: e?.translation ?? '');
    _targetCtrl = TextEditingController(text: '${e?.targetCount ?? 33}');
    if (e != null) _selectedCategory = e.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _arabicCtrl.dispose();
    _transliterationCtrl.dispose();
    _translationCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _save(TasbeehBloc bloc) {
    if (!_formKey.currentState!.validate()) return;

    final counter = TasbeehCounter(
      id: widget.editCounter?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      arabicText: _arabicCtrl.text.trim(),
      transliteration: _transliterationCtrl.text.trim(),
      translation: _translationCtrl.text.trim(),
      targetCount: int.tryParse(_targetCtrl.text) ?? 33,
      category: _selectedCategory,
    );

    bloc.addCustomCounter(counter);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(builder: (context, state) {
      final bloc = context.read<TasbeehBloc>();
      return Scaffold(
        backgroundColor: TasbeehColors.background,
        appBar: AppBar(
          backgroundColor: TasbeehColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded,
                color: TasbeehColors.steelBlue),
            onPressed: () => Navigator.pop(context),
          ),
          title: ShaderMask(
            shaderCallback: (b) =>
                TasbeehColors.primaryGradient.createShader(b),
            child: const Text(
              'Add Custom Dhikr',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: TasbeehColors.babyBlue),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionLabel('Arabic Text'),
              _buildField(
                controller: _arabicCtrl,
                hint: 'اكتب الذكر بالعربية',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                arabicStyle: true,
                validator: (v) =>
                v == null || v.isEmpty ? 'Please enter Arabic text' : null,
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Name'),
              _buildField(
                controller: _nameCtrl,
                hint: 'e.g. SubhanAllah',
                validator: (v) =>
                v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Transliteration'),
              _buildField(
                controller: _transliterationCtrl,
                hint: 'e.g. SubhanAllah',
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Translation'),
              _buildField(
                controller: _translationCtrl,
                hint: 'e.g. Glory be to Allah',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Target Count'),
              _buildField(
                controller: _targetCtrl,
                hint: '33',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildSectionLabel('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCategories
                    .where((c) => c != 'All')
                    .map((cat) {
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient:
                        selected ? TasbeehColors.primaryGradient : null,
                        color: selected ? null : TasbeehColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? TasbeehColors.blueDark
                              : TasbeehColors.babyBlue,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : TasbeehColors.steelBlue,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => _save(bloc),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: TasbeehColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: TasbeehColors.standardBlue.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save Dhikr',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TasbeehTextStyles.subheading
            .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
    bool arabicStyle = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: arabicStyle
          ? TasbeehTextStyles.arabicLarge(22)
          : const TextStyle(
        fontSize: 15,
        color: TasbeehColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: TasbeehColors.textLight.withValues(alpha: 0.6),
          fontFamily: arabicStyle ? 'Amiri' : null,
          fontSize: arabicStyle ? 18 : 14,
        ),
        filled: true,
        fillColor: TasbeehColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TasbeehColors.babyBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TasbeehColors.babyBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: TasbeehColors.standardBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}