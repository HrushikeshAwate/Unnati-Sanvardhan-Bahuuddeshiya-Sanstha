import 'package:flutter/material.dart';
import 'package:usbs/core/localization/app_language.dart';

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final translated = AppI18n.tx(context, text);
    final loading = AppI18n.isTranslatingText(context, text);

    if (!loading) {
      return Text(
        translated,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            translated,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
          ),
        ),
        const SizedBox(width: 6),
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}
