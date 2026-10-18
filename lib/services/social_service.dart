import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Backs features 25–27 (leagues, friends, lesson threads, clubs). Firebase
/// is already initialized and the user already signed in by [AuthGate]
/// before any screen using this service can be reached (auth is mandatory),
/// so this just reads the current user rather than signing in itself. Every
/// public method still fails soft (returns empty/false) if Firestore is
/// unreachable, so the rest of the app keeps working without it.
/// The single shared club every player can join.
const defaultClubId = 'kalanden-manding';

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  bool get isAvailable => FirebaseAuth.instance.currentUser != null;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> ensureReady() async => isAvailable;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Call after login and whenever local XP/tier changes, so the leaderboard
  /// and club contributions stay in sync. [leagueTier] is the index into
  /// `leagueTierNames` (progress_store.dart) — written here so
  /// [weeklyLeagueStream] can filter the board to the caller's own tier.
  Future<void> upsertProfile({
    required String displayName,
    required int xp,
    required int weeklyXp,
    required int leagueTier,
  }) async {
    if (!isAvailable) return;
    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'xp': xp,
      'weeklyXp': weeklyXp,
      'leagueTier': leagueTier,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Leaderboard scoped to a single league tier — see [upsertProfile].
  /// Needs a composite index on (leagueTier asc, weeklyXp desc), declared in
  /// firestore.indexes.json.
  Stream<List<LeagueMember>> weeklyLeagueStream(int leagueTier) {
    if (!isAvailable) return const Stream.empty();
    return _db
        .collection('users')
        .where('leagueTier', isEqualTo: leagueTier)
        .orderBy('weeklyXp', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => LeagueMember(uid: d.id, name: d['displayName'] ?? '?', weeklyXp: d['weeklyXp'] ?? 0)).toList());
  }

  Future<void> addFriend(String friendUid) async {
    if (!isAvailable || friendUid == uid) return;
    await _db.collection('users').doc(uid).collection('friends').doc(friendUid).set({'addedAt': FieldValue.serverTimestamp()});
  }

  Stream<List<LeagueMember>> friendsStream() {
    if (!isAvailable) return const Stream.empty();
    return _db.collection('users').doc(uid).collection('friends').snapshots().asyncMap((snap) async {
      final out = <LeagueMember>[];
      for (final doc in snap.docs) {
        final userDoc = await _db.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          out.add(LeagueMember(uid: doc.id, name: userDoc['displayName'] ?? '?', weeklyXp: userDoc['weeklyXp'] ?? 0));
        }
      }
      return out;
    });
  }

  Stream<List<ThreadPost>> lessonThreadStream(String unitId) {
    if (!isAvailable) return const Stream.empty();
    return _db
        .collection('lessonThreads')
        .doc(unitId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ThreadPost(
                  id: d.id,
                  author: d['author'] ?? '?',
                  authorUid: (d.data()['authorUid'] as String?) ?? '',
                  text: d['text'] ?? '',
                  createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
                ))
            .toList());
  }

  /// Signale un message pour modération (consultable côté console Firebase).
  Future<void> reportPost(String unitId, ThreadPost post, String reason) async {
    if (!isAvailable) return;
    await _db.collection('reports').add({
      'unitId': unitId,
      'postId': post.id,
      'postAuthorUid': post.authorUid,
      'text': post.text.length > 500 ? post.text.substring(0, 500) : post.text,
      'reason': reason,
      'reporterUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static const _blockedKey = 'nko_kalan_blocked_uids';

  /// Auteurs masqués par l'utilisateur — local à l'appareil.
  Future<Set<String>> blockedUids() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_blockedKey) ?? const []).toSet();
  }

  Future<void> blockUser(String authorUid) async {
    if (authorUid.isEmpty || authorUid == uid) return;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_blockedKey) ?? const []).toSet()..add(authorUid);
    await prefs.setStringList(_blockedKey, set.toList());
  }

  Future<void> postToThread(String unitId, String author, String text) async {
    if (!isAvailable || text.trim().isEmpty) return;
    await _db.collection('lessonThreads').doc(unitId).collection('posts').add({
      'author': author,
      'authorUid': uid,
      'text': text.trim().length > 500 ? text.trim().substring(0, 500) : text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<ClubData?> clubStream(String clubId) {
    if (!isAvailable) return const Stream.empty();
    return _db.collection('clubs').doc(clubId).snapshots().map((d) {
      if (!d.exists) return null;
      final members = (d['members'] as Map?)?.cast<String, dynamic>() ?? {};
      return ClubData(
        id: d.id,
        name: d['name'] ?? clubId,
        weeklyGoalXp: d['weeklyGoalXp'] ?? 500,
        members: members.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    });
  }

  Future<void> joinClub(String clubId, String displayName) async {
    if (!isAvailable) return;
    final ref = _db.collection('clubs').doc(clubId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': clubId,
        'weeklyGoalXp': 500,
        'members': {uid!: 0}
      });
      return;
    }
    final members = snap.data()?['members'] as Map?;
    if (members == null || !members.containsKey(uid)) {
      await ref.set({
        'members': {uid: 0}
      }, SetOptions(merge: true));
    }
  }

  /// Adds [xp] earned by this player to the club's tally. Called from real
  /// lesson completions (see main.dart), never from a free-standing button.
  Future<void> contributeToClub(String clubId, int xp) async {
    if (!isAvailable || xp <= 0) return;
    await _db.collection('clubs').doc(clubId).set({
      'members': {uid: FieldValue.increment(xp)},
    }, SetOptions(merge: true));
  }
}

class LeagueMember {
  final String uid;
  final String name;
  final int weeklyXp;
  const LeagueMember({required this.uid, required this.name, required this.weeklyXp});
}

class ThreadPost {
  final String id;
  final String author;
  final String authorUid;
  final String text;
  final DateTime? createdAt;
  const ThreadPost({
    required this.id,
    required this.author,
    required this.authorUid,
    required this.text,
    required this.createdAt,
  });
}

class ClubData {
  final String id;
  final String name;
  final int weeklyGoalXp;
  final Map<String, int> members;
  const ClubData({required this.id, required this.name, required this.weeklyGoalXp, required this.members});

  int get totalXp => members.values.fold(0, (a, b) => a + b);
}
