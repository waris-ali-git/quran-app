import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/translation_service.dart';
import '../state/language_cubit.dart';
import '../di.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translatedText;
  String _currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _currentLang = context.read<LanguageCubit>().state;
    _translateIfNeeded();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translatedText = null;
      _translateIfNeeded();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = context.watch<LanguageCubit>().state;
    if (newLang != _currentLang) {
      _currentLang = newLang;
      _translatedText = null;
      _translateIfNeeded();
    }
  }

  Future<void> _translateIfNeeded() async {
    if (_currentLang == 'en' || _currentLang.isEmpty) {
      if (mounted) {
        setState(() {
          _translatedText = widget.text;
        });
      }
      return;
    }

    final translationService = sl<TranslationService>();
    final result = await translationService.translate(
      text: widget.text,
      targetLang: _currentLang,
    );

    if (mounted) {
      setState(() {
        _translatedText = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = _currentLang == 'ar';
    final bool isUrdu = _currentLang == 'ur';
    final effectiveStyle = isArabic
        ? (widget.style?.copyWith(fontFamily: 'DigitalKhatt') ??
            const TextStyle(fontFamily: 'DigitalKhatt'))
        : isUrdu
            ? (widget.style?.copyWith(fontFamily: 'Jameel Noori') ??
                const TextStyle(fontFamily: 'Jameel Noori'))
            : widget.style;

    if (_translatedText == null) {
      // Show original text with slight opacity while loading to avoid layout jumping
      return Text(
        widget.text,
        style: effectiveStyle?.copyWith(
            color: effectiveStyle.color?.withValues(alpha: 0.5) ??
                Colors.grey.withValues(alpha: 0.5)),
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return Text(
      _translatedText!,
      style: effectiveStyle,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
