import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/widgets/game_header_bar.dart';
import '../../../shared/widgets/game_success_overlay.dart';
import '../game/school_explorer_game.dart';
import '../models/school_scene.dart';
import '../providers/school_explorer_provider.dart';

/// School Explorer: an isometric 2.5D UK primary school (classroom, hall,
/// playground, canteen) for getting to know the rooms and what's in them.
///
/// Explore mode — tap anything to hear its name. Find mode — "Can you find
/// the...?" rounds, scored per area.
///
/// The [SchoolExplorerProvider] is provided by the route in routes.dart.
class SchoolExplorerScreen extends StatefulWidget {
  const SchoolExplorerScreen({super.key});

  @override
  State<SchoolExplorerScreen> createState() => _SchoolExplorerScreenState();
}

class _SchoolExplorerScreenState extends State<SchoolExplorerScreen> {
  late final SchoolExplorerGame _game;

  static const double _bannerHeight = 56;
  static const double _bottomBarHeight = 132;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SchoolExplorerProvider>();
    _game = SchoolExplorerGame(provider: provider);
    AudioService.playInstructionClip(
      SchoolExplorerProvider.audioGameId,
      'intro',
      locale: provider.locale,
    );
  }

  @override
  void dispose() {
    AudioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolExplorerProvider>();
    final localizer = AppLocalizations(locale: provider.locale);
    final padding = MediaQuery.of(context).padding;

    // Tell the game which parts of the screen the Flutter chrome covers,
    // so the scene is fitted into the clear band between them.
    _game.topInset = padding.top + 88 + _bannerHeight;
    _game.bottomInset = padding.bottom + _bottomBarHeight;

    final isFind = provider.mode == SchoolExplorerMode.find;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          SafeArea(
            child: Column(
              children: [
                GameHeaderBar(
                  onBack: () => Navigator.of(context).pop(),
                  showScore: isFind,
                  scoreLabel: localizer('general.score'),
                  scoreValue: '${provider.score}',
                  showLevel: false,
                  centerContent: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        localizer(provider.area.titleKey),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _bannerHeight,
                  child: Center(
                    child: isFind
                        ? _FindBanner(provider: provider, localizer: localizer)
                        : _ExploreBanner(
                            provider: provider,
                            localizer: localizer,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _BottomBar(provider: provider, localizer: localizer),
            ),
          ),
          // Zoom controls, alongside pinch — big targets for small hands,
          // and the only way to zoom with a mouse or trackpad.
          Positioned(
            right: 12,
            top: padding.top + 88 + _bannerHeight + 8,
            child: _ZoomControls(game: _game, localizer: localizer),
          ),
          if (provider.isFindComplete)
            Positioned.fill(
              child: GameSuccessOverlay(
                gameId: SchoolExplorerProvider.audioGameId,
                locale: provider.locale,
                scoreStyle: SuccessScoreStyle.custom,
                score: provider.score,
                customScoreLine: localizer('school_explorer.success_summary')
                    .replaceAll('{score}', '${provider.score}')
                    .replaceAll('{total}', '${provider.totalRounds}'),
                showPersonalBest: provider.lastResult != null,
                isNewPersonalBest:
                    provider.lastResult?.isNewPersonalBest ?? false,
                personalBest: provider.lastResult?.personalBest,
                onPlayAgain: provider.playAgain,
                onChangeLevel: () =>
                    provider.setMode(SchoolExplorerMode.explore),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Banners ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final Color colour;
  final Widget child;
  const _Pill({required this.colour, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ExploreBanner extends StatelessWidget {
  final SchoolExplorerProvider provider;
  final AppLocalizations localizer;
  const _ExploreBanner({required this.provider, required this.localizer});

  @override
  Widget build(BuildContext context) {
    final found = provider.discoveredCount(provider.area);
    final total = provider.totalToDiscover(provider.area);
    return _Pill(
      colour: const Color(0xFF3B6231),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              localizer('school_explorer.tap_hint'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.star, color: Color(0xFFFFC928), size: 22),
          const SizedBox(width: 4),
          Text(
            '$found / $total',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FindBanner extends StatelessWidget {
  final SchoolExplorerProvider provider;
  final AppLocalizations localizer;
  const _FindBanner({required this.provider, required this.localizer});

  @override
  Widget build(BuildContext context) {
    final target = provider.targetNameKey;
    if (target == null) return const SizedBox.shrink();
    // Whole question per item (not a template) so Welsh can contract the
    // article properly, e.g. "Ble mae'r bwrdd gwyn?".
    final text = localizer('$target.find');
    return _Pill(
      colour: const Color(0xFF1565C0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${provider.roundNumber}/${provider.totalRounds}',
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
          IconButton(
            tooltip: localizer('school_explorer.listen'),
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: provider.repeatPrompt,
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar: mode toggle + school map ────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final SchoolExplorerProvider provider;
  final AppLocalizations localizer;
  const _BottomBar({required this.provider, required this.localizer});

  static const Map<SchoolArea, IconData> _icons = {
    SchoolArea.classroom: Icons.menu_book,
    SchoolArea.hall: Icons.theater_comedy,
    SchoolArea.playground: Icons.park,
    SchoolArea.canteen: Icons.restaurant,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<SchoolExplorerMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFFDA16E1),
              selectedForegroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            segments: [
              ButtonSegment(
                value: SchoolExplorerMode.explore,
                icon: const Icon(Icons.touch_app),
                label: Text(localizer('school_explorer.mode.explore')),
              ),
              ButtonSegment(
                value: SchoolExplorerMode.find,
                icon: const Icon(Icons.search),
                label: Text(localizer('school_explorer.mode.find')),
              ),
            ],
            selected: {provider.mode},
            onSelectionChanged: (s) => provider.setMode(s.first),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final area in SchoolArea.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _AreaButton(
                      icon: _icons[area]!,
                      label: localizer(area.titleKey),
                      selected: provider.area == area,
                      onTap: () => provider.goTo(area),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AreaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AreaButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : const Color(0xFF5A2A82);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? const Color(0xFF5A2A82) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: selected ? 3 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 24),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Zoom controls ───────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final SchoolExplorerGame game;
  final AppLocalizations localizer;
  const _ZoomControls({required this.game, required this.localizer});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: Icons.add,
          tooltip: localizer('school_explorer.zoom_in'),
          onPressed: () => game.zoomBy(1.35),
        ),
        const SizedBox(height: 10),
        _RoundButton(
          icon: Icons.remove,
          tooltip: localizer('school_explorer.zoom_out'),
          onPressed: () => game.zoomBy(1 / 1.35),
        ),
        const SizedBox(height: 10),
        _RoundButton(
          icon: Icons.fit_screen,
          tooltip: localizer('school_explorer.zoom_fit'),
          onPressed: game.resetView,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF5A2A82), width: 3),
        ),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, size: 32, color: const Color(0xFF5A2A82)),
          ),
        ),
      ),
    );
  }
}
