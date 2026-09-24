import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GridKeyboardNavigator {
  static final Set<LogicalKeyboardKey> rightKeys = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.numpad6,
  };

  static final Set<LogicalKeyboardKey> leftKeys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.numpad4,
  };

  static final Set<LogicalKeyboardKey> upKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.numpad8,
  };

  static final Set<LogicalKeyboardKey> downKeys = {
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.numpad2,
  };

  static final Set<LogicalKeyboardKey> actionKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.numpadEnter,
  };

  static bool isActionKey(LogicalKeyboardKey key) => actionKeys.contains(key);

  /// Navigates through [focusNodes] across [cols] columns and optional [sections].
  /// Returns `true` if the key was handled, or `false` otherwise.
  static bool handleKeyEvent({
    required int currentIndex,
    required LogicalKeyboardKey key,
    required int cols,
    required List<FocusNode> focusNodes,
    List<List<int>>? sections,
  }) {
    if (focusNodes.isEmpty) return false;

    if (rightKeys.contains(key)) {
      final target = (currentIndex + 1) % focusNodes.length;
      focusNodes[target].requestFocus();
      return true;
    }

    if (leftKeys.contains(key)) {
      final target = (currentIndex - 1 + focusNodes.length) % focusNodes.length;
      focusNodes[target].requestFocus();
      return true;
    }

    if (upKeys.contains(key) || downKeys.contains(key)) {
      final effectiveSections = sections ?? [List.generate(focusNodes.length, (i) => i)];
      final grid = _computeGrid(effectiveSections, cols);

      int r = -1;
      int c = -1;
      for (int i = 0; i < grid.length; i++) {
        final idx = grid[i].indexOf(currentIndex);
        if (idx != -1) {
          r = i;
          c = idx;
          break;
        }
      }

      if (r == -1) return false;

      if (upKeys.contains(key)) {
        final targetRow = r > 0 ? grid[r - 1] : grid.last;
        final targetCol = c.clamp(0, targetRow.length - 1);
        focusNodes[targetRow[targetCol]].requestFocus();
        return true;
      }

      if (downKeys.contains(key)) {
        final targetRow = r < grid.length - 1 ? grid[r + 1] : grid.first;
        final targetCol = c.clamp(0, targetRow.length - 1);
        focusNodes[targetRow[targetCol]].requestFocus();
        return true;
      }
    }

    return false;
  }

  static List<List<int>> _computeGrid(List<List<int>> sections, int cols) {
    final List<List<int>> grid = [];
    for (final section in sections) {
      for (int i = 0; i < section.length; i += cols) {
        grid.add(section.sublist(i, (i + cols > section.length) ? section.length : i + cols));
      }
    }
    return grid;
  }
}