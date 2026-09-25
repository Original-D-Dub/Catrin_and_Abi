import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/route_observers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/game_filters.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/settings_provider.dart';
import '../../../shared/widgets/back_arrow_icon.dart';
import '../../welcome/widgets/speech_bubble.dart';
import '../models/trail_node.dart';
import '../providers/trail_provider.dart';

/// The "Learn BSL"/"Learn IAC" guided trail: a full-width intro block above
/// a chain of mini-game lockups (circular thumbnail, name pill, level
/// badge), staggered left/right down the screen so the sequence reads as a
/// winding path, with a fork/merge after letter_bingo level 1. Tapping an
/// unlocked lockup launches that game directly at that level.
class LearnBslTrailScreen extends StatefulWidget {
  /// UI locale ('en' or 'cy').
  final String locale;

  const LearnBslTrailScreen({super.key, this.locale = 'en'});

  @override
  State<LearnBslTrailScreen> createState() => _LearnBslTrailScreenState();
}

/// One section of the trail after section 1, hidden behind the previous
/// section's clouds until [gateNodeId] is completed — see
/// [_LearnBslTrailScreenState._gatedSections].
class _GatedSection {
  final String gateNodeId;
  final int startIndex;
  final String titleKey;
  final String descriptionKey;

  const _GatedSection({
    required this.gateNodeId,
    required this.startIndex,
    required this.titleKey,
    required this.descriptionKey,
  });
}

class _LearnBslTrailScreenState extends State<LearnBslTrailScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrailProvider>().loadProgress();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      trailRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    trailRouteObserver.unsubscribe(this);
    _cloudPartController.dispose();
    _lockedTapTimer?.cancel();
    super.dispose();
  }

  // Id of the locked node whose "why is this locked" speech bubble is
  // currently showing, or null when none is — set by tapping a locked
  // lockup (see [_handleLockedTap]) and cleared automatically after
  // [_lockedTapMessageDuration].
  String? _lockedTapNodeId;
  Timer? _lockedTapTimer;

  static const Duration _lockedTapMessageDuration = Duration(seconds: 3);

  void _handleLockedTap(TrailNode node) {
    _lockedTapTimer?.cancel();
    setState(() => _lockedTapNodeId = node.id);
    _lockedTapTimer = Timer(_lockedTapMessageDuration, () {
      if (mounted) setState(() => _lockedTapNodeId = null);
    });
  }

  // The node this one unlocks from is found via [TrailNode.nextNodeIds]
  // rather than just `bslTrail[index - 1]` — that assumption only holds for
  // the linear stretches of the trail, not the fork after letter_bingo_1
  // (where two nodes share one predecessor) or letter_bingo_3 (which has
  // two). Only the common single-predecessor case gets the specific "finish
  // level N" message; forks/merges fall back to the generic one since
  // there's no single "previous level" to name.
  String _lockedTapMessage(
    TrailProvider trail,
    TrailNode node,
    AppLocalizations localizer,
  ) {
    final predecessors = bslTrail
        .where((n) => n.nextNodeIds.contains(node.id))
        .toList();
    if (predecessors.length == 1 && trail.isNodeUnlocked(predecessors.first)) {
      final previousLevel = bslTrail.indexOf(predecessors.first) + 1;
      return localizer('trail.locked_message_previous')
          .replaceAll('{level}', '$previousLevel');
    }
    return localizer('trail.locked_message_generic');
  }

  // Fired by [trailRouteObserver] the moment this screen becomes visible
  // again after a game screen pushed on top of it is popped — the point at
  // which the player would actually see the clouds part, as opposed to the
  // moment TrailProvider's state changes (which happens as soon as the
  // level ends, while its success overlay still covers the trail).
  @override
  void didPopNext() {
    _maybeStartCloudParting(context.read<TrailProvider>());
  }

  // Drives the Simpsons-style cloud-parting reveal that plays when the
  // player returns to the trail having just unlocked a new section. Only
  // one section can ever be mid-reveal at a time (sections unlock one
  // level-completion at a time), so a single controller shared by every
  // gated section is enough.
  late final AnimationController _cloudPartController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Eases the parting in and out (slow-fast-slow) rather than moving the
  // clouds at a constant linear speed.
  late final Animation<double> _cloudPartAnimation = CurvedAnimation(
    parent: _cloudPartController,
    curve: Curves.easeInOut,
  );

  // The gate node currently mid-reveal, or null when no parting animation
  // is in flight — identifies whose heading should currently be covered by
  // (and animating apart via) the cloud overlay in [_buildSectionWidgets],
  // rather than sitting fully revealed with no overlay at all.
  String? _partingGateNodeId;

  // Beat before the clouds start pulling apart — long enough for the
  // player to register they're back on the trail (and that its map has
  // changed) before the reveal itself kicks off.
  static const Duration _cloudPartDelay = Duration(seconds: 2);

  void _maybeStartCloudParting(TrailProvider trail) {
    if (_partingGateNodeId != null) return;
    final gateId = trail.justCompletedNodeId;
    if (gateId == null || !_gatedSections.any((s) => s.gateNodeId == gateId)) {
      return;
    }
    // Consumed immediately so a later revisit (e.g. after the app is
    // restarted with this node already completed) never replays it.
    trail.consumeJustCompleted();
    // Setting this now (rather than after the delay) is what keeps the
    // newly-unlocked section's heading and cloud band hidden under fully
    // closed clouds for the duration of the delay, instead of popping in
    // early.
    setState(() => _partingGateNodeId = gateId);
    Future.delayed(_cloudPartDelay, () {
      if (!mounted) return;
      _cloudPartController.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _partingGateNodeId = null);
      });
    });
  }

  // Breakpoint below which the pill name keeps the default font size —
  // only wider (tablet-ish) devices get the larger size.
  static const double _wideDeviceBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations(locale: widget.locale);
    final trail = context.watch<TrailProvider>();
    final screenSize = MediaQuery.of(context).size;
    final isWideDevice = screenSize.width >= _wideDeviceBreakpoint;
    final nameFontSize = AppSizes.fontSizeSmall + (isWideDevice ? 2 : 0);
    // Clouds hiding the not-yet-built continuation of the trail, past the
    // last defined level — sized relative to the device, not the (much
    // taller) scrollable trail content.
    final cloudHeight = screenSize.height * 0.25;

    // The trail's own branding (title + section 1's intro copy) follows the
    // player's BSL/IAC sign-system setting, same as the home-screen tile
    // that links here — the underlying level structure is identical either
    // way, only the framing changes. Section 2 (counting) has no IAC
    // variant, so it isn't affected.
    final isIac =
        context.watch<SettingsProvider>().signSystem == SignSystem.iac;
    final trailNameKey = isIac ? 'trail.iac.name' : 'trail.bsl.name';
    final section1DescriptionKey = isIac
        ? 'trail.iac.section1.description'
        : 'trail.bsl.section1.description';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          localizer(trailNameKey),
          style: AppTheme.title.copyWith(
            fontSize: AppSizes.fontSizeLarge,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const BackArrowIcon(),
          tooltip: localizer('general.back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF8BC34A))),
          // bottom: false — the scrollable content (and the clouds at its
          // end) should be able to scroll all the way to the physical
          // bottom edge of the screen instead of stopping short at the
          // safe-area inset, which would otherwise always show a strip of
          // plain background beneath the clouds.
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              // No bottom inset — otherwise this padding would leave a
              // strip of background showing below the clouds even once
              // scrolled all the way down.
              padding: const EdgeInsets.only(
                left: AppSizes.paddingMedium,
                right: AppSizes.paddingMedium,
                top: AppSizes.paddingMedium,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.spacingLarge),
                  _TrailSection(
                    localizer: localizer,
                    titleKey: 'trail.section1.title',
                    descriptionKey: section1DescriptionKey,
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  if (trail.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSizes.paddingLarge),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    ..._buildSectionWidgets(
                      context,
                      trail,
                      localizer,
                      nameFontSize,
                      cloudHeight,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Every section after section 1, in order — each stays hidden behind the
  // previous section's clouds until [_GatedSection.gateNodeId] is
  // completed. Section 1 itself isn't listed here since it's always
  // visible (it has no gate).
  static final List<_GatedSection> _gatedSections = [
    _GatedSection(
      gateNodeId: 'bubble_pop_4',
      startIndex: bslTrail.indexWhere((n) => n.id == 'counting_game_1'),
      titleKey: 'trail.section2.title',
      descriptionKey: 'trail.section2.description',
    ),
    _GatedSection(
      gateNodeId: 'counting_game_8',
      startIndex: bslTrail.indexWhere((n) => n.id == 'letter_bingo_2'),
      titleKey: 'trail.section3.title',
      descriptionKey: 'trail.section3.description',
    ),
  ];

  /// Builds section 1's path plus every gated section unlocked so far.
  /// Sections unlock strictly in order — a gate node only becomes reachable
  /// by playing through the section before it — so this never has to look
  /// past the first locked one.
  ///
  /// A still-locked gate's continuation is hidden by a plain closed cloud
  /// band trailing the segment above it (see [_buildTrailPath]'s
  /// `showClouds`) — there's nothing to reveal yet, so those clouds never
  /// animate. The moment a gate *is* unlocked, that plain band disappears
  /// (the path itself is drawn in full, right down to its last node) and
  /// the newly-unlocked section's own heading takes over as the thing the
  /// clouds sit on top of and reveal — see the loop below.
  List<Widget> _buildSectionWidgets(
    BuildContext context,
    TrailProvider trail,
    AppLocalizations localizer,
    double nameFontSize,
    double cloudHeight,
  ) {
    final widgets = <Widget>[];

    // Whether the segment leading up to [gate] should still show its plain
    // "hides what's not built/unlocked yet" cloud band: true whenever that
    // gate hasn't completed. `gate == null` is section 1 or the trail's
    // true end, which never has anything to unlock and so always keeps it.
    bool showClouds(_GatedSection? gate) =>
        gate == null || !trail.completedNodeIds.contains(gate.gateNodeId);

    final firstGate = _gatedSections.isEmpty ? null : _gatedSections.first;
    widgets.add(
      LayoutBuilder(
        builder: (context, constraints) => _buildTrailPath(
          context,
          trail,
          localizer,
          constraints.maxWidth,
          nameFontSize,
          cloudHeight,
          startIndex: 0,
          endIndex: firstGate?.startIndex ?? bslTrail.length,
          showClouds: showClouds(firstGate),
        ),
      ),
    );

    for (var i = 0; i < _gatedSections.length; i++) {
      final section = _gatedSections[i];
      if (!trail.completedNodeIds.contains(section.gateNodeId)) break;
      final nextSection = i + 1 < _gatedSections.length
          ? _gatedSections[i + 1]
          : null;
      // Roomier than the usual spacingLarge gap elsewhere on the trail —
      // this is the last card of the section above sitting right next to
      // the next section's title, so it gets a bit more breathing room.
      widgets.add(const SizedBox(height: AppSizes.spacingXLarge));
      widgets.add(
        Stack(
          clipBehavior: Clip.none,
          children: [
            _TrailSection(
              localizer: localizer,
              titleKey: section.titleKey,
              descriptionKey: section.descriptionKey,
            ),
            // Layered directly on top of the heading above — not beside
            // it — so parting these clouds is what reveals the title and
            // description, rather than the heading just appearing next to
            // a separate cloud band. Extends up past its own top edge by
            // the same spacingXLarge gap above to swallow it (where the
            // segment before it used to keep its own closed band right up
            // until this gate completed), so there's a single unbroken
            // cloud mass rather than two separate patches with a strip of
            // green between them.
            if (_partingGateNodeId == section.gateNodeId)
              Positioned(
                left: -AppSizes.paddingMedium,
                right: -AppSizes.paddingMedium,
                top: -AppSizes.spacingXLarge,
                bottom: 0,
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) => AnimatedBuilder(
                      animation: _cloudPartAnimation,
                      builder: (context, _) => _CloudsLayer(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        partProgress: _cloudPartAnimation.value,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: AppSizes.spacingLarge));
      widgets.add(
        LayoutBuilder(
          builder: (context, constraints) => _buildTrailPath(
            context,
            trail,
            localizer,
            constraints.maxWidth,
            nameFontSize,
            cloudHeight,
            startIndex: section.startIndex,
            endIndex: nextSection?.startIndex ?? bslTrail.length,
            showClouds: showClouds(nextSection),
          ),
        ),
      );
    }

    return widgets;
  }

  // Width reserved for each lockup (thumbnail + pill), as a fraction of the
  // available screen width — keeps the trail's proportions consistent
  // across phone and tablet sizes instead of a fixed pixel width. Clamped
  // so lockups don't become absurdly small on tiny screens or huge on very
  // wide ones.
  static const double _lockupWidthFraction = 0.4;
  static const double _minLockupWidth = 110;
  static const double _maxLockupWidth = 240;

  // Vertical space reserved per trail row — comfortably taller than a
  // lockup (~125 tall) so consecutive rows never touch.
  static const double _rowHeight = 150;

  // Distance from a lockup's top edge to its "anchor" point (the
  // thumbnail's centre) — where the connecting path lines meet it. Half of
  // _TrailThumbnail's fixed 96px diameter.
  static const double _anchorY = 48;

  // Extra clearance between the last visible row and where a still-locked
  // cloud band starts. The band's puffs deliberately bleed a little above
  // their own top edge so it doesn't read as a hard-edged panel — this
  // gap keeps that bleed landing on empty background instead of on the
  // last level's own card.
  static const double _cloudBandTopGap = 56;

  // Deterministic "randomised" horizontal placement (-1 = left edge, 1 =
  // right edge) for each node, indexed the same as [bslTrail]. A fixed
  // random seed keeps the meander stable across rebuilds while avoiding
  // the regular zigzag a hand-picked alternating pattern would produce.
  static final List<double> _positionX = _generatePositionX();

  static List<double> _generatePositionX() {
    final random = math.Random(11);
    final values = List<double>.filled(bslTrail.length, 0);
    var previous = 0.0;
    for (var i = 0; i < bslTrail.length; i++) {
      double x;
      do {
        x = -0.9 + random.nextDouble() * 1.8;
      } while ((x - previous).abs() < 0.4);
      values[i] = x;
      previous = x;
    }
    // The fork branches share a row, so pull them out to opposite edges
    // regardless of the values above — guarantees they can't overlap no
    // matter how narrow the screen is.
    final branchA = bslTrail.indexWhere((n) => n.id == 'card_matching_3');
    final branchB = bslTrail.indexWhere((n) => n.id == 'bubble_pop_3');
    values[branchA] = -1 + random.nextDouble() * 0.15;
    values[branchB] = 1 - random.nextDouble() * 0.15;
    return values;
  }

  // Row index (0-based) for each node — the fork branches share a row.
  static final List<int> _rowIndexOf = _generateRowIndex();

  static List<int> _generateRowIndex() {
    final rows = List<int>.filled(bslTrail.length, 0);
    var row = 0;
    var i = 0;
    while (i < bslTrail.length) {
      final node = bslTrail[i];
      rows[i] = row;
      if (node.nextNodeIds.length == 2) {
        rows[i + 1] = row + 1;
        rows[i + 2] = row + 1;
        i += 3;
        row += 2;
      } else {
        i += 1;
        row += 1;
      }
    }
    return rows;
  }

  /// Renders one contiguous slice of [bslTrail] — `[startIndex, endIndex)`
  /// — as its own self-contained path-with-clouds segment, so a later
  /// section (e.g. section 2) can be stacked underneath an earlier one
  /// without disturbing its row layout. [showClouds] controls whether this
  /// segment ends in a cloud band hiding its continuation; when false, the
  /// segment simply ends at its last node (used for section 1 once section
  /// 2 has been revealed below it).
  Widget _buildTrailPath(
    BuildContext context,
    TrailProvider trail,
    AppLocalizations localizer,
    double maxWidth,
    double nameFontSize,
    double cloudHeight, {
    required int startIndex,
    required int endIndex,
    required bool showClouds,
  }) {
    final lockupWidth = (maxWidth * _lockupWidthFraction).clamp(
      _minLockupWidth,
      _maxLockupWidth,
    );
    final baseRow = _rowIndexOf[startIndex];
    final totalRows =
        _rowIndexOf.sublist(startIndex, endIndex).reduce(math.max) -
        baseRow +
        1;
    final trailHeight = totalRows * _rowHeight;
    final totalHeight =
        trailHeight + (showClouds ? _cloudBandTopGap + cloudHeight : 0);
    final availableX = math.max(0.0, maxWidth - lockupWidth);

    double leftOf(int i) => (_positionX[i] + 1) / 2 * availableX;
    double topOf(int i) => (_rowIndexOf[i] - baseRow) * _rowHeight;

    // anchors/edges are keyed by LOCAL index (offset from startIndex), so
    // this segment's CustomPaint stays self-contained.
    final anchors = [
      for (var i = startIndex; i < endIndex; i++)
        Offset(leftOf(i) + lockupWidth / 2, topOf(i) + _anchorY),
    ];

    final edges = <(int, int)>[];
    for (var i = startIndex; i < endIndex; i++) {
      for (final nextId in bslTrail[i].nextNodeIds) {
        final j = bslTrail.indexWhere((n) => n.id == nextId);
        // Skip edges leaving this segment (e.g. section 1's last node
        // pointing into section 2) — the next section draws its own path.
        if (j >= startIndex && j < endIndex) {
          edges.add((i - startIndex, j - startIndex));
        }
      }
    }

    if (showClouds) {
      // Extend the path from the last node in this segment straight down
      // through the cloud band, so it visibly continues into (and
      // disappears under) the clouds rather than just stopping dead.
      final lastLocalIndex = anchors.length - 1;
      final intoClouds = anchors.length;
      anchors.add(Offset(anchors[lastLocalIndex].dx, totalHeight));
      edges.add((lastLocalIndex, intoClouds));
    }

    // AnimatedSize smooths the height change when the cloud band drops out
    // of totalHeight at the end of the parting animation (section 2's
    // content sliding up to close the gap the clouds leave behind) instead
    // of it snapping instantly.
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: maxWidth,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TrailPathPainter(anchors: anchors, edges: edges),
              ),
            ),
            for (var i = startIndex; i < endIndex; i++)
              Positioned(
                left: leftOf(i),
                top: topOf(i),
                // Fixed to lockupWidth and centered so the card's visual
                // centre always lands under its anchor point above — the
                // card's own intrinsic width (thumbnail vs. name pill)
                // would otherwise drift from lockupWidth and throw off the
                // path.
                width: lockupWidth,
                child: Center(
                  child: _trailCard(
                    context,
                    trail,
                    localizer,
                    bslTrail[i],
                    i + 1,
                    nameFontSize,
                  ),
                ),
              ),
            for (var i = startIndex; i < endIndex; i++)
              if (_lockedTapNodeId == bslTrail[i].id)
                _lockedTapBubble(
                  trail,
                  localizer,
                  bslTrail[i],
                  leftOf(i),
                  topOf(i),
                  lockupWidth,
                  maxWidth,
                ),
            // Negative left/right bleed the clouds out past the screen's
            // EdgeInsets.all(paddingMedium) content padding, so the clouds
            // reach the true screen edges instead of stopping at the
            // padded content width. Always fully closed (partProgress: 0)
            // — this band only ever hides a gate that hasn't unlocked yet,
            // so it never has anything to reveal or animate; the moment
            // its gate completes it disappears outright (see `showClouds`
            // in [_buildSectionWidgets]) and the newly-unlocked section's
            // own heading takes over as the thing the clouds part to
            // reveal.
            if (showClouds)
              Positioned(
                left: -AppSizes.paddingMedium,
                right: -AppSizes.paddingMedium,
                bottom: 0,
                height: cloudHeight,
                child: IgnorePointer(
                  child: _CloudsLayer(
                    width: maxWidth + AppSizes.paddingMedium * 2,
                    height: cloudHeight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Width the "why is this locked" bubble renders at — capped to the
  // segment's own width so it never demands more room than a narrow phone
  // screen has. Positioned above the tapped lockup, horizontally centred on
  // it but clamped so it can't run off either edge of the segment.
  static const double _lockedBubbleWidth = 220;

  // Vertical clearance above a lockup's top edge the bubble needs to clear
  // the thumbnail + name pill beneath it.
  static const double _lockedBubbleClearance = 96;

  Widget _lockedTapBubble(
    TrailProvider trail,
    AppLocalizations localizer,
    TrailNode node,
    double left,
    double top,
    double lockupWidth,
    double maxWidth,
  ) {
    final bubbleWidth = math.min(_lockedBubbleWidth, maxWidth);
    final anchorX = left + lockupWidth / 2;
    final bubbleLeft = (anchorX - bubbleWidth / 2).clamp(
      0.0,
      math.max(0.0, maxWidth - bubbleWidth),
    ).toDouble();
    return Positioned(
      left: bubbleLeft,
      top: top - _lockedBubbleClearance,
      child: IgnorePointer(
        child: SizedBox(
          width: bubbleWidth,
          child: SpeechBubble(
            text: _lockedTapMessage(trail, node, localizer),
            pointDirection: PointDirection.bottom,
          ),
        ),
      ),
    );
  }

  Widget _trailCard(
    BuildContext context,
    TrailProvider trail,
    AppLocalizations localizer,
    TrailNode node,
    int trailPosition,
    double nameFontSize,
  ) {
    final unlocked = trail.isNodeUnlocked(node);
    final name = node.nameKey != null
        ? localizer(node.nameKey!)
        : localizer('trail.level_name_fallback');

    return _TrailCard(
      name: name,
      trailPosition: trailPosition,
      nameFontSize: nameFontSize,
      thumbnailAsset: node.thumbnailAsset,
      locked: !unlocked,
      onTap: unlocked
          ? () {
              trail.enterTrail(node.id);
              Navigator.pushNamed(
                context,
                node.route,
                arguments: {
                  'locale': widget.locale,
                  'level': '${node.level}',
                  'trailNode': node.id,
                },
              );
            }
          : () => _handleLockedTap(node),
    );
  }
}

/// Paints the smooth, curved path connecting each trail node to its
/// successor(s) — including both branches at the fork and the merge that
/// follows. Each segment is a cubic Bezier with vertical tangents at both
/// ends, which keeps every curve smooth and, since several segments meet
/// vertically at shared nodes (the fork and merge points), keeps those
/// joins smooth too.
class _TrailPathPainter extends CustomPainter {
  final List<Offset> anchors;
  final List<(int, int)> edges;

  _TrailPathPainter({required this.anchors, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (final (fromIndex, toIndex) in edges) {
      final from = anchors[fromIndex];
      final to = anchors[toIndex];
      final halfDy = (to.dy - from.dy) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(
          from.dx,
          from.dy + halfDy,
          to.dx,
          to.dy - halfDy,
          to.dx,
          to.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPathPainter oldDelegate) => true;
}

/// Cloud band covering the trail's continuation past the last defined
/// level, redrawn after the parting clouds in *The Simpsons*' opening
/// title sequence: solid white cumulus puffs with a flat, cel-shaded
/// underside, densely overlapped so they cover the band on their own —
/// there is no solid-colour panel underneath any more.
///
/// [partProgress] animates the reveal that plays when the player returns
/// to the trail having just finished the section this band was hiding:
/// 0 is fully closed (the band's normal resting state); at 1 every puff
/// has slid off past whichever screen edge is nearest — left-half puffs
/// exit left, right-half puffs exit right — like the sky splitting open
/// down the middle. See [_LearnBslTrailScreenState._maybeStartCloudParting].
class _CloudsLayer extends StatelessWidget {
  final double width;
  final double height;
  final double partProgress;

  const _CloudsLayer({
    required this.width,
    required this.height,
    this.partProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CloudsPainter(partProgress: partProgress)),
    );
  }
}

/// Paints [_CloudsLayer]'s puffs: a dense scatter of small-to-medium
/// circles covering the whole band, plus a handful of larger three-bump
/// clusters on top (the classic flat-bottomed cartoon cloud silhouette)
/// so the band reads as individual clouds rather than an amorphous
/// scatter. Every circle gets a pale blue-grey "shade" circle drawn
/// just behind and below it, for the same flat cel-shaded look Simpsons
/// clouds use instead of a soft drop shadow.
class _CloudsPainter extends CustomPainter {
  final double partProgress;

  const _CloudsPainter({required this.partProgress});

  static const _cloudColor = Color(0xFFFFFFFF);
  static const _shadeColor = Color(0xFFD7E3EC);

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final fillPaint = Paint();
    final shadePaint = Paint();

    // Draws one puff, sliding it off toward whichever edge [isLeft] points
    // to and fading it out as [partProgress] goes from 0 to 1 — grouping
    // by the caller-supplied half (rather than each circle's own x)
    // keeps multi-circle clusters moving together instead of tearing.
    void drawPuff(Offset center, double radius, {required bool isLeft}) {
      final opacity = (1 - partProgress).clamp(0.0, 1.0);
      if (opacity <= 0) return;
      final dx = isLeft
          ? -partProgress * size.width
          : partProgress * size.width;
      final shifted = center.translate(dx, 0);
      shadePaint.color = _shadeColor.withValues(alpha: opacity);
      canvas.drawCircle(
        shifted.translate(0, radius * 0.3),
        radius * 0.85,
        shadePaint,
      );
      fillPaint.color = _cloudColor.withValues(alpha: opacity);
      canvas.drawCircle(shifted, radius, fillPaint);
    }

    // Jittered grid rather than a pure random scatter — this painter has
    // to fully cover two very different shapes (a short, wide band
    // trailing an as-yet-unbuilt path, and a much taller area sized to a
    // section's whole heading card, video placeholder included), and a
    // pure random scatter is only ever *statistically likely* to have no
    // gaps: fine for the former, but risks visible holes over the
    // latter's larger area. Placing one puff per grid cell — with a
    // radius comfortably bigger than the cell, so neighbours always
    // overlap even at maximum jitter — guarantees full coverage
    // regardless of canvas size, while the per-cell jitter still keeps it
    // reading as organic puffs rather than a mechanical tiling. The row
    // loop starts at 0 rather than -1 (unlike the column loop, which does
    // start a cell early to bleed puffs to the left edge) — row 0 alone
    // already comfortably covers y=0, and starting a row earlier would
    // only add unwanted bleed above the canvas's own top edge, which is
    // exactly what [_LearnBslTrailScreenState._cloudBandTopGap] gives
    // clearance for.
    final scatterRandom = math.Random(5);
    const cellSize = 32.0;
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      for (var col = -1; col < cols; col++) {
        final jitterX = (scatterRandom.nextDouble() - 0.5) * cellSize;
        final jitterY = (scatterRandom.nextDouble() - 0.5) * cellSize;
        final center = Offset(
          col * cellSize + cellSize / 2 + jitterX,
          row * cellSize + cellSize / 2 + jitterY,
        );
        final radius = cellSize * (1.0 + scatterRandom.nextDouble() * 0.5);
        drawPuff(center, radius, isLeft: center.dx < midX);
      }
    }

    // A handful of big, three-bump cloud silhouettes on top, spread
    // evenly across the width for a readable cloud shape.
    final heroRandom = math.Random(9);
    final heroCount = (size.width / 200).ceil().clamp(3, 8);
    for (var i = 0; i < heroCount; i++) {
      final cx =
          (i + 0.5) / heroCount * size.width +
          (heroRandom.nextDouble() - 0.5) * 50;
      final cy =
          size.height * 0.3 + heroRandom.nextDouble() * size.height * 0.35;
      final scale = 0.8 + heroRandom.nextDouble() * 0.5;
      final isLeft = cx < midX;
      drawPuff(
        Offset(cx - 48 * scale, cy + 12 * scale),
        38 * scale,
        isLeft: isLeft,
      );
      drawPuff(Offset(cx, cy - 16 * scale), 56 * scale, isLeft: isLeft);
      drawPuff(
        Offset(cx + 48 * scale, cy + 12 * scale),
        38 * scale,
        isLeft: isLeft,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter oldDelegate) =>
      oldDelegate.partProgress != partProgress;
}

/// A trail section's heading: title above a white card holding the
/// description and a video placeholder — used for both section 1
/// ("Finger Spelling") and section 2 ("BSL Numbers").
class _TrailSection extends StatelessWidget {
  final AppLocalizations localizer;
  final String titleKey;
  final String descriptionKey;

  const _TrailSection({
    required this.localizer,
    required this.titleKey,
    required this.descriptionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizer(titleKey),
          style: AppTheme.heading.copyWith(
            fontSize: AppSizes.fontSizeLarge,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        // Double-border "picture frame" — same technique as the animal
        // tile on the letter_bingo success page (bingo_celebration.dart's
        // _AnimalCard): a padded, bordered outer ring around a second
        // bordered inner container.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.headerBackgroundLight,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            border: Border.all(color: AppColors.headerBorderDark, width: 2),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(
                AppSizes.borderRadiusLarge - 4,
              ),
              border: Border.all(color: AppColors.headerBorderDark, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizer(descriptionKey),
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: AppSizes.fontSizeBody,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                const _VideoPlaceholder(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder for a section's explainer video — no video asset exists
/// yet, so this just reserves the space with the same picture-frame style
/// used elsewhere on the trail (see [_TrailThumbnail]).
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.headerBackground,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          border: Border.all(color: AppColors.headerBorderDark, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 56),
        ),
      ),
    );
  }
}

class _TrailCard extends StatelessWidget {
  final String name;
  final int trailPosition;
  final double nameFontSize;
  final String thumbnailAsset;
  final bool locked;
  final VoidCallback? onTap;

  const _TrailCard({
    required this.name,
    required this.trailPosition,
    required this.nameFontSize,
    required this.thumbnailAsset,
    required this.locked,
    required this.onTap,
  });

  // How far the pill rides up into the thumbnail's bottom edge.
  static const double _pillOverlap = 18;

  // Luminance-preserving greyscale matrix — desaturates the whole tile for
  // a locked lockup instead of dimming it with opacity.
  static const List<double> _desaturateMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrailThumbnail(asset: thumbnailAsset, locked: locked),
        Transform.translate(
          offset: const Offset(0, -_pillOverlap),
          child: _TrailNamePill(
            name: name,
            levelNumber: trailPosition,
            nameFontSize: nameFontSize,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: locked
          ? ColorFiltered(
              colorFilter: const ColorFilter.matrix(_desaturateMatrix),
              child: content,
            )
          : content,
    );
  }
}

/// Circular thumbnail image, framed with the same double-border "picture
/// frame" style as [GameHeaderBar]'s score circle.
class _TrailThumbnail extends StatelessWidget {
  final String asset;
  final bool locked;

  const _TrailThumbnail({required this.asset, required this.locked});

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.headerBackgroundLight,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.headerBorderDark, width: 2),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.headerBackground,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.headerBorderDark, width: 2),
          ),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.games,
                  size: AppSizes.iconXLarge,
                  color: Colors.white,
                ),
              ),
              if (locked)
                const Center(
                  child: Icon(Icons.lock, color: Colors.white, size: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Level name pill with a small circular badge — showing the level's
/// position on the trail — centred on the pill and straddling its bottom
/// edge. Both use the same double-border style as [GameHeaderBar].
class _TrailNamePill extends StatelessWidget {
  final String name;
  final int levelNumber;
  final double nameFontSize;

  const _TrailNamePill({
    required this.name,
    required this.levelNumber,
    required this.nameFontSize,
  });

  static const _borderSide = BorderSide(
    color: AppColors.headerBorderDark,
    width: 2,
  );

  static const double _badgeSize = 26;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.headerBackgroundLight,
            borderRadius: BorderRadius.circular(20),
            border: const Border.fromBorderSide(_borderSide),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.circular(16),
              border: const Border.fromBorderSide(_borderSide),
            ),
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Centred horizontally on the pill, straddling its bottom edge
        // with only a 25% overlap (75% of the badge hangs below the pill).
        Positioned(
          left: 0,
          right: 0,
          bottom: -_badgeSize * 0.75,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(minWidth: _badgeSize),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                // Large enough to always exceed half the badge's height,
                // so the short ends read as fully circular however wide
                // the number makes it.
                borderRadius: BorderRadius.circular(100),
                color: AppColors.headerBackgroundLight,
                border: const Border.fromBorderSide(_borderSide),
              ),
              // No Center here — with a bounded (but non-tight) max width
              // from the Positioned/Center chain above, Center expands to
              // fill that width instead of shrink-wrapping, which would
              // stop this container hugging the number.
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.headerBackground,
                  border: const Border.fromBorderSide(_borderSide),
                ),
                child: Text(
                  '$levelNumber',
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
