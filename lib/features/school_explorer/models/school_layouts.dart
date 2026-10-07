import 'dart:ui';

import 'school_scene.dart';

/// Hand-built layouts for the four School Explorer areas, loosely modelled
/// on a typical UK primary school: a classroom off the school hall, with
/// the canteen and the playground reached through the hall.
///
/// Back walls sit on the `x == 0` and `y == 0` planes, so wall-mounted
/// objects (whiteboard, clock, doors...) are thin boxes against them.
class SchoolLayouts {
  SchoolLayouts._();

  static SchoolScene forArea(SchoolArea area) => switch (area) {
    SchoolArea.classroom => classroom,
    SchoolArea.hall => hall,
    SchoolArea.playground => playground,
    SchoolArea.canteen => canteen,
  };

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _wood = Color(0xFFC8955C);
  static const _darkWood = Color(0xFF8D6038);
  static const _white = Color(0xFFF8F8F4);
  static const _grey = Color(0xFF9EA4AA);
  static const _steel = Color(0xFFC3CBD2);
  static const _glass = Color(0xFFAEDCF2);
  static const _doorBlue = Color(0xFF3F74B5);
  static const _red = Color(0xFFE0524B);
  static const _blue = Color(0xFF4A90D9);
  static const _green = Color(0xFF5DB85C);
  static const _yellow = Color(0xFFF2C94C);
  static const _purple = Color(0xFF9B6CC9);
  static const _orange = Color(0xFFF2994A);
  static const _cork = Color(0xFFD9A869);
  static const _chalk = Color(0xFF2F5D46);
  static const _pianoBlack = Color(0xFF2B2B2B);

  static const _chairColours = [_red, _blue, _green, _yellow];

  // ── Part builders ─────────────────────────────────────────────────────────

  /// A table top on four legs.
  static List<IsoPart> _table(
    double x,
    double y,
    double w,
    double d, {
    double h = 0.6,
    Color top = _wood,
    Color legs = _darkWood,
  }) {
    const leg = 0.1;
    return [
      IsoPart(x + 0.05, y + 0.05, 0, leg, leg, h, legs),
      IsoPart(x + w - 0.15, y + 0.05, 0, leg, leg, h, legs),
      IsoPart(x + 0.05, y + d - 0.15, 0, leg, leg, h, legs),
      IsoPart(x + w - 0.15, y + d - 0.15, 0, leg, leg, h, legs),
      IsoPart(x, y, h, w, d, 0.08, top),
    ];
  }

  /// A child-size chair. [backAtY] puts the backrest on the far (low-y)
  /// side; otherwise it's on the far (low-x) side.
  static List<IsoPart> _chair(
    double x,
    double y,
    Color colour, {
    bool backAtY = true,
  }) {
    return [
      IsoPart(x + 0.05, y + 0.05, 0, 0.35, 0.35, 0.35, _grey),
      IsoPart(x, y, 0.35, 0.45, 0.45, 0.07, colour),
      if (backAtY)
        IsoPart(x, y, 0.42, 0.45, 0.07, 0.4, colour)
      else
        IsoPart(x, y, 0.42, 0.07, 0.45, 0.4, colour),
    ];
  }

  /// A pupils' table with chairs along both long (x) sides.
  static List<IsoPart> _tableGroup(double x, double y, int colourOffset) {
    return [
      for (var i = 0; i < 3; i++)
        ..._chair(
          x + 0.2 + i * 0.75,
          y - 0.45,
          _chairColours[(i + colourOffset) % 4],
        ),
      ..._table(x, y, 2.4, 1.2),
      for (var i = 0; i < 3; i++)
        ..._chair(
          x + 0.2 + i * 0.75,
          y + 1.25,
          _chairColours[(i + colourOffset + 2) % 4],
        ),
    ];
  }

  /// A door against the y == 0 wall.
  static List<IsoPart> _doorOnBackWall(double x, {Color colour = _doorBlue}) =>
      [
        IsoPart(x - 0.1, 0, 0, 1.4, 0.08, 2.35, _white),
        IsoPart(x, 0, 0, 1.2, 0.14, 2.2, colour),
        IsoPart(x + 0.2, 0.14, 1.4, 0.3, 0.05, 0.5, _glass),
        IsoPart(x + 1.0, 0.14, 1.0, 0.1, 0.06, 0.06, _yellow),
      ];

  /// A door against the x == 0 wall.
  static List<IsoPart> _doorOnSideWall(double y, {Color colour = _doorBlue}) =>
      [
        IsoPart(0, y - 0.1, 0, 0.08, 1.4, 2.35, _white),
        IsoPart(0, y, 0, 0.14, 1.2, 2.2, colour),
        IsoPart(0.14, y + 0.2, 1.4, 0.05, 0.3, 0.5, _glass),
        IsoPart(0.14, y + 1.0, 1.0, 0.06, 0.1, 0.06, _yellow),
      ];

  static List<IsoPart> _windowOnSideWall(double y, double length) => [
    IsoPart(0, y - 0.08, 1.05, 0.1, length + 0.16, 1.6, _white),
    IsoPart(0, y, 1.15, 0.14, length, 1.4, _glass, decal: IsoDecal.window),
  ];

  static List<IsoPart> _clockOnBackWall(double x, double z) => [
    IsoPart(x, 0, z, 0.6, 0.1, 0.6, _white, decal: IsoDecal.clock),
  ];

  /// A tree on a 1×1 footprint at ([x], [y]). The trunk is a block; the
  /// leafy crown is hand-drawn by ObjectDetails' tree art painter inside
  /// the invisible 'canopy' volume (which also makes it tappable).
  static List<IsoPart> _tree(double x, double y) => [
    IsoPart(x + 0.36, y + 0.36, 0, 0.28, 0.28, 1.5, _darkWood, id: 'trunk'),
    IsoPart(
      x - 0.3,
      y - 0.3,
      1.1,
      1.6,
      1.6,
      2.0,
      const Color(0x00000000),
      id: 'canopy',
      visible: false,
    ),
  ];

  static List<IsoPart> _bench(double x, double y, double w, Color colour) => [
    IsoPart(x + 0.1, y + 0.05, 0, 0.12, 0.3, 0.4, _darkWood),
    IsoPart(x + w - 0.22, y + 0.05, 0, 0.12, 0.3, 0.4, _darkWood),
    IsoPart(x, y, 0.4, w, 0.4, 0.08, colour),
  ];

  // ── Classroom ─────────────────────────────────────────────────────────────

  static final classroom = SchoolScene(
    area: SchoolArea.classroom,
    width: 10,
    depth: 8,
    floorColor: const Color(0xFFBFD7EA),
    floorLineColor: const Color(0xFFA9C5DC),
    wallColor: const Color(0xFFF6EBCF),
    objects: [
      SchoolObject(
        id: 'display_board',
        nameKey: 'school_explorer.object.display_board',
        parts: const [
          IsoPart(0.5, 0, 1.2, 2.2, 0.08, 1.3, _cork, decal: IsoDecal.pictures),
        ],
      ),
      SchoolObject(
        id: 'whiteboard',
        nameKey: 'school_explorer.object.whiteboard',
        parts: const [
          IsoPart(3, 0, 1.1, 3.6, 0.1, 1.6, _grey),
          IsoPart(3.1, 0, 1.2, 3.4, 0.14, 1.4, _white, decal: IsoDecal.writing),
        ],
      ),
      SchoolObject(
        id: 'clock',
        nameKey: 'school_explorer.object.clock',
        parts: _clockOnBackWall(7.2, 2.3),
      ),
      SchoolObject(
        id: 'door_hall',
        nameKey: 'school_explorer.object.door_to_hall',
        spellKey: 'school_explorer.object.door',
        leadsTo: SchoolArea.hall,
        parts: _doorOnBackWall(8.3),
      ),
      SchoolObject(
        id: 'window',
        nameKey: 'school_explorer.object.window',
        parts: _windowOnSideWall(1.2, 2.6),
      ),
      SchoolObject(
        id: 'plant',
        nameKey: 'school_explorer.object.plant',
        // A terracotta pot of soil; the leaves are hand-drawn by
        // ObjectDetails' plant art painter, anchored to the 'soil' part.
        // 'foliage' is the invisible space they fill, so tapping the
        // leaves selects the plant and it sorts correctly with the window.
        parts: const [
          IsoPart(
            0.22,
            2.22,
            0,
            0.46,
            0.46,
            0.36,
            Color(0xFFD9774A),
            id: 'pot',
          ),
          IsoPart(
            0.17,
            2.17,
            0.32,
            0.56,
            0.56,
            0.12,
            Color(0xFFC4643A),
            id: 'rim',
          ),
          IsoPart(
            0.22,
            2.22,
            0.44,
            0.46,
            0.46,
            0,
            Color(0xFF6B4A2E),
            id: 'soil',
          ),
          IsoPart(
            0.02,
            1.9,
            0.44,
            0.9,
            1.1,
            0.85,
            Color(0x00000000),
            id: 'foliage',
            visible: false,
          ),
        ],
      ),
      SchoolObject(
        id: 'coat_pegs',
        nameKey: 'school_explorer.object.coat_pegs',
        parts: const [
          IsoPart(0, 4.1, 1.5, 0.1, 1.2, 0.15, _darkWood),
          IsoPart(0, 4.15, 0.8, 0.3, 0.3, 0.7, _red),
          IsoPart(0, 4.55, 0.8, 0.3, 0.3, 0.7, _blue),
          IsoPart(0, 4.95, 0.9, 0.3, 0.3, 0.6, _yellow),
        ],
      ),
      SchoolObject(
        id: 'bookshelf',
        nameKey: 'school_explorer.object.bookshelf',
        parts: const [
          IsoPart(0, 5.6, 0, 0.6, 2.0, 1.6, _wood, decal: IsoDecal.books),
        ],
      ),
      SchoolObject(
        id: 'reading_corner',
        nameKey: 'school_explorer.object.reading_corner',
        parts: const [
          IsoPart(0.9, 5.6, 0, 2.3, 2.2, 0, _purple, decal: IsoDecal.lines),
        ],
      ),
      SchoolObject(
        id: 'teacher_desk',
        nameKey: 'school_explorer.object.teacher_desk',
        parts: const [
          IsoPart(3.6, 1.4, 0, 1.8, 0.9, 0.72, _darkWood),
          IsoPart(3.5, 1.3, 0.72, 2.0, 1.1, 0.1, _wood),
        ],
      ),
      SchoolObject(
        id: 'computer',
        nameKey: 'school_explorer.object.computer',
        parts: const [
          IsoPart(4.8, 1.55, 0.82, 0.3, 0.25, 0.12, _grey),
          IsoPart(
            4.55,
            1.5,
            0.94,
            0.8,
            0.12,
            0.55,
            Color(0xFF34495E),
            decal: IsoDecal.screen,
          ),
        ],
      ),
      SchoolObject(
        id: 'table_a',
        nameKey: 'school_explorer.object.table',
        parts: _tableGroup(2.0, 4.0, 0),
      ),
      SchoolObject(
        id: 'table_b',
        nameKey: 'school_explorer.object.table',
        parts: _tableGroup(5.6, 4.0, 1),
      ),
      SchoolObject(
        id: 'bin',
        nameKey: 'school_explorer.object.bin',
        parts: const [IsoPart(9.2, 2.8, 0, 0.45, 0.45, 0.6, _green)],
      ),
      SchoolObject(
        id: 'trays',
        nameKey: 'school_explorer.object.trays',
        parts: const [
          IsoPart(7.6, 7.0, 0, 1.8, 0.6, 0.95, _white),
          IsoPart(9.4, 7.02, 0.1, 0.02, 0.56, 0.25, _red),
          IsoPart(9.4, 7.02, 0.4, 0.02, 0.56, 0.25, _blue),
          IsoPart(9.4, 7.02, 0.68, 0.02, 0.56, 0.2, _yellow),
          IsoPart(7.65, 7.6, 0.1, 0.5, 0.02, 0.25, _green),
          IsoPart(8.25, 7.6, 0.1, 0.5, 0.02, 0.25, _orange),
          IsoPart(8.85, 7.6, 0.1, 0.5, 0.02, 0.25, _purple),
          IsoPart(7.65, 7.6, 0.4, 0.5, 0.02, 0.25, _blue),
          IsoPart(8.25, 7.6, 0.4, 0.5, 0.02, 0.25, _red),
          IsoPart(8.85, 7.6, 0.4, 0.5, 0.02, 0.25, _yellow),
        ],
      ),
    ],
  );

  // ── School hall ───────────────────────────────────────────────────────────

  static final hall = SchoolScene(
    area: SchoolArea.hall,
    width: 12,
    depth: 10,
    floorColor: const Color(0xFFD9B77E),
    floorLineColor: const Color(0xFFC9A46A),
    wallColor: const Color(0xFFE8EEF3),
    wallHeight: 3.6,
    objects: [
      SchoolObject(
        id: 'door_classroom',
        nameKey: 'school_explorer.object.door_to_classroom',
        spellKey: 'school_explorer.object.door',
        leadsTo: SchoolArea.classroom,
        parts: _doorOnBackWall(0.5),
      ),
      SchoolObject(
        id: 'screen',
        nameKey: 'school_explorer.object.screen',
        parts: const [
          IsoPart(3.9, 0, 1.6, 3.2, 0.08, 1.6, _white, decal: IsoDecal.screen),
        ],
      ),
      SchoolObject(
        id: 'stage',
        nameKey: 'school_explorer.object.stage',
        parts: const [
          IsoPart(2.2, 0, 0.8, 1.0, 0.25, 2.6, _red),
          IsoPart(7.8, 0, 0.8, 1.0, 0.25, 2.6, _red),
          IsoPart(2.2, 0, 0, 6.6, 2.2, 0.8, _darkWood),
          IsoPart(2.2, 0, 0.8, 6.6, 2.2, 0, _wood, decal: IsoDecal.lines),
          IsoPart(4.6, 2.2, 0, 1.6, 0.4, 0.27, _darkWood),
          IsoPart(4.6, 2.2, 0.27, 1.6, 0.2, 0.27, _darkWood),
        ],
      ),
      SchoolObject(
        id: 'clock',
        nameKey: 'school_explorer.object.clock',
        parts: _clockOnBackWall(9.0, 2.6),
      ),
      SchoolObject(
        id: 'door_canteen',
        nameKey: 'school_explorer.object.door_to_canteen',
        spellKey: 'school_explorer.object.door',
        leadsTo: SchoolArea.canteen,
        parts: _doorOnBackWall(10.2, colour: _green),
      ),
      SchoolObject(
        id: 'wall_bars',
        nameKey: 'school_explorer.object.wall_bars',
        parts: const [
          IsoPart(0, 1.4, 0, 0.3, 2.6, 2.8, _wood, decal: IsoDecal.lines),
        ],
      ),
      SchoolObject(
        id: 'window',
        nameKey: 'school_explorer.object.window',
        parts: _windowOnSideWall(4.6, 1.8),
      ),
      SchoolObject(
        id: 'stacked_chairs',
        nameKey: 'school_explorer.object.stacked_chairs',
        parts: [
          for (var i = 0; i < 6; i++)
            IsoPart(0.4, 6.8, i * 0.28, 0.6, 0.6, 0.26, _chairColours[i % 4]),
        ],
      ),
      SchoolObject(
        id: 'door_playground',
        nameKey: 'school_explorer.object.door_to_playground',
        spellKey: 'school_explorer.object.door',
        leadsTo: SchoolArea.playground,
        parts: _doorOnSideWall(8.2, colour: _orange),
      ),
      SchoolObject(
        id: 'piano',
        nameKey: 'school_explorer.object.piano',
        // An upright piano with its stool. Named parts: ObjectDetails
        // paints the close-up detail (sheet music, key lines, nameplate,
        // floating notes...) relative to these.
        parts: [
          const IsoPart(10.0, 3.4, 0, 1.6, 0.55, 1.3, _pianoBlack, id: 'case'),
          const IsoPart(10.02, 4.1, 0, 0.1, 0.12, 0.62, _pianoBlack),
          const IsoPart(11.48, 4.1, 0, 0.1, 0.12, 0.62, _pianoBlack),
          const IsoPart(
            10.0,
            3.95,
            0.62,
            1.6,
            0.32,
            0.1,
            _pianoBlack,
            id: 'keybed',
          ),
          const IsoPart(10.0, 3.95, 0.72, 0.1, 0.32, 0.08, _pianoBlack),
          const IsoPart(11.5, 3.95, 0.72, 0.1, 0.32, 0.08, _pianoBlack),
          const IsoPart(
            10.1,
            3.97,
            0.72,
            1.4,
            0.26,
            0.03,
            Color(0xFFFFFBEF),
            decal: IsoDecal.pianoKeys,
            id: 'keys',
          ),
          const IsoPart(
            10.25,
            3.95,
            0.8,
            1.1,
            0.04,
            0.34,
            Color(0xFF3A3A3A),
            id: 'stand',
          ),
          const IsoPart(10.4, 3.99, 0.84, 0.8, 0.02, 0.36, _white, id: 'music'),
          for (var i = 0; i < 3; i++)
            IsoPart(
              10.62 + i * 0.14,
              3.95,
              0.04,
              0.08,
              0.16,
              0.04,
              const Color(0xFFE0B040),
              id: 'pedal$i',
            ),
          // Stool.
          const IsoPart(10.42, 4.65, 0, 0.08, 0.08, 0.45, _pianoBlack),
          const IsoPart(11.12, 4.65, 0, 0.08, 0.08, 0.45, _pianoBlack),
          const IsoPart(10.42, 4.9, 0, 0.08, 0.08, 0.45, _pianoBlack),
          const IsoPart(11.12, 4.9, 0, 0.08, 0.08, 0.45, _pianoBlack),
          const IsoPart(
            10.35,
            4.6,
            0.45,
            0.92,
            0.42,
            0.12,
            Color(0xFFB23A48),
            id: 'stool',
          ),
        ],
      ),
      SchoolObject(
        id: 'bench_a',
        nameKey: 'school_explorer.object.bench',
        parts: _bench(3.0, 4.8, 4.2, _blue),
      ),
      SchoolObject(
        id: 'mats',
        nameKey: 'school_explorer.object.mats',
        parts: const [
          IsoPart(2.4, 6.8, 0, 1.6, 2.4, 0.12, _blue),
          IsoPart(4.3, 6.8, 0, 1.6, 2.4, 0.12, _blue),
        ],
      ),
      SchoolObject(
        id: 'bench_b',
        nameKey: 'school_explorer.object.bench',
        parts: _bench(7.0, 7.4, 3.6, _blue),
      ),
    ],
  );

  // ── Playground ────────────────────────────────────────────────────────────

  static final playground = SchoolScene(
    area: SchoolArea.playground,
    width: 14,
    depth: 12,
    floorColor: const Color(0xFF8E959C),
    floorLineColor: const Color(0xFF858B91),
    hasWalls: false,
    objects: [
      SchoolObject(
        id: 'school_building',
        nameKey: 'school_explorer.object.school_building',
        parts: const [
          IsoPart(
            0,
            -1.2,
            0,
            14,
            1.2,
            3.4,
            Color(0xFFB5563E),
            decal: IsoDecal.window,
          ),
          IsoPart(0, -1.2, 3.4, 14, 1.2, 0.3, Color(0xFF5C5C5C)),
        ],
      ),
      SchoolObject(
        id: 'door_hall',
        nameKey: 'school_explorer.object.door_to_hall',
        spellKey: 'school_explorer.object.door',
        leadsTo: SchoolArea.hall,
        parts: const [
          IsoPart(6.2, 0, 0, 1.6, 0.1, 2.5, _white),
          IsoPart(6.3, 0, 0, 1.4, 0.16, 2.35, _orange),
          IsoPart(6.95, 0.16, 1.0, 0.1, 0.05, 0.1, _yellow),
        ],
      ),
      SchoolObject(
        id: 'grass',
        nameKey: 'school_explorer.object.grass',
        parts: const [
          IsoPart(
            8.5,
            4.0,
            0,
            5.5,
            8.0,
            0,
            Color(0xFF7CC26B),
            decal: IsoDecal.lines,
          ),
        ],
      ),
      SchoolObject(
        id: 'hopscotch',
        nameKey: 'school_explorer.object.hopscotch',
        parts: const [
          IsoPart(
            1.8,
            5.0,
            0,
            1.2,
            4.4,
            0,
            Color(0xFF8E959C),
            decal: IsoDecal.hopscotch,
          ),
        ],
      ),
      SchoolObject(
        id: 'bench',
        nameKey: 'school_explorer.object.bench',
        parts: _bench(0.6, 1.2, 2.0, _wood),
      ),
      SchoolObject(
        id: 'garden',
        nameKey: 'school_explorer.object.garden',
        // A wooden raised bed of soil; the flowers and vegetables are
        // hand-drawn by ObjectDetails' garden art painter, anchored to
        // 'soil', inside the invisible 'plants' volume.
        parts: const [
          IsoPart(0.4, 2.6, 0, 2.4, 1.0, 0.45, _wood, id: 'bed'),
          IsoPart(
            0.48,
            2.68,
            0.45,
            2.24,
            0.84,
            0,
            Color(0xFF6B4A2E),
            id: 'soil',
          ),
          IsoPart(
            0.45,
            2.65,
            0.45,
            2.3,
            0.9,
            0.8,
            Color(0x00000000),
            id: 'plants',
            visible: false,
          ),
        ],
      ),
      SchoolObject(
        id: 'climbing_frame',
        nameKey: 'school_explorer.object.climbing_frame',
        parts: const [
          IsoPart(3.8, 2.2, 0, 0.15, 0.15, 2.2, _red),
          IsoPart(6.0, 2.2, 0, 0.15, 0.15, 2.2, _red),
          IsoPart(3.8, 4.0, 0, 0.15, 0.15, 2.2, _red),
          IsoPart(6.0, 4.0, 0, 0.15, 0.15, 2.2, _red),
          IsoPart(3.8, 2.2, 1.2, 2.35, 1.95, 0.12, _yellow),
          IsoPart(3.8, 2.2, 2.2, 2.35, 1.95, 0.25, _blue),
          IsoPart(4.4, 4.15, 0.0, 0.1, 0.1, 1.2, _green),
          IsoPart(5.2, 4.15, 0.0, 0.1, 0.1, 1.2, _green),
          IsoPart(4.4, 4.15, 0.3, 0.9, 0.08, 0.06, _green),
          IsoPart(4.4, 4.15, 0.65, 0.9, 0.08, 0.06, _green),
          IsoPart(4.4, 4.15, 1.0, 0.9, 0.08, 0.06, _green),
        ],
      ),
      SchoolObject(
        id: 'slide',
        nameKey: 'school_explorer.object.slide',
        // A smooth diagonal chute from the climbing frame's platform down
        // to the ground, hand-drawn by ObjectDetails' slide art painter.
        // 'chute' is the invisible volume it fills: the chute's top is at
        // this box's top-left (x, top), running down along +x to its far end.
        parts: const [
          IsoPart(
            6.15,
            2.8,
            0,
            2.55,
            0.6,
            1.45,
            Color(0x00000000),
            id: 'chute',
            visible: false,
          ),
        ],
      ),
      SchoolObject(
        id: 'tree_a',
        nameKey: 'school_explorer.object.tree',
        parts: _tree(12.4, 1.2),
      ),
      SchoolObject(
        id: 'football_goal',
        nameKey: 'school_explorer.object.football_goal',
        parts: const [
          IsoPart(12.9, 6.6, 0, 0.15, 0.15, 1.3, _white),
          IsoPart(12.9, 9.0, 0, 0.15, 0.15, 1.3, _white),
          IsoPart(12.9, 6.6, 1.3, 0.15, 2.55, 0.15, _white),
          IsoPart(
            13.5,
            6.6,
            0,
            0.1,
            2.55,
            1.3,
            Color(0x55FFFFFF),
            decal: IsoDecal.window,
          ),
        ],
      ),
      SchoolObject(
        id: 'picnic_table',
        nameKey: 'school_explorer.object.picnic_table',
        parts: [
          ..._bench(4.0, 7.6, 2.0, _wood),
          ..._table(4.0, 8.1, 2.0, 1.0, h: 0.75),
          ..._bench(4.0, 9.2, 2.0, _wood),
        ],
      ),
      SchoolObject(
        id: 'tree_b',
        nameKey: 'school_explorer.object.tree',
        parts: _tree(0.6, 10.4),
      ),
    ],
  );

  // ── Canteen ───────────────────────────────────────────────────────────────

  static final canteen = SchoolScene(
    area: SchoolArea.canteen,
    width: 10,
    depth: 8,
    floorColor: const Color(0xFFE9E1D3),
    floorLineColor: const Color(0xFFD6CCBA),
    wallColor: const Color(0xFFDDF0E4),
    objects: [
      SchoolObject(
        id: 'window',
        nameKey: 'school_explorer.object.window',
        parts: _windowOnSideWall(1.0, 1.6),
      ),
      SchoolObject(
        id: 'trays',
        nameKey: 'school_explorer.object.lunch_trays',
        parts: [
          for (var i = 0; i < 8; i++)
            IsoPart(
              0.3,
              0.4,
              i * 0.11,
              0.7,
              0.7,
              0.08,
              i.isEven ? _blue : _green,
            ),
        ],
      ),
      SchoolObject(
        id: 'serving_counter',
        nameKey: 'school_explorer.object.serving_counter',
        parts: const [
          IsoPart(1.2, 0.2, 0, 4.6, 1.1, 0.95, _steel),
          IsoPart(1.2, 0.2, 0.95, 4.6, 1.1, 0.05, _grey, decal: IsoDecal.food),
          IsoPart(1.2, 0.6, 1.0, 4.6, 0.06, 0.5, Color(0x88D9F1FF)),
        ],
      ),
      SchoolObject(
        id: 'menu',
        nameKey: 'school_explorer.object.menu',
        parts: const [
          IsoPart(6.3, 0, 1.4, 1.6, 0.08, 1.1, _chalk, decal: IsoDecal.writing),
        ],
      ),
      SchoolObject(
        id: 'fruit_bowl',
        nameKey: 'school_explorer.object.fruit_bowl',
        // A small table; the round bowl and the fruit in it are
        // hand-drawn by ObjectDetails' fruit bowl art painter, centred on
        // the table top, inside the invisible 'fruit' volume.
        parts: const [
          IsoPart(6.3, 0.5, 0, 1.2, 0.8, 0.9, _wood, id: 'table'),
          IsoPart(
            6.45,
            0.5,
            0.9,
            0.9,
            0.8,
            0.5,
            Color(0x00000000),
            id: 'fruit',
            visible: false,
          ),
        ],
      ),
      SchoolObject(
        id: 'door_hall',
        nameKey: 'school_explorer.object.door_to_hall',
        spellKey: 'school_explorer.object.door',
        leadsTo: SchoolArea.hall,
        parts: _doorOnBackWall(8.4, colour: _green),
      ),
      SchoolObject(
        id: 'water_fountain',
        nameKey: 'school_explorer.object.water_fountain',
        // Named parts: ObjectDetails paints the close-up detail (bowl,
        // water arc, button icon...) relative to these.
        parts: const [
          IsoPart(
            0,
            2.85,
            0.5,
            0.06,
            0.9,
            0.95,
            Color(0xFF8FD3F4),
            id: 'splashback',
          ),
          IsoPart(
            0.06,
            3.05,
            0,
            0.4,
            0.5,
            0.72,
            Color(0xFFB9C6D0),
            id: 'pedestal',
          ),
          IsoPart(
            0.02,
            2.93,
            0.72,
            0.66,
            0.74,
            0.16,
            Color(0xFFE3EAEF),
            id: 'basin',
          ),
          IsoPart(
            0.1,
            3.24,
            0.88,
            0.14,
            0.12,
            0.16,
            Color(0xFFF1F5F8),
            id: 'spout',
          ),
          IsoPart(0.68, 3.18, 0.74, 0.04, 0.24, 0.12, _blue, id: 'button'),
        ],
      ),
      SchoolObject(
        id: 'sink',
        nameKey: 'school_explorer.object.sink',
        parts: const [
          IsoPart(0, 4.4, 0.75, 0.7, 0.9, 0.2, _white),
          IsoPart(0, 4.75, 0.95, 0.35, 0.1, 0.2, _steel),
          IsoPart(0, 4.3, 1.5, 0.08, 1.1, 0.9, _glass),
        ],
      ),
      SchoolObject(
        id: 'lunchboxes',
        nameKey: 'school_explorer.object.lunchboxes',
        parts: const [
          IsoPart(0, 5.9, 0, 0.7, 1.8, 1.2, _wood),
          IsoPart(0.7, 6.0, 0.15, 0.02, 0.5, 0.35, _red),
          IsoPart(0.7, 6.6, 0.15, 0.02, 0.5, 0.35, _purple),
          IsoPart(0.7, 7.2, 0.15, 0.02, 0.4, 0.35, _yellow),
          IsoPart(0.7, 6.0, 0.7, 0.02, 0.5, 0.35, _green),
          IsoPart(0.7, 6.6, 0.7, 0.02, 0.5, 0.35, _blue),
          IsoPart(0.7, 7.2, 0.7, 0.02, 0.4, 0.35, _orange),
        ],
      ),
      SchoolObject(
        id: 'lunch_table_a',
        nameKey: 'school_explorer.object.lunch_table',
        parts: [
          ..._bench(2.2, 2.6, 4.0, _blue),
          ..._table(2.2, 3.1, 4.0, 1.0, h: 0.65, top: _white),
          ..._bench(2.2, 4.2, 4.0, _blue),
        ],
      ),
      SchoolObject(
        id: 'lunch_table_b',
        nameKey: 'school_explorer.object.lunch_table',
        parts: [
          ..._bench(2.2, 5.3, 4.0, _blue),
          ..._table(2.2, 5.8, 4.0, 1.0, h: 0.65, top: _white),
          ..._bench(2.2, 6.9, 4.0, _blue),
        ],
      ),
      SchoolObject(
        id: 'recycling_bins',
        nameKey: 'school_explorer.object.recycling_bins',
        parts: const [
          IsoPart(7.8, 5.6, 0, 0.5, 0.5, 0.8, _blue),
          IsoPart(8.4, 5.6, 0, 0.5, 0.5, 0.8, _green),
          IsoPart(9.0, 5.6, 0, 0.5, 0.5, 0.8, _grey),
        ],
      ),
    ],
  );
}
