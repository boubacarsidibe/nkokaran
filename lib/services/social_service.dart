import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Backs features 25–27 (leagues, friends, lesson threads, clubs). All of it
/// needs a real Firebase project — see `lib/firebase_options.dart`. Every
/// public method fails soft (returns empty/false) when Firebase isn't
/// configured or reachable, so the rest of the app keeps working without it.
class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  bool _initTried = false;
  bool _available = false;
  String? _uid;

  bool get isAvailable => _available;
  String? get uid => _uid;

  Future<bool> ensureReady() async {
    if (_initTried) return _available;
    _initTried = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user!.uid;
      _available = true;
    } catch (_) {
      // No/placeholder Firebase config, unsupported platform, or offline —
      // social screens show a "non disponible" state instead of crashing.
      _available = false;
    }
    return _available;
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Call after login and whenever local XP changes, so the leaderboard and
  /// club contributions stay in sync.
  Future<void> upsertProfile({required String displayName, required int xp, required int weeklyXp}) async {
    if (!_available) return;
    await _db.collection('users').doc(_uid).set({
      'displayName': displayName,
      'xp': xp,
      'weeklyXp': weeklyXp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<LeagueMember>> weeklyLeagueStream() {
    if (!_available) return const Stream.empty();
    return _db
        .collection('users')
        .orderBy('weeklyXp', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => LeagueMember(uid: d.id, name: d['displayName'] ?? '?', weeklyXp: d['weeklyXp'] ?? 0)).toList());
  }

  Future<void> addFriend(String friendUid) async {
    if (!_available || friendUid == _uid) return;
    await _db.collection('users').doc(_uid).collection('friends').doc(friendUid).set({'addedAt': FieldValue.serverTimestamp()});
  }

  Stream<List<LeagueMember>> friendsStream() {
    if (!_available) return const Stream.empty();
    return _db.collection('users').doc(_uid).collection('friends').snapshots().asyncMap((snap) async {
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
    if (!_available) return const Stream.empty();
    return _db
        .collection('lessonThreads')
        .doc(unitId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ThreadPost(author: d['author'] ?? '?', text: d['text'] ?? '', createdAt: (d['createdAt'] as Timestamp?)?.toDate()))
            .toList());
  }

  Future<void> postToThread(String unitId, String author, String text) async {
    if (!_available || text.trim().isEmpty) return;
    await _db.collection('lessonThreads').doc(unitId).collection('posts').add({
      'author': author,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<ClubData?> clubStream(String clubId) {
    if (!_available) return const Stream.empty();
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
    if (!_available) return;
    await _db.collection('clubs').doc(clubId).set({
      'name': clubId,
      'weeklyGoalXp': 500,
      'members.$_uid': 0,
    }, SetOptions(merge: true));
  }

  Future<void> contributeToClub(String clubId, int xp) async {
    if (!_available) return;
    await _db.collection('clubs').doc(clubId).set({
      'members.$_uid': FieldValue.increment(xp),
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
  final String author;
  final String text;
  final DateTime? createdAt;
  const ThreadPost({required this.author, required this.text, required this.createdAt});
}

class ClubData {
  final String id;
  final String name;
  final int weeklyGoalXp;
  final Map<String, int> members;
  const ClubData({required this.id, required this.name, required this.weeklyGoalXp, required this.members});

  int get totalXp => members.values.fold(0, (a, b) => a + b);
}
