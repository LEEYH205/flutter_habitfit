import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ranking.dart';

/// 클럽 서비스
class ClubService {
  static final ClubService _instance = ClubService._internal();
  factory ClubService() => _instance;
  ClubService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _clubsCollection = 'clubs';
  static const String _clubMembersCollection = 'club_members';

  /// 클럽 생성 (새로운 Club 모델용)
  Future<void> createClub({
    required String name,
    required String description,
    required String category,
    required bool isPrivate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되지 않았습니다');

      final now = DateTime.now();
      final clubId = _firestore.collection(_clubsCollection).doc().id;

      final club = Club(
        id: clubId,
        name: name,
        description: description,
        ownerId: user.uid,
        ownerName: user.displayName ?? 'Unknown User',
        memberIds: [user.uid], // 생성자는 자동으로 멤버가 됨
        adminIds: [user.uid], // 생성자는 자동으로 관리자가 됨
        type: ClubType.running, // 기본값
        isPublic: !isPrivate,
        maxMembers: 50,
        settings: {'category': category},
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .set(club.toMap());

      // 생성자를 클럽 멤버로 추가
      await _firestore
          .collection(_clubMembersCollection)
          .doc('${clubId}_${user.uid}')
          .set({
        'clubId': clubId,
        'userId': user.uid,
        'role': 'owner',
        'joinedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw Exception('클럽 생성에 실패했습니다: $e');
    }
  }

  /// 클럽 목록 조회
  Future<List<Club>> getClubs() async {
    try {
      final snapshot = await _firestore
          .collection(_clubsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Club.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('클럽 목록 조회에 실패했습니다: $e');
    }
  }

  /// 클럽 생성 (기존 메서드 - 호환성을 위해 유지)
  Future<String?> createClubOld({
    required String name,
    required String description,
    required ClubType type,
    String? imageUrl,
    bool isPublic = true,
    int maxMembers = 50,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final clubId = _firestore.collection(_clubsCollection).doc().id;

      final club = Club(
        id: clubId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        ownerId: user.uid,
        ownerName: user.displayName ?? 'Unknown User',
        memberIds: [user.uid], // 생성자는 자동으로 멤버가 됨
        adminIds: [user.uid], // 생성자는 자동으로 관리자가 됨
        type: type,
        isPublic: isPublic,
        maxMembers: maxMembers,
        settings: settings ?? {},
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .set(club.toMap());

      // 클럽 멤버 정보 추가
      await _addClubMember(
        clubId: clubId,
        userId: user.uid,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        role: ClubMemberRole.owner,
      );

      print('✅ 클럽 생성 완료: $name');
      return clubId;
    } catch (e) {
      print('❌ 클럽 생성 오류: $e');
      return null;
    }
  }

  /// 클럽 가입
  Future<bool> joinClub(String clubId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 클럽 정보 조회
      final clubDoc = await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('존재하지 않는 클럽입니다');
      }

      final club = Club.fromMap(clubDoc.data()!);

      // 이미 멤버인지 확인
      if (club.isMember(user.uid)) {
        throw Exception('이미 가입된 클럽입니다');
      }

      // 클럽이 가득 찬지 확인
      if (club.isFull) {
        throw Exception('클럽이 가득 찼습니다');
      }

      final batch = _firestore.batch();

      // 클럽 멤버 목록에 추가
      batch.update(
        _firestore.collection(_clubsCollection).doc(clubId),
        {
          'memberIds': FieldValue.arrayUnion([user.uid]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // 클럽 멤버 정보 추가
      await _addClubMember(
        clubId: clubId,
        userId: user.uid,
        displayName: user.displayName ?? 'Unknown User',
        profileImageUrl: user.photoURL,
        role: ClubMemberRole.member,
      );

      await batch.commit();

      print('✅ 클럽 가입 완료: $clubId');
      return true;
    } catch (e) {
      print('❌ 클럽 가입 오류: $e');
      return false;
    }
  }

  /// 클럽 탈퇴
  Future<bool> leaveClub(String clubId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 클럽 정보 조회
      final clubDoc = await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('존재하지 않는 클럽입니다');
      }

      final club = Club.fromMap(clubDoc.data()!);

      // 소유자는 탈퇴할 수 없음
      if (club.isOwner(user.uid)) {
        throw Exception('클럽 소유자는 탈퇴할 수 없습니다. 클럽을 삭제하거나 소유권을 이전하세요.');
      }

      // 멤버가 아닌 경우
      if (!club.isMember(user.uid)) {
        throw Exception('가입되지 않은 클럽입니다');
      }

      final batch = _firestore.batch();

      // 클럽 멤버 목록에서 제거
      batch.update(
        _firestore.collection(_clubsCollection).doc(clubId),
        {
          'memberIds': FieldValue.arrayRemove([user.uid]),
          'adminIds': FieldValue.arrayRemove([user.uid]), // 관리자였다면 관리자에서도 제거
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // 클럽 멤버 정보 삭제
      batch.delete(
        _firestore.collection(_clubMembersCollection).doc('${clubId}_${user.uid}'),
      );

      await batch.commit();

      print('✅ 클럽 탈퇴 완료: $clubId');
      return true;
    } catch (e) {
      print('❌ 클럽 탈퇴 오류: $e');
      return false;
    }
  }

  /// 클럽 삭제 (소유자만 가능)
  Future<bool> deleteClub(String clubId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 클럽 정보 조회
      final clubDoc = await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('존재하지 않는 클럽입니다');
      }

      final club = Club.fromMap(clubDoc.data()!);

      // 소유자 권한 확인
      if (!club.isOwner(user.uid)) {
        throw Exception('클럽 소유자만 삭제할 수 있습니다');
      }

      final batch = _firestore.batch();

      // 클럽 삭제
      batch.delete(_firestore.collection(_clubsCollection).doc(clubId));

      // 모든 멤버 정보 삭제
      final membersQuery = await _firestore
          .collection(_clubMembersCollection)
          .where('clubId', isEqualTo: clubId)
          .get();

      for (final memberDoc in membersQuery.docs) {
        batch.delete(memberDoc.reference);
      }

      await batch.commit();

      print('✅ 클럽 삭제 완료: $clubId');
      return true;
    } catch (e) {
      print('❌ 클럽 삭제 오류: $e');
      return false;
    }
  }

  /// 클럽 멤버 추가 (내부 메서드)
  Future<void> _addClubMember({
    required String clubId,
    required String userId,
    required String displayName,
    String? profileImageUrl,
    required ClubMemberRole role,
  }) async {
    final member = ClubMember(
      userId: userId,
      displayName: displayName,
      profileImageUrl: profileImageUrl,
      role: role,
      joinedAt: DateTime.now(),
      stats: {},
    );

    await _firestore
        .collection(_clubMembersCollection)
        .doc('${clubId}_$userId')
        .set({
      'clubId': clubId,
      ...member.toMap(),
    });
  }

  /// 공개 클럽 목록 조회
  Future<List<Club>> getPublicClubs({
    ClubType? type,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_clubsCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('updatedAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => Club.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ 공개 클럽 목록 조회 오류: $e');
      return [];
    }
  }

  /// 사용자가 가입한 클럽 목록 조회
  Future<List<Club>> getUserClubs(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_clubsCollection)
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Club.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 사용자 클럽 목록 조회 오류: $e');
      return [];
    }
  }

  /// 클럽 정보 조회
  Future<Club?> getClub(String clubId) async {
    try {
      final doc = await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .get();

      if (doc.exists) {
        return Club.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 클럽 정보 조회 오류: $e');
      return null;
    }
  }

  /// 클럽 멤버 목록 조회
  Future<List<ClubMember>> getClubMembers(String clubId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_clubMembersCollection)
          .where('clubId', isEqualTo: clubId)
          .orderBy('joinedAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ClubMember.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 클럽 멤버 목록 조회 오류: $e');
      return [];
    }
  }

  /// 클럽 검색
  Future<List<Club>> searchClubs(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // 클럽 이름으로 검색
      final querySnapshot = await _firestore
          .collection(_clubsCollection)
          .where('isPublic', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => Club.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ 클럽 검색 오류: $e');
      return [];
    }
  }

  /// 클럽 정보 업데이트 (소유자/관리자만 가능)
  Future<bool> updateClub({
    required String clubId,
    String? name,
    String? description,
    String? imageUrl,
    bool? isPublic,
    int? maxMembers,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 클럽 정보 조회 및 권한 확인
      final club = await getClub(clubId);
      if (club == null) {
        throw Exception('존재하지 않는 클럽입니다');
      }

      if (!club.isAdmin(user.uid)) {
        throw Exception('클럽 관리자만 정보를 수정할 수 있습니다');
      }

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isPublic != null) updateData['isPublic'] = isPublic;
      if (maxMembers != null) updateData['maxMembers'] = maxMembers;
      if (settings != null) updateData['settings'] = settings;

      await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .update(updateData);

      print('✅ 클럽 정보 업데이트 완료: $clubId');
      return true;
    } catch (e) {
      print('❌ 클럽 정보 업데이트 오류: $e');
      return false;
    }
  }

  /// 멤버 역할 변경 (소유자만 가능)
  Future<bool> changeMemberRole({
    required String clubId,
    required String memberId,
    required ClubMemberRole newRole,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 클럽 정보 조회 및 권한 확인
      final club = await getClub(clubId);
      if (club == null) {
        throw Exception('존재하지 않는 클럽입니다');
      }

      if (!club.isOwner(user.uid)) {
        throw Exception('클럽 소유자만 멤버 역할을 변경할 수 있습니다');
      }

      // 자기 자신의 역할은 변경할 수 없음
      if (memberId == user.uid) {
        throw Exception('자신의 역할은 변경할 수 없습니다');
      }

      final batch = _firestore.batch();

      // 클럽 멤버 정보 업데이트
      batch.update(
        _firestore.collection(_clubMembersCollection).doc('${clubId}_$memberId'),
        {
          'role': newRole.value,
        },
      );

      // 클럽의 관리자 목록 업데이트
      if (newRole == ClubMemberRole.admin) {
        batch.update(
          _firestore.collection(_clubsCollection).doc(clubId),
          {
            'adminIds': FieldValue.arrayUnion([memberId]),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        batch.update(
          _firestore.collection(_clubsCollection).doc(clubId),
          {
            'adminIds': FieldValue.arrayRemove([memberId]),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      await batch.commit();

      print('✅ 멤버 역할 변경 완료: $memberId -> ${newRole.displayName}');
      return true;
    } catch (e) {
      print('❌ 멤버 역할 변경 오류: $e');
      return false;
    }
  }

  /// 멤버 추방 (소유자/관리자만 가능)
  Future<bool> kickMember({
    required String clubId,
    required String memberId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 클럽 정보 조회 및 권한 확인
      final club = await getClub(clubId);
      if (club == null) {
        throw Exception('존재하지 않는 클럽입니다');
      }

      if (!club.isAdmin(user.uid)) {
        throw Exception('클럽 관리자만 멤버를 추방할 수 있습니다');
      }

      // 소유자는 추방할 수 없음
      if (club.isOwner(memberId)) {
        throw Exception('클럽 소유자는 추방할 수 없습니다');
      }

      // 자기 자신은 추방할 수 없음
      if (memberId == user.uid) {
        throw Exception('자신을 추방할 수 없습니다');
      }

      final batch = _firestore.batch();

      // 클럽 멤버 목록에서 제거
      batch.update(
        _firestore.collection(_clubsCollection).doc(clubId),
        {
          'memberIds': FieldValue.arrayRemove([memberId]),
          'adminIds': FieldValue.arrayRemove([memberId]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // 클럽 멤버 정보 삭제
      batch.delete(
        _firestore.collection(_clubMembersCollection).doc('${clubId}_$memberId'),
      );

      await batch.commit();

      print('✅ 멤버 추방 완료: $memberId');
      return true;
    } catch (e) {
      print('❌ 멤버 추방 오류: $e');
      return false;
    }
  }
}
