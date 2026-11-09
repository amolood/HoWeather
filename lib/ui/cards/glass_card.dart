import 'dart:ui';

import 'package:flutter/material.dart';

import '../icons/glyphs.dart';
import '../sky/sky_palette.dart';
import '../theme.dart';
import '../typography.dart';

/// Frosted glass panel used by every home card: a small uppercase label at
/// the top-start, the [child], and an optional bottom row ([footer]) that
/// sits at the bottom of the card when the card is stretched (paired cards).
/// Colours come from the [SkyPalette], not the app theme.
class GlassCard extends StatelessWidget {
  final String? title;
  final Glyph? glyph;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    this.title,
    this.glyph,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(AppTokens.cardPadding),
  });

  @override
  Widget build(BuildContext context) {
    final p = SkyPalette.of(context);
    final radius = BorderRadius.circular(AppTokens.radius);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          CardHeader(title!, glyph: glyph),
          const SizedBox(height: 12),
        ],
        child,
      ],
    );
    if (footer != null) {
      // Bounded height (stretched pair): footer pinned to the bottom.
      // Unbounded: plain stacking.
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          content,
          Padding(padding: const EdgeInsets.only(top: 12), child: footer),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0A1E3C),
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: p.glass,
              borderRadius: radius,
              border: Border.all(color: p.glassLine),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.ink),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small uppercase card label (glyph + title) in tertiary ink.
class CardHeader extends StatelessWidget {
  final String title;
  final Glyph? glyph;
  const CardHeader(this.title, {super.key, this.glyph});

  @override
  Widget build(BuildContext context) {
    final faint = SkyPalette.of(context).inkFaint;
    return Row(
      children: [
        if (glyph != null) ...[
          GlyphView(glyph!, size: 15, color: faint),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            AppType.labelText(context, title),
            maxLines: 2,
            style: AppType.labelOf(context).copyWith(color: faint),
          ),
        ),
      ],
    );
  }
}

/// The dominant value of a card, with a small top-aligned unit after it.
class BigValue extends StatelessWidget {
  final String value;
  final String unit;
  const BigValue(this.value, {super.key, this.unit = ''});

  @override
  Widget build(BuildContext context) {
    final p = SkyPalette.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      // Number first, unit after it, in every locale ("21 km/h").
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppType.metric.copyWith(color: p.ink)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                unit,
                style: AppType.metricUnit.copyWith(color: p.inkSoft),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom row of a card: secondary [info] at the start, a [pill] at the end.
class CardFooter extends StatelessWidget {
  final String info;
  final String? pill;
  final Widget? pillLeading;
  const CardFooter({super.key, this.info = '', this.pill, this.pillLeading});

  @override
  Widget build(BuildContext context) {
    final p = SkyPalette.of(context);
    final hasPill = pill != null && pill!.isNotEmpty;
    // The pill keeps its natural width (up to most of the row) so the state
    // word stays readable; the info line wraps in what is left.
    // (No LayoutBuilder: paired cards are measured with IntrinsicHeight.)
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              info,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(color: p.inkSoft),
            ),
          ),
          if (hasPill) ...[
            const SizedBox(width: 8),
            // Natural width, capped so long labels ellipsize instead of
            // squeezing the info line to nothing.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.textScalerOf(context).scale(104),
              ),
              child: SkyPill(
                pill!,
                key: const ValueKey('cardPill'),
                leading: pillLeading,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small rounded state pill with a translucent white fill.
class SkyPill extends StatelessWidget {
  final String text;
  final Widget? leading;
  const SkyPill(this.text, {super.key, this.leading});

  @override
  Widget build(BuildContext context) {
    final p = SkyPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.pill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.glassLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded temperature with a degree sign: `9.6` -> `"10°"`.
String roundedTemp(double v) => '${v.round()}°';
