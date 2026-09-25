import 'package:flutter/material.dart';

import '../../../shared/services/trail_progress_service.dart';
import '../models/trail_node.dart';

/// Tracks progress through the "Learn BSL trail" and whether the game
/// currently on screen was launched from it.
///
/// Two independent pieces of state:
/// - [completedNodeIds]: which trail nodes the player has finished — loaded
///   from Supabase (empty for guests, see [TrailProgressService]) and used
///   to decide which nodes are unlocked.
/// - [activeNodeId]: set only while playing a game reached *via* the trail,
///   so that game's "Next Level" button can advance the trail instead of
///   its own normal level progression. Cleared for ordinary play.
class TrailProvider extends ChangeNotifier {
  final TrailProgressService _service;

  TrailProvider({TrailProgressService? service})
    : _service = service ?? TrailProgressService();

  Set<String> _completedNodeIds = {};
  Set<String> get completedNodeIds => _completedNodeIds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _activeNodeId;
  String? get activeNodeId => _activeNodeId;

  // Set by [completeNode] the moment a node is *newly* completed, so the
  // trail screen can tell "just unlocked this section" apart from "this
  // section was already unlocked when I loaded" and play its cloud-parting
  // reveal only for the former. Cleared once the trail screen has consumed
  // it (see [consumeJustCompleted]) so revisiting later doesn't replay it.
  String? _justCompletedNodeId;
  String? get justCompletedNodeId => _justCompletedNodeId;

  TrailNode? get activeNode => _activeNodeId == null
      ? null
      : bslTrail.firstWhere((n) => n.id == _activeNodeId);

  /// (Re)loads completed nodes from Supabase. Call when the trail screen
  /// opens, so it reflects the current sign-in state.
  Future<void> loadProgress() async {
    _isLoading = true;
    notifyListeners();
    _completedNodeIds = await _service.fetchCompletedNodeIds();
    _isLoading = false;
    notifyListeners();
  }

  /// A node is unlocked if it's the trail's first node, or any node listing
  /// it as a successor has been completed — this is what makes the node
  /// after a fork unlock on the *first* branch finished, not both.
  bool isNodeUnlocked(TrailNode node) {
    if (node.id == bslTrail.first.id) return true;
    return bslTrail
        .where((n) => n.nextNodeIds.contains(node.id))
        .any((n) => _completedNodeIds.contains(n.id));
  }

  /// Marks the game now on screen as launched from the trail node [nodeId].
  void enterTrail(String nodeId) {
    _activeNodeId = nodeId;
    notifyListeners();
  }

  /// Clears trail-session state — call when leaving the trail flow (e.g.
  /// returning to the trail map, or playing a game normally afterwards).
  void exitTrail() {
    _activeNodeId = null;
    notifyListeners();
  }

  /// Records [nodeId] as completed, optimistically updating local state
  /// before persisting (mirrors [SettingsProvider]'s save pattern).
  Future<void> completeNode(String nodeId) async {
    if (_completedNodeIds.contains(nodeId)) return;
    _completedNodeIds = {..._completedNodeIds, nodeId};
    _justCompletedNodeId = nodeId;
    notifyListeners();
    await _service.markNodeCompleted(nodeId);
  }

  /// Clears [justCompletedNodeId] once whoever needed it (the trail
  /// screen's cloud-parting reveal) has acted on it.
  void consumeJustCompleted() {
    _justCompletedNodeId = null;
  }
}
