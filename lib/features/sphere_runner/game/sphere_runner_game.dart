import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Gate operation ───────────────────────────────────────────────────────────

enum OpType { add, subtract, multiply }

class GateOp {
  final OpType type;
  final int value;

  const GateOp(this.type, this.value);

  int apply(int n) => switch (type) {
        OpType.add => (n + value).clamp(0, 99),
        OpType.subtract => (n - value).clamp(0, 99),
        OpType.multiply => (n * value).clamp(0, 99),
      };

  // Mathematical symbol — not localised (language-independent notation)
  String get label => switch (type) {
        OpType.add => '+$value',
        OpType.subtract => '-$value',
        OpType.multiply => '×$value',
      };

  Color get colour => switch (type) {
        OpType.add => const Color(0xFF4CAF50),
        OpType.subtract => const Color(0xFFF44336),
        OpType.multiply => const Color(0xFF2196F3),
      };
}

// ─── Spring physics ───────────────────────────────────────────────────────────

class _Spring {
  Vector2 target;
  Vector2 pos;
  Vector2 vel = Vector2.zero();

  _Spring(Vector2 t)
      : target = t.clone(),
        pos = t.clone();

  void step(double dt) {
    final spring = (target - pos)..scale(14 * dt);
    vel
      ..add(spring)
      ..scale(pow(0.87, dt * 60).toDouble());
    pos.add(vel * dt);
  }

  void kick(Vector2 v) => vel.add(v);
}

// ─── Scrolling track ──────────────────────────────────────────────────────────

class TrackComponent extends Component
    with HasGameReference<SphereRunnerGame> {
  double _scroll = 0;

  @override
  int get priority => 0;

  @override
  void update(double dt) {
    _scroll = (_scroll + game.scrollSpeed * dt) % 60;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final tl = w * 0.08;
    final tr = w * 0.92;
    final mid = w / 2;

    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0d1b2a), Color(0xFF162030)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Road surface
    canvas.drawRect(
      Rect.fromLTRB(tl, 0, tr, h),
      Paint()..color = const Color(0xFF1a3050),
    );

    // Horizontal speed lines
    final speedPaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1;
    for (double y = -_scroll; y < h; y += 60) {
      canvas.drawLine(Offset(tl, y), Offset(tr, y), speedPaint);
    }

    // Dashed centre divider
    final dashPaint = Paint()
      ..color = Colors.white.withAlpha(70)
      ..strokeWidth = 2;
    for (double y = -_scroll; y < h; y += 60) {
      canvas.drawLine(Offset(mid, y), Offset(mid, y + 32), dashPaint);
    }

    // Road edges
    final edgePaint = Paint()
      ..color = Colors.white.withAlpha(170)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(tl, 0), Offset(tl, h), edgePaint);
    canvas.drawLine(Offset(tr, 0), Offset(tr, h), edgePaint);

    // Subtle highlight of active lane
    final lane = game.inLeftLane
        ? Rect.fromLTRB(tl, h * 0.62, mid - 3, h)
        : Rect.fromLTRB(mid + 3, h * 0.62, tr, h);
    canvas.drawRect(lane, Paint()..color = Colors.white.withAlpha(8));
  }
}

// ─── Gate pair ────────────────────────────────────────────────────────────────

class GatePair extends PositionComponent
    with HasGameReference<SphereRunnerGame> {
  final GateOp leftOp;
  final GateOp rightOp;
  bool _passed = false;

  static const double gateH = 68.0;

  GatePair({
    required Vector2 startPos,
    required this.leftOp,
    required this.rightOp,
  }) : super(position: startPos, priority: 1);

  @override
  void update(double dt) {
    y += game.scrollSpeed * dt;

    if (!_passed) {
      final py = game.playerY;
      if (y > py - 40 && y < py + 40) {
        _passed = true;
        game.applyOp(game.inLeftLane ? leftOp : rightOp);
      }
    }

    if (y > game.size.y + gateH + 20) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final tl = w * 0.08;
    final tr = w * 0.92;
    const gap = 4.0;
    final mid = w / 2;

    _drawGate(canvas, tl, mid - gap, leftOp, game.inLeftLane);
    _drawGate(canvas, mid + gap, tr, rightOp, !game.inLeftLane);
  }

  void _drawGate(Canvas canvas, double l, double r, GateOp op, bool active) {
    final rect = Rect.fromLTWH(l, -gateH / 2, r - l, gateH);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    if (active) {
      canvas.drawRRect(
        rr.inflate(6),
        Paint()
          ..color = op.colour.withAlpha(45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.drawRRect(rr, Paint()..color = op.colour.withAlpha(active ? 120 : 65));

    canvas.drawRRect(
      rr,
      Paint()
        ..color = op.colour.withAlpha(active ? 240 : 130)
        ..strokeWidth = active ? 3.0 : 1.5
        ..style = PaintingStyle.stroke,
    );

    // Label — mathematical notation, no localisation needed
    TextPaint(
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [Shadow(color: op.colour, blurRadius: 14)],
      ),
    ).render(canvas, op.label, Vector2((l + r) / 2, 0), anchor: Anchor.center);
  }
}

// ─── Player sphere cluster ────────────────────────────────────────────────────

class PlayerCluster extends PositionComponent
    with HasGameReference<SphereRunnerGame> {
  final _rng = Random();
  final List<_Spring> _springs = [];
  double _targetX = 0;
  double _currentX = 0;
  double _velX = 0;

  static const double _r = 15.0;

  PlayerCluster() : super(priority: 2);

  @override
  void onMount() {
    super.onMount();
    position = Vector2(game.size.x / 2, game.playerY);
    _rebuild(game.sphereCount);
  }

  void moveTo(bool left) {
    _targetX = (left ? -1.0 : 1.0) * game.size.x * 0.22;
    final kx = left ? 40.0 : -40.0;
    for (final s in _springs) {
      s.kick(Vector2(kx, -(_rng.nextDouble() * 10 + 4)));
    }
  }

  void syncCount() => _rebuild(game.sphereCount);

  void _rebuild(int n) {
    final targets = _clusterPositions(n, _r);
    while (_springs.length < targets.length) {
      _springs.add(_Spring(targets[_springs.length]));
    }
    while (_springs.length > targets.length) {
      _springs.removeLast();
    }
    for (int i = 0; i < targets.length; i++) {
      _springs[i].target = targets[i];
    }
  }

  @override
  void update(double dt) {
    if (_springs.length != game.sphereCount) _rebuild(game.sphereCount);

    final err = _targetX - _currentX;
    _velX += err * 28 * dt;
    _velX *= pow(0.72, dt * 60).toDouble();

    if (_velX.abs() > 3) {
      for (final s in _springs) {
        s.kick(Vector2(-_velX * dt * 2.2, 0));
      }
    }

    _currentX += _velX * dt;
    x = game.size.x / 2 + _currentX;

    for (final s in _springs) {
      s.step(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _springs.length; i++) {
      _drawSphere(canvas, _springs[i].pos, _r, i);
    }
  }

  void _drawSphere(Canvas canvas, Vector2 c, double r, int idx) {
    final hue = (idx * 31.0 + 200) % 360;
    final base = HSLColor.fromAHSL(1, hue, 0.72, 0.52).toColor();
    final highlight = HSLColor.fromAHSL(1, hue, 0.55, 0.80).toColor();
    final shadow = HSLColor.fromAHSL(1, hue, 0.82, 0.24).toColor();

    canvas.drawCircle(
      Offset(c.x, c.y),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.38),
          radius: 0.85,
          colors: [highlight, base, shadow],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(c.x, c.y), radius: r)),
    );

    canvas.drawCircle(
      Offset(c.x - r * 0.3, c.y - r * 0.3),
      r * 0.22,
      Paint()..color = Colors.white.withAlpha(125),
    );
  }

  /// Hexagonal ring packing for N spheres.
  static List<Vector2> _clusterPositions(int n, double r) {
    final out = <Vector2>[];
    if (n <= 0) return out;
    out.add(Vector2.zero());
    final spacing = r * 2.15;
    int ring = 1;
    while (out.length < n) {
      final perRing = ring * 6;
      for (int i = 0; i < perRing && out.length < n; i++) {
        final angle = (2 * pi / perRing) * i - pi / 2;
        out.add(Vector2(cos(angle) * ring * spacing, sin(angle) * ring * spacing));
      }
      ring++;
    }
    return out;
  }
}

// ─── Main game ────────────────────────────────────────────────────────────────

class SphereRunnerGame extends FlameGame with DragCallbacks, KeyboardEvents {
  int sphereCount = 3;
  bool inLeftLane = true;
  bool endgameMode = false;
  bool gameWon = false;
  double scrollSpeed = 155;

  double get playerY => size.y * 0.75;

  /// Observed by the Flutter HUD overlay for live sphere count updates.
  final sphereCountNotifier = ValueNotifier<int>(3);

  final _rng = Random();
  final _smartQueue = <({GateOp left, GateOp right})>[];
  late final PlayerCluster _cluster;
  double _gateTimer = 0;

  static const double _gateInterval = 3.0;

  @override
  Color backgroundColor() => const Color(0xFF0d1b2a);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(TrackComponent());
    _cluster = PlayerCluster();
    add(_cluster);
    _spawnGate();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameWon) return;
    _gateTimer += dt;
    if (_gateTimer >= _gateInterval) {
      _gateTimer = 0;
      _spawnGate();
    }
  }

  // ── Gate spawning ─────────────────────────────────────────────────────────

  void _spawnGate() {
    final GateOp left, right;
    if (endgameMode && _smartQueue.isNotEmpty) {
      final g = _smartQueue.removeAt(0);
      left = g.left;
      right = g.right;
    } else {
      left = _randOp();
      right = _randOp();
    }
    add(GatePair(
      startPos: Vector2(0, -GatePair.gateH - 10),
      leftOp: left,
      rightOp: right,
    ));
  }

  GateOp _randOp() => switch (_rng.nextInt(3)) {
        0 => GateOp(OpType.add, _rng.nextInt(10) + 1),
        1 => GateOp(OpType.subtract, _rng.nextInt(10) + 1),
        _ => GateOp(OpType.multiply, 2),
      };

  // ── Operation logic ───────────────────────────────────────────────────────

  void applyOp(GateOp op) {
    sphereCount = op.apply(sphereCount);
    _cluster.syncCount();
    sphereCountNotifier.value = sphereCount;

    if (sphereCount == 20) {
      gameWon = true;
      overlays.add('win');
      return;
    }

    if (sphereCount > 15) {
      endgameMode = true;
      _smartQueue.clear();
      _buildEndgame();
    } else {
      endgameMode = false;
      _smartQueue.clear();
    }
  }

  /// Pre-calculate up to 2 gate pairs whose correct path reaches exactly 20.
  void _buildEndgame() {
    final need = 20 - sphereCount;
    if (need == 0) return;

    final absNeed = need.abs();
    final opType = need > 0 ? OpType.add : OpType.subtract;

    if (absNeed <= 10) {
      _enqueue(GateOp(opType, absNeed));
      return;
    }

    for (int a = 1; a < absNeed && a <= 10; a++) {
      final b = absNeed - a;
      if (b >= 1 && b <= 10) {
        _enqueue(GateOp(opType, a));
        _enqueue(GateOp(opType, b));
        return;
      }
    }

    _enqueue(GateOp(opType, absNeed.clamp(1, 10)));
  }

  void _enqueue(GateOp correct) {
    final decoy = _randOp();
    _rng.nextBool()
        ? _smartQueue.add((left: correct, right: decoy))
        : _smartQueue.add((left: decoy, right: correct));
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    sphereCount = 3;
    inLeftLane = true;
    endgameMode = false;
    gameWon = false;
    _smartQueue.clear();
    _gateTimer = 0;
    sphereCountNotifier.value = 3;
    children.whereType<GatePair>().toList().forEach(remove);
    _cluster.syncCount();
    _cluster.moveTo(true);
    overlays.remove('win');
    _spawnGate();
  }

  // ── Keyboard input (desktop) ──────────────────────────────────────────────

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && !inLeftLane) {
        inLeftLane = true;
        _cluster.moveTo(true);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight && inLeftLane) {
        inLeftLane = false;
        _cluster.moveTo(false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ── Swipe input ───────────────────────────────────────────────────────────

  double _swipeAccum = 0;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _swipeAccum = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _swipeAccum += event.localDelta.x;
    if (_swipeAccum.abs() > 28) {
      final goLeft = _swipeAccum < 0;
      if (goLeft != inLeftLane) {
        inLeftLane = goLeft;
        _cluster.moveTo(inLeftLane);
      }
      _swipeAccum = 0;
    }
  }
}
