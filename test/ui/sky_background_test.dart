import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/domain/condition_map.dart';
import 'package:howeather/ui/sky/sky_background.dart';

void main() {
  loopTests();

  test('SkyColors.gradient has 2+ colours for every scene', () {
    for (final s in SkyScene.values) {
      expect(
        SkyColors.gradient(s).length,
        greaterThanOrEqualTo(2),
        reason: '$s',
      );
    }
  });

  testWidgets('SkyBackground renders every scene with animations disabled', (
    tester,
  ) async {
    for (final s in SkyScene.values) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SkyBackground(s),
        ),
      );
      expect(tester.takeException(), isNull, reason: '$s');
      expect(find.byType(CustomPaint), findsWidgets);
      // Static frame: no ticker scheduled.
      expect(tester.binding.hasScheduledFrame, isFalse, reason: '$s');
    }
  });

  testWidgets('SkyBackground animates when animations are enabled', (
    tester,
  ) async {
    await tester.pumpWidget(const SkyBackground(SkyScene.rainDay));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}

/// Distance on a circle of circumference [period] (handles wrap-around).
double _wrapDist(double a, double b, double period) {
  final d = (a - b).abs() % period;
  return d < period - d ? d : period - d;
}

void loopTests() {
  group('motion loops seamlessly (v = 0 equals v = 1)', () {
    const w = 400.0;
    test('clouds', () {
      for (var i = 0; i < cloudSpecs.length; i++) {
        expect(
          _wrapDist(cloudX(i, 0, w), cloudX(i, 1, w), w * 1.6),
          lessThan(1e-6),
          reason: 'cloud $i',
        );
      }
    });
    test('rain and snow', () {
      for (final s in skySeeds) {
        expect(_wrapDist(rainPhase(s, 0), rainPhase(s, 1), 1), lessThan(1e-9));
        expect(_wrapDist(snowPhase(s, 0), snowPhase(s, 1), 1), lessThan(1e-9));
        expect(snowSway(s, 0), closeTo(snowSway(s, 1), 1e-9));
      }
    });
  });
}
