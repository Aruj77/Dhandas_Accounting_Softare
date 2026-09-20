class SmartFilter {
  static bool matches(String candidate, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final target = candidate.toLowerCase();

    if (target.contains(q)) return true;

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length > 1) {
      final allTokensMatch = tokens.every((token) => matches(target, token));
      if (allTokensMatch) return true;
    }

    if (_matchesAcronym(target, q)) return true;

    if (_matchesSubsequence(target, q)) return true;

    return false;
  }

  static bool _matchesAcronym(String target, String query) {
    final words = target.split(RegExp(r'[\s\-_]+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return false;

    final initialsBuffer = StringBuffer();
    for (final w in words) {
      initialsBuffer.write(w[0]);
      final symbols = w.replaceAll(RegExp(r'[a-zA-Z0-9]'), '');
      if (symbols.isNotEmpty) {
        initialsBuffer.write(symbols);
      }
    }
    final initials = initialsBuffer.toString();

    if (initials.contains(query)) return true;

    if (query.length >= 2 && words.first.startsWith(query[0])) {
      final querySymbols = query.replaceAll(RegExp(r'[a-zA-Z0-9]'), '');
      final targetSymbols = target.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');
      if (querySymbols.isNotEmpty && targetSymbols.contains(querySymbols)) {
        return true;
      }
    }

    return false;
  }
  static bool _matchesSubsequence(String target, String query) {
    int targetIndex = 0;
    int queryIndex = 0;

    while (targetIndex < target.length && queryIndex < query.length) {
      if (target[targetIndex] == query[queryIndex]) {
        queryIndex++;
      }
      targetIndex++;
    }

    return queryIndex == query.length;
  }

  static List<T> filterAndSort<T>({
    required List<T> items,
    required String query,
    required String Function(T) labelExtractor,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return items;

    final matched = <T>[];

    for (final item in items) {
      final label = labelExtractor(item);
      if (matches(label, cleanQuery)) {
        matched.add(item);
      }
    }

    matched.sort((a, b) {
      final labelA = labelExtractor(a).toLowerCase();
      final labelB = labelExtractor(b).toLowerCase();

      final aExact = labelA == cleanQuery;
      final bExact = labelB == cleanQuery;
      if (aExact != bExact) return aExact ? -1 : 1;

      final aStarts = labelA.startsWith(cleanQuery);
      final bStarts = labelB.startsWith(cleanQuery);
      if (aStarts != bStarts) return aStarts ? -1 : 1;

      final aContains = labelA.contains(cleanQuery);
      final bContains = labelB.contains(cleanQuery);
      if (aContains != bContains) return aContains ? -1 : 1;

      return labelA.compareTo(labelB);
    });

    return matched;
  }
}