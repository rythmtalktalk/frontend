import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/activity.dart';
import '../models/user_activity.dart';

import 'dart:io';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Authentication
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInAnonymously() async {
    try {
      print('익명 로그인 시도 중...');
      final result = await _auth.signInAnonymously();
      print('익명 로그인 성공: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('익명 로그인 실패: $e');
      print('에러 타입: ${e.runtimeType}');
      if (e.toString().contains('internal-error')) {
        print('Firebase 내부 오류 - 네트워크 연결을 확인하세요');
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      print('이메일 로그인 시도 중: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('이메일 로그인 성공: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('이메일 로그인 실패: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      print('이메일 회원가입 시도 중: $email');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('이메일 회원가입 성공: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('이메일 회원가입 실패: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('로그아웃 완료');
    } catch (e) {
      print('로그아웃 실패: $e');
    }
  }

  // Activities CRUD
  Future<List<MusicActivity>> getTodayActivities() async {
    try {
      print('오늘의 활동 가져오기 시작');
      final querySnapshot = await _firestore
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      print('오늘의 활동 문서 수: ${querySnapshot.docs.length}');

      final activities = querySnapshot.docs.map((doc) {
        print('문서 ID: ${doc.id}, 데이터: ${doc.data()}');
        return MusicActivity.fromJson({'id': doc.id, ...doc.data()});
      }).toList();

      print('오늘의 활동 파싱 완료: ${activities.length}개');
      return activities;
    } catch (e) {
      print('활동 가져오기 실패: $e');
      return [];
    }
  }

  Future<List<MusicActivity>> getPopularActivities() async {
    try {
      print('인기 활동 가져오기 시작');
      final querySnapshot = await _firestore
          .collection('activities')
          .where('isPopular', isEqualTo: true)
          .orderBy('likeCount', descending: true)
          .limit(20)
          .get();

      print('인기 활동 문서 수: ${querySnapshot.docs.length}');

      final activities = querySnapshot.docs.map((doc) {
        print('인기 활동 문서 ID: ${doc.id}, 데이터: ${doc.data()}');
        return MusicActivity.fromJson({'id': doc.id, ...doc.data()});
      }).toList();

      print('인기 활동 파싱 완료: ${activities.length}개');
      return activities;
    } catch (e) {
      print('인기 활동 가져오기 실패: $e');
      return [];
    }
  }

  Future<bool> likeActivity(String activityId) async {
    try {
      final docRef = _firestore.collection('activities').doc(activityId);
      await docRef.update({'likeCount': FieldValue.increment(1)});

      // 사용자 좋아요 기록
      if (currentUser != null) {
        await _firestore
            .collection('user_likes')
            .doc('${currentUser!.uid}_$activityId')
            .set({
              'userId': currentUser!.uid,
              'activityId': activityId,
              'likedAt': FieldValue.serverTimestamp(),
            });
      }

      return true;
    } catch (e) {
      print('좋아요 실패: $e');
      return false;
    }
  }

  // User Activities
  Future<bool> saveUserActivity(UserActivity userActivity) async {
    try {
      await _firestore
          .collection('user_activities')
          .doc(userActivity.id)
          .set(userActivity.toJson());
      return true;
    } catch (e) {
      print('사용자 활동 저장 실패: $e');
      return false;
    }
  }

  Future<List<UserActivity>> getUserActivities(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserActivity.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('사용자 활동 가져오기 실패: $e');
      return [];
    }
  }

  // Firebase 연결 테스트
  Future<bool> testFirebaseConnection() async {
    try {
      print('Firebase 연결 테스트 시작...');

      // 간단한 읽기 테스트
      final testQuery = await _firestore
          .collection('activities')
          .limit(1)
          .get();

      print('Firebase 읽기 테스트 성공: ${testQuery.docs.length}개 문서');

      // 인증된 사용자 확인
      final user = currentUser;
      print('현재 인증된 사용자: ${user?.uid}');

      return true;
    } catch (e) {
      print('Firebase 연결 테스트 실패: $e');
      return false;
    }
  }

  // Parent Feedback
  Future<bool> saveParentFeedback(ParentFeedback feedback) async {
    try {
      print('피드백 저장 시작: ${feedback.id}');
      print('피드백 데이터: ${feedback.toJson()}');

      await _firestore
          .collection('parent_feedback')
          .doc(feedback.id)
          .set(feedback.toJson());

      print('피드백 저장 성공: ${feedback.id}');
      return true;
    } catch (e) {
      print('부모 피드백 저장 실패: $e');
      print('피드백 ID: ${feedback.id}');
      print('사용자 ID: ${feedback.userId}');
      return false;
    }
  }

  Future<List<ParentFeedback>> getParentFeedbackByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('피드백 조회 시작:');
      print('- 사용자 ID: $userId');
      print('- 시작 날짜: $startDate');
      print('- 종료 날짜: $endDate');

      final querySnapshot = await _firestore
          .collection('parent_feedback')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      print('조회된 문서 수: ${querySnapshot.docs.length}');

      final feedbacks = querySnapshot.docs.map((doc) {
        print('문서 ID: ${doc.id}');
        print('문서 데이터: ${doc.data()}');
        return ParentFeedback.fromJson({'id': doc.id, ...doc.data()});
      }).toList();

      print('변환된 피드백 수: ${feedbacks.length}');
      return feedbacks;
    } catch (e) {
      print('날짜별 피드백 가져오기 실패: $e');
      return [];
    }
  }

  // File Upload
  Future<String?> uploadAudioFile(String filePath, String fileName) async {
    try {
      final ref = _storage.ref().child('recordings/$fileName');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('오디오 파일 업로드 실패: $e');
      return null;
    }
  }

  // Statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final activities = await getUserActivities(userId);
      final totalActivities = activities.length;
      final completedActivities = activities.where((a) => a.isCompleted).length;
      final totalStickers = activities.fold<int>(
        0,
        (sum, a) => sum + a.stickers,
      );

      return {
        'totalActivities': totalActivities,
        'completedActivities': completedActivities,
        'totalStickers': totalStickers,
        'streakDays': await calculateStreakDays(userId),
      };
    } catch (e) {
      print('사용자 통계 가져오기 실패: $e');
      return {};
    }
  }

  Future<int> calculateStreakDays(String userId) async {
    try {
      final now = DateTime.now();
      final activities = await getUserActivities(userId);

      if (activities.isEmpty) return 0;

      // 날짜별로 그룹핑
      final dateMap = <String, bool>{};
      for (final activity in activities) {
        final dateKey = activity.completedAt.toIso8601String().split('T')[0];
        dateMap[dateKey] = true;
      }

      // 연속 일수 계산
      int streak = 0;
      for (int i = 0; i < 365; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateKey = checkDate.toIso8601String().split('T')[0];

        if (dateMap.containsKey(dateKey)) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('연속 일수 계산 실패: $e');
      return 0;
    }
  }

  // 가사 타이밍 데이터 업데이트
  Future<bool> updateActivityWithLyricTimings(
    String activityId,
    List<SongSection> sections,
  ) async {
    try {
      await _firestore.collection('activities').doc(activityId).update({
        'sections': sections.map((e) => e.toJson()).toList(),
      });
      return true;
    } catch (e) {
      print('가사 타이밍 업데이트 실패: $e');
      return false;
    }
  }

  // 가사 타이밍이 있는 활동 가져오기
  Future<MusicActivity?> getActivityWithTimings(String activityId) async {
    try {
      final doc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();
      if (doc.exists) {
        return MusicActivity.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      print('타이밍 정보 포함 활동 가져오기 실패: $e');
      return null;
    }
  }
}
