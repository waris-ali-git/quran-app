import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../models/counter.dart';
import '../services/tasbeeh_service.dart';

// ═══════════════════════════════════════════
//   STATE
// ═══════════════════════════════════════════

class TasbeehState {
  final List<TasbeehCounter> counters;
  final TasbeehCounter? activeCounter;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> settings;
  final bool justCompleted;
  final Map<String, dynamic> stats;

  const TasbeehState({
    this.counters = const [],
    this.activeCounter,
    this.isLoading = true,
    this.error,
    this.settings = const {},
    this.justCompleted = false,
    this.stats = const {},
  });

  TasbeehState copyWith({
    List<TasbeehCounter>? counters,
    TasbeehCounter? activeCounter,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? settings,
    bool? justCompleted,
    Map<String, dynamic>? stats,
    bool clearActive = false,
  }) {
    return TasbeehState(
      counters: counters ?? this.counters,
      activeCounter: clearActive ? null : (activeCounter ?? this.activeCounter),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      settings: settings ?? this.settings,
      justCompleted: justCompleted ?? this.justCompleted,
      stats: stats ?? this.stats,
    );
  }
}

// ═══════════════════════════════════════════
//   CUBIT
// ═══════════════════════════════════════════

class TasbeehBloc extends Cubit<TasbeehState> {
  final TasbeehService _service;

  DateTime? _sessionStart;
  Timer? _completionTimer;

  TasbeehBloc({TasbeehService? service})
      : _service = service ?? TasbeehService(),
        super(const TasbeehState()) {
    _init();
  }

  Future<void> _init() async {
    final counters = await _service.loadCounters();
    final settings = await _service.loadSettings();
    final stats = await _service.getStatistics(counters);
    emit(TasbeehState(
      counters: counters,
      activeCounter: counters.isNotEmpty ? counters.first : null,
      isLoading: false,
      settings: settings,
      stats: stats,
    ));
  }

  // ─── Increment ─────────────────────────────────────────────────────────────
  Future<void> increment() async {
    if (state.activeCounter == null) return;

    _sessionStart ??= DateTime.now();

    final counter = state.activeCounter!;
    final newCount = counter.count + 1;
    final justHitTarget = newCount == counter.targetCount ||
        (newCount > counter.targetCount &&
            newCount % counter.targetCount == 0);

    // Haptic feedback
    if (state.settings['vibrationEnabled'] == true) {
      if (justHitTarget) {
        HapticFeedback.heavyImpact();
        _vibrateMilestone();
      } else {
        HapticFeedback.selectionClick();
      }
    }

    final updated = counter.copyWith(
      count: newCount,
      totalCount: counter.totalCount + 1,
    );

    final updatedCounters = state.counters.map((c) {
      return c.id == updated.id ? updated : c;
    }).toList();

    emit(state.copyWith(
      activeCounter: updated,
      counters: updatedCounters,
      justCompleted: justHitTarget,
    ));

    await _service.saveCounters(updatedCounters);

    // Clear justCompleted after animation
    if (justHitTarget) {
      _completionTimer?.cancel();
      _completionTimer = Timer(const Duration(milliseconds: 1500), () {
        emit(state.copyWith(justCompleted: false));
      });
    }
  }

  // ─── Decrement ─────────────────────────────────────────────────────────────
  Future<void> decrement() async {
    if (state.activeCounter == null) return;
    final counter = state.activeCounter!;
    if (counter.count == 0) return;

    HapticFeedback.lightImpact();

    final updated = counter.copyWith(count: counter.count - 1);
    final updatedCounters = state.counters
        .map((c) => c.id == updated.id ? updated : c)
        .toList();

    emit(state.copyWith(
      activeCounter: updated,
      counters: updatedCounters,
    ));
    await _service.saveCounters(updatedCounters);
  }

  // ─── Reset current counter ─────────────────────────────────────────────────
  Future<void> resetCount() async {
    if (state.activeCounter == null) return;

    await _endSession();

    HapticFeedback.mediumImpact();
    final counter = state.activeCounter!;
    final updated = counter.copyWith(
      count: 0,
      totalSessions: counter.totalSessions + 1,
    );
    final updatedCounters = state.counters
        .map((c) => c.id == updated.id ? updated : c)
        .toList();

    emit(state.copyWith(
      activeCounter: updated,
      counters: updatedCounters,
    ));
    await _service.saveCounters(updatedCounters);
  }

  // ─── Select a counter ──────────────────────────────────────────────────────
  Future<void> selectCounter(TasbeehCounter counter) async {
    await _endSession();
    emit(state.copyWith(activeCounter: counter));
  }

  // ─── Add custom counter ────────────────────────────────────────────────────
  Future<void> addCustomCounter(TasbeehCounter counter) async {
    final updatedCounters = [...state.counters, counter];
    emit(state.copyWith(
      counters: updatedCounters,
      activeCounter: counter,
    ));
    await _service.saveCounters(updatedCounters);
  }

  // ─── Delete counter ────────────────────────────────────────────────────────
  Future<void> deleteCounter(String id) async {
    final updatedCounters =
        state.counters.where((c) => c.id != id).toList();
    TasbeehCounter? newActive = state.activeCounter?.id == id
        ? (updatedCounters.isNotEmpty ? updatedCounters.first : null)
        : state.activeCounter;

    emit(state.copyWith(
      counters: updatedCounters,
      activeCounter: newActive,
    ));
    await _service.saveCounters(updatedCounters);
  }

  // ─── Toggle favorite ───────────────────────────────────────────────────────
  Future<void> toggleFavorite(String id) async {
    final updatedCounters = state.counters.map((c) {
      return c.id == id ? c.copyWith(isFavorite: !c.isFavorite) : c;
    }).toList();

    final updatedActive = state.activeCounter?.id == id
        ? updatedCounters.firstWhere((c) => c.id == id)
        : state.activeCounter;

    emit(state.copyWith(
      counters: updatedCounters,
      activeCounter: updatedActive,
    ));
    await _service.saveCounters(updatedCounters);
  }

  // ─── Update settings ───────────────────────────────────────────────────────
  Future<void> updateSetting(String key, dynamic value) async {
    final newSettings = Map<String, dynamic>.from(state.settings);
    newSettings[key] = value;
    emit(state.copyWith(settings: newSettings));
    await _service.saveSettings(newSettings);
  }

  // ─── Refresh stats ─────────────────────────────────────────────────────────
  Future<void> refreshStats() async {
    final stats = await _service.getStatistics(state.counters);
    emit(state.copyWith(stats: stats));
  }

  // ─── Private helpers ───────────────────────────────────────────────────────
  Future<void> _endSession() async {
    if (_sessionStart != null && state.activeCounter != null) {
      final counter = state.activeCounter!;
      if (counter.count > 0) {
        final session = TasbeehSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tasbeehId: counter.id,
          tasbeehName: counter.name,
          count: counter.count,
          startTime: _sessionStart!,
          endTime: DateTime.now(),
        );
        await _service.saveSession(session);
      }
      _sessionStart = null;
    }
  }

  Future<void> _vibrateMilestone() async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (hasVibrator) {
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 200]);
    }
  }

  @override
  Future<void> close() {
    _completionTimer?.cancel();
    return super.close();
  }
}