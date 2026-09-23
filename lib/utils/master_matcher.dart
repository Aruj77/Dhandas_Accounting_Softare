// Lightweight fuzzy matcher (normalized Levenshtein similarity) used to
// decide whether a name extracted from a scanned document already exists
// in the company's Party/Item masters, or should be suggested as new.
// No extra dependency — pure Dart, O(n*m) per comparison, fine for the
// list sizes typical of an SMB's masters (hundreds, not millions).
class MasterMatch {
  final Map<String, dynamic>? match;
  final double score; // 0..1, 1 = exact
  final bool isNew;

  MasterMatch({required this.match, required this.score, required this.isNew});
}

class MasterMatcher {
  static const double defaultThreshold = 0.72;

  static String _norm(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(
          RegExp(r'\s+'), ' ');

  static double similarity(String a, String b) {
    final na = _norm(a);
    final nb = _norm(b);
    if (na.isEmpty || nb.isEmpty) return 0;
    if (na == nb) return 1;
    final dist = _levenshtein(na, nb);
    final maxLen = na.length > nb.length ? na.length : nb.length;
    if (maxLen == 0) return 0;
    return 1 - (dist / maxLen);
  }

  static int _levenshtein(String s, String t) {
    final m = s.length, n = t.length;
    List<int> prev = List.generate(n + 1, (j) => j);
    for (int i = 1; i <= m; i++) {
      final cur = List<int>.filled(n + 1, 0);
      cur[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        final del = prev[j] + 1;
        final ins = cur[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        cur[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      prev = cur;
    }
    return prev[n];
  }

  /// Finds the closest entry in [candidates] (each a masters record map
  /// with a 'name' key) to [name]. Returns isNew=true when nothing crosses
  /// [threshold], meaning the UI should offer to create a new master entry.
  static MasterMatch bestMatch(
    String name,
    List<Map<String, dynamic>> candidates, {
    double threshold = defaultThreshold,
  }) {
    Map<String, dynamic>? best;
    double bestScore = 0;
    for (final c in candidates) {
      final s = similarity(name, (c['name'] ?? '').toString());
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return MasterMatch(
      match: bestScore >= threshold ? best : null,
      score: bestScore,
      isNew: bestScore < threshold,
    );
  }
}
