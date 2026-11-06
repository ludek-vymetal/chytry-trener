import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../models/coach/coach_inbody_entry.dart';

/// Tvar postavy podle měření InBody / váhy SPAL: černá silueta na bílém
/// pozadí, která se pomalu otáčí kolem svislé osy (jde i otáčet tažením).
///
/// Z měření se bere:
/// * BMI a % tuku → celková „mohutnost“,
/// * rozložení tuku (trup × nohy) → jablko / hruška,
/// * rozložení svalů (paže + trup × nohy) → silný vršek / silné nohy,
/// * podíl kosterní svaloviny → ramena, paže, stehna.
/// Bez segmentální analýzy se tvar odhadne jen z BMI a % tuku.
class BodyShape {
  BodyShape._(this._levels, this._legs, this._arms, this.head,
      this.shapeLabel, this.muscleLabel, this.description);

  final List<_Level> _levels; // trup (shora dolů)
  final List<_Level> _legs; // jedna noha (střed ve vzdálenosti cx)
  final List<_Level> _arms; // jedna paže
  final _Level head;

  /// Hlavní tvar (Jablko, Hruška, …).
  final String shapeLabel;

  /// Rozložení svalů (Silný vršek, slabší nohy, …).
  final String muscleLabel;

  /// Krátké vysvětlení pro klienta.
  final String description;

  static double _c(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  factory BodyShape.fromEntry(CoachInbodyEntry e, {required bool male}) {
    final h = e.heightCm > 0 ? e.heightCm / 100.0 : (male ? 1.78 : 1.66);
    final w = e.weightKg > 0 ? e.weightKg : (male ? 80.0 : 62.0);
    final bmi = w / (h * h);
    final fatPct = e.bodyFatPercent > 0 ? e.bodyFatPercent : (male ? 18.0 : 27.0);

    // --- výchozí proporce (poloviční šířky a hloubky, výška postavy = 1)
    var sh = male ? 0.125 : 0.106; // ramena
    var ch = male ? 0.112 : 0.102; // hrudník
    var chD = male ? 0.072 : 0.07;
    var wa = male ? 0.090 : 0.077; // pas
    var waD = 0.068;
    var be = male ? 0.094 : 0.088; // podbřišek
    var beD = 0.07;
    var hi = male ? 0.100 : 0.114; // boky
    var hiD = male ? 0.074 : 0.08;
    var th = male ? 0.056 : 0.060; // stehno
    var ca = male ? 0.040 : 0.038; // lýtko
    var ua = male ? 0.034 : 0.030; // paže
    var fa = male ? 0.028 : 0.024; // předloktí
    var bellyZ = 0.0; // břicho dopředu
    var gluteZ = -0.006; // hýždě dozadu
    var chestZ = 0.004;

    // --- celková mohutnost podle BMI
    final size = _c(math.sqrt(bmi / 22.5), 0.82, 1.45);

    // --- tuk: kolik nad „sportovní normou“
    final refFat = male ? 15.0 : 25.0;
    final fd = _c((fatPct - refFat) / 15, -0.6, 1.6);
    final fatPlus = math.max(fd, 0.0);

    // rozložení tuku
    final segFat = e.fatLeftArmKg +
        e.fatRightArmKg +
        e.fatTrunkKg +
        e.fatLeftLegKg +
        e.fatRightLegKg;
    var dTr = 0.0, dLeg = 0.0;
    if (segFat > 0) {
      dTr = e.fatTrunkKg / segFat - (male ? 0.52 : 0.45);
      dLeg = (e.fatLeftLegKg + e.fatRightLegKg) / segFat - (male ? 0.32 : 0.40);
    }

    // rozložení svalů
    final upper = e.muscleLeftArmKg + e.muscleRightArmKg + e.muscleTrunkKg;
    final lower = e.muscleLeftLegKg + e.muscleRightLegKg;
    var mu = 0.0;
    if (upper > 0 && lower > 0) {
      mu = _c(upper / lower / (male ? 1.85 : 1.7) - 1, -0.3, 0.3);
    }
    var mm = 0.0;
    if (e.smmKg > 0) {
      mm = _c((e.smmKg / w - (male ? 0.44 : 0.37)) / 0.08, -1, 1.5);
    }

    // --- břicho (jablko)
    final belly = 1 + 0.35 * fatPlus * (1 + 3 * math.max(dTr, -0.2));
    wa *= belly;
    be *= belly;
    waD *= 1 + 0.5 * fatPlus * (1 + 3 * math.max(dTr, -0.2));
    beD *= 1 + 0.55 * fatPlus * (1 + 3 * math.max(dTr, -0.2));
    bellyZ = 0.022 * fatPlus * (1 + 3 * math.max(dTr, -0.2));
    if (fd < 0) {
      wa *= 1 + 0.18 * fd; // štíhlý pas
      be *= 1 + 0.12 * fd;
    }

    // --- boky a stehna (hruška)
    final hips = 1 + 0.25 * fatPlus * (1 + 3 * math.max(dLeg, -0.2));
    hi *= hips;
    hiD *= hips;
    th *= hips;
    gluteZ -= 0.012 * fatPlus * (1 + 2 * math.max(dLeg, -0.2));

    // --- svaly
    sh *= 1 + 0.12 * mm + 0.8 * mu;
    ch *= 1 + 0.06 * mm + 0.25 * mu;
    chD *= 1 + 0.10 * mm + 0.3 * mu;
    chestZ += 0.006 * math.max(mm, 0);
    ua *= 1 + 0.15 * mm + 0.9 * mu + 0.25 * fatPlus;
    fa *= 1 + 0.12 * mm + 0.5 * mu;
    th *= 1 + 0.12 * mm - 0.9 * mu;
    ca *= 1 + 0.10 * mm - 0.8 * mu;

    _Level t(double y, double a, double d, [double z = 0]) =>
        _Level(y, a * size, d * size, z * size);

    final torso = [
      t(0.118, 0.028, 0.032),
      t(0.135, 0.034, 0.036),
      t(0.152, sh * 0.62, 0.048),
      t(0.170, sh * 0.90, 0.056),
      t(0.195, sh, chD * 0.9, chestZ * 0.4), // ramena (index 4)
      t(0.235, sh * 0.96, chD * 0.97, chestZ * 0.8),
      t(0.270, ch, chD, chestZ),
      t(0.335, (ch + wa) / 2, (chD + waD) / 2, (chestZ + bellyZ) / 2),
      t(0.400, wa, waD, bellyZ * 0.8),
      t(0.455, be, beD, bellyZ),
      t(0.505, hi, hiD, gluteZ * 0.5),
      t(0.540, hi * 0.96, hiD * 0.95, gluteZ),
      t(0.556, hi * 0.80, hiD * 0.85, gluteZ * 0.6),
    ];

    final legs = [
      t(0.535, th, th * 1.08),
      t(0.600, th * 0.93, th),
      t(0.680, th * 0.72, th * 0.80),
      t(0.735, 0.034, 0.038),
      t(0.790, ca, ca * 1.1, -0.004),
      t(0.860, ca * 0.75, ca * 0.8),
      t(0.945, 0.022, 0.026),
      t(0.968, 0.024, 0.045, 0.02),
      t(0.985, 0.022, 0.050, 0.025),
    ];

    final arms = [
      t(0.165, ua * 0.80, ua * 0.90),
      t(0.190, ua * 1.12, ua * 1.05),
      t(0.240, ua, ua),
      t(0.310, ua * 0.85, ua * 0.88),
      t(0.345, 0.025, 0.026),
      t(0.400, fa, fa * 0.95),
      t(0.490, 0.019, 0.017),
      t(0.530, 0.025, 0.014),
      t(0.585, 0.018, 0.011),
    ];

    final head = t(0.062, 0.050, 0.060, 0.004);

    // --- popis
    String shape;
    String text;
    final excess = fatPct >= refFat + 3;
    if (excess && dTr > 0.04 && dTr >= dLeg) {
      shape = 'Jablko';
      text = 'Tuk se ukládá hlavně na břiše a trupu. Pomáhá redukce, '
          'pohyb a spánek – břišní tuk jde dolů jako první.';
    } else if (excess && dLeg > 0.04) {
      shape = 'Hruška';
      text = 'Tuk se ukládá hlavně na bocích a stehnech. Je zdravotně '
          'méně rizikový, ale odchází nejpomaleji.';
    } else if (excess) {
      shape = 'Rovnoměrně rozložený tuk';
      text = 'Tuk je rozložený po celém těle bez výrazné převahy.';
    } else if (mu > 0.1) {
      shape = 'V-tvar';
      text = 'Silná ramena a záda, pas užší. Nohy zaostávají – přidat '
          'objem na dřepy, výpady a mrtvé tahy.';
    } else if (mm > 0.5) {
      shape = 'Atletická postava';
      text = 'Nízký tuk a nadprůměrná svalová hmota.';
    } else {
      shape = 'Vyvážená postava';
      text = 'Tuk ani svaly nejsou výrazně posunuté k jedné části těla.';
    }

    String muscle;
    if (upper <= 0 || lower <= 0) {
      muscle = 'Svaly po částech těla nejsou změřené';
    } else if (mu > 0.1) {
      muscle = 'Silný vršek, slabší nohy';
    } else if (mu < -0.1) {
      muscle = 'Silné nohy, slabší vršek';
    } else {
      muscle = 'Svaly rozložené vyváženě';
    }
    if (upper > 0 && lower > 0 && mu < -0.1 && !excess) {
      text = 'Nohy jsou silné, horní polovina zaostává – přidat tlaky, '
          'přítahy a ramena.';
    }

    return BodyShape._(torso, legs, arms, head, shape, muscle, text);
  }
}

class _Level {
  const _Level(this.y, this.a, this.d, this.z);

  /// Výška od temene (0) k chodidlům (1).
  final double y;

  /// Poloviční šířka zepředu.
  final double a;

  /// Poloviční hloubka (zboku).
  final double d;

  /// Posun středu dopředu (+) / dozadu (−).
  final double z;
}

/// Karta s otáčející se siluetou a popisem tvaru postavy.
class BodyShapeCard extends StatefulWidget {
  const BodyShapeCard({super.key, required this.entry, required this.male});

  final CoachInbodyEntry entry;
  final bool male;

  @override
  State<BodyShapeCard> createState() => _BodyShapeCardState();
}

class _BodyShapeCardState extends State<BodyShapeCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _angle = 0;
  bool _drag = false;
  bool _pauza = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      if (_drag || _pauza) return;
      setState(() => _angle += dt * (2 * math.pi / 14)); // 1 otáčka / 14 s
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String get _pohled {
    final a = (_angle % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final deg = a * 180 / math.pi;
    if (deg < 30 || deg >= 330) return 'zepředu';
    if (deg < 150) return 'z boku';
    if (deg < 210) return 'zezadu';
    return 'z boku';
  }

  @override
  Widget build(BuildContext context) {
    final shape = BodyShape.fromEntry(widget.entry, male: widget.male);
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tvar postavy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _drag = true),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _angle += d.delta.dx / 90),
              onHorizontalDragEnd: (_) => setState(() => _drag = false),
              onDoubleTap: () => setState(() => _pauza = !_pauza),
              child: AspectRatio(
                aspectRatio: 0.62,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Semantics(
                    label: 'Silueta postavy: ${shape.shapeLabel}',
                    child: CustomPaint(
                      painter: _BodyPainter(shape, _angle),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pohled $_pohled · otoč tažením, dvojklik = zastavit',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Text(
              shape.shapeLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(shape.muscleLabel,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(shape.description, style: const TextStyle(height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter(this.shape, this.angle);

  final BodyShape shape;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height * 0.92;
    final top = size.height * 0.04;
    final cx = size.width / 2;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = true;

    double half(_Level l) =>
        math.sqrt(math.pow(l.a * cosA, 2) + math.pow(l.d * sinA, 2));

    // Svislý „válec“ z úrovní: střed (x, z) v prostoru, otočení kolem osy y.
    Path part(List<_Level> levels, double offX) {
      final left = <Offset>[];
      final right = <Offset>[];
      for (final l in levels) {
        final center = offX * cosA + l.z * sinA;
        final w = half(l);
        final y = top + l.y * unit;
        left.add(Offset(cx + (center - w) * unit, y));
        right.add(Offset(cx + (center + w) * unit, y));
      }
      final pts = [...left, ...right.reversed];
      return _smooth(pts);
    }

    // trup
    canvas.drawPath(part(shape._levels, 0), paint);

    // nohy (střed nohy = půlka šířky boků)
    final hip = shape._levels[shape._levels.length - 2];
    final legX = hip.a * 0.48;
    canvas.drawPath(part(shape._legs, -legX), paint);
    canvas.drawPath(part(shape._legs, legX), paint);

    // paže: odsazené od trupu, aby byla vidět mezera v pase
    double torsoAt(double y) {
      final ls = shape._levels;
      for (var i = 0; i < ls.length - 1; i++) {
        if (y >= ls[i].y && y <= ls[i + 1].y) {
          final t = (y - ls[i].y) / (ls[i + 1].y - ls[i].y);
          return ls[i].a + (ls[i + 1].a - ls[i].a) * t;
        }
      }
      return ls.last.a;
    }

    for (final side in [-1.0, 1.0]) {
      final left = <Offset>[];
      final right = <Offset>[];
      final shoulder = shape._levels[4].a;
      for (final l in shape._arms) {
        // u ramene se paže napojí na deltový sval, níž drží mezeru od trupu
        final atShoulder = shoulder - l.a * 0.7;
        var x = l.y < 0.25
            ? atShoulder
            : math.max(atShoulder, torsoAt(l.y) + l.a + 0.012);
        x *= side;
        final center = x * cosA + l.z * sinA;
        final w = half(l);
        final y = top + l.y * unit;
        left.add(Offset(cx + (center - w) * unit, y));
        right.add(Offset(cx + (center + w) * unit, y));
      }
      canvas.drawPath(_smooth([...left, ...right.reversed]), paint);
    }

    // hlava
    final h = shape.head;
    final hc = h.z * sinA;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + hc * unit, top + h.y * unit),
        width: half(h) * 2 * unit,
        height: 0.118 * unit,
      ),
      paint,
    );
  }

  /// Uzavřená hladká křivka přes body (kvadratické Bézierovy oblouky
  /// mezi středy sousedních úseček).
  static Path _smooth(List<Offset> pts) {
    final path = Path();
    if (pts.length < 3) return path;
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    path.moveTo(mid(pts.last, pts.first).dx, mid(pts.last, pts.first).dy);
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final n = pts[(i + 1) % pts.length];
      final m = mid(p, n);
      path.quadraticBezierTo(p.dx, p.dy, m.dx, m.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.angle != angle || old.shape != shape;
}
