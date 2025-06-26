import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import 'firebase_service.dart';

class LyricTimingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 기존 활동에 가사 타이밍 정보 추가
  static Future<void> updateActivitiesWithTimings() async {
    try {
      print('활동에 가사 타이밍 정보 추가 시작...');

      // 곰 세 마리 업데이트
      await _updateBearsActivity();

      // 나비야 업데이트
      await _updateButterflyActivity();

      // 동물농장 업데이트
      await _updateAnimalFarmActivity();

      // 작은별 업데이트
      await _updateTwinkleStarActivity();

      // 아기상어 업데이트
      await _updateBabySharkActivity();

      print('모든 활동의 가사 타이밍 정보 업데이트 완료!');
    } catch (e) {
      print('가사 타이밍 업데이트 실패: $e');
      rethrow;
    }
  }

  // 곰 세 마리 가사 타이밍 추가
  static Future<void> _updateBearsActivity() async {
    final sections = [
      SongSection(
        index: 0,
        text: '곰 세 마리가 한 집에 있어',
        startTime: 0.0,
        endTime: 4.5,
      ),
      SongSection(
        index: 1,
        text: '아빠 곰, 엄마 곰, 애기 곰',
        startTime: 4.5,
        endTime: 8.0,
      ),
      SongSection(index: 2, text: '아빠 곰은 뚱뚱해', startTime: 8.0, endTime: 11.5),
      SongSection(index: 3, text: '엄마 곰은 날씬해', startTime: 11.5, endTime: 15.0),
      SongSection(
        index: 4,
        text: '애기 곰은 너무 귀여워',
        startTime: 15.0,
        endTime: 18.5,
      ),
      SongSection(index: 5, text: '으쓱으쓱 잘한다', startTime: 18.5, endTime: 22.0),
    ];

    await FirebaseService().updateActivityWithLyricTimings(
      'activity_1',
      sections,
    );
    print('곰 세 마리 가사 타이밍 업데이트 완료');
  }

  // 나비야 가사 타이밍 추가
  static Future<void> _updateButterflyActivity() async {
    final sections = [
      SongSection(
        index: 0,
        text: '나비야 나비야 이리 날아와',
        startTime: 0.0,
        endTime: 4.0,
      ),
      SongSection(
        index: 1,
        text: '노랑나비 흰나비 어서 날아와',
        startTime: 4.0,
        endTime: 8.0,
      ),
      SongSection(
        index: 2,
        text: '봄바람에 꽃잎도 방긋방긋 웃는데',
        startTime: 8.0,
        endTime: 12.0,
      ),
      SongSection(
        index: 3,
        text: '너도 나도 즐겁게 춤을 추어라',
        startTime: 12.0,
        endTime: 16.0,
      ),
    ];

    await FirebaseService().updateActivityWithLyricTimings(
      'activity_2',
      sections,
    );
    print('나비야 가사 타이밍 업데이트 완료');
  }

  // 동물농장 가사 타이밍 추가
  static Future<void> _updateAnimalFarmActivity() async {
    final sections = [
      SongSection(
        index: 0,
        text: '꼬끼오 꼬끼오 닭이 울어요',
        startTime: 0.0,
        endTime: 4.0,
      ),
      SongSection(index: 1, text: '음메 음메 소가 울어요', startTime: 4.0, endTime: 8.0),
      SongSection(
        index: 2,
        text: '멍멍 멍멍 개가 짖어요',
        startTime: 8.0,
        endTime: 12.0,
      ),
      SongSection(
        index: 3,
        text: '야옹 야옹 고양이 울어요',
        startTime: 12.0,
        endTime: 16.0,
      ),
      SongSection(
        index: 4,
        text: '동물농장 즐거운 동물농장',
        startTime: 16.0,
        endTime: 20.0,
      ),
      SongSection(index: 5, text: '모두 모두 노래해요', startTime: 20.0, endTime: 24.0),
    ];

    await FirebaseService().updateActivityWithLyricTimings(
      'activity_3',
      sections,
    );
    print('동물농장 가사 타이밍 업데이트 완료');
  }

  // 작은별 가사 타이밍 추가
  static Future<void> _updateTwinkleStarActivity() async {
    final sections = [
      SongSection(index: 0, text: '반짝반짝 작은별', startTime: 0.0, endTime: 4.0),
      SongSection(index: 1, text: '아름답게 비추네', startTime: 4.0, endTime: 8.0),
      SongSection(index: 2, text: '서쪽 하늘에서도', startTime: 8.0, endTime: 12.0),
      SongSection(index: 3, text: '동쪽 하늘에서도', startTime: 12.0, endTime: 16.0),
      SongSection(index: 4, text: '반짝반짝 작은별', startTime: 16.0, endTime: 20.0),
      SongSection(index: 5, text: '아름답게 비추네', startTime: 20.0, endTime: 24.0),
    ];

    await FirebaseService().updateActivityWithLyricTimings(
      'activity_5',
      sections,
    );
    print('작은별 가사 타이밍 업데이트 완료');
  }

  // 아기상어 가사 타이밍 추가
  static Future<void> _updateBabySharkActivity() async {
    final sections = [
      SongSection(index: 0, text: '아기상어 뚜루루뚜루', startTime: 0.0, endTime: 3.0),
      SongSection(index: 1, text: '아기상어 뚜루루뚜루', startTime: 3.0, endTime: 6.0),
      SongSection(index: 2, text: '아기상어 뚜루루뚜루', startTime: 6.0, endTime: 9.0),
      SongSection(index: 3, text: '아기상어', startTime: 9.0, endTime: 11.0),
      SongSection(index: 4, text: '엄마상어 뚜루루뚜루', startTime: 11.0, endTime: 14.0),
      SongSection(index: 5, text: '엄마상어 뚜루루뚜루', startTime: 14.0, endTime: 17.0),
      SongSection(index: 6, text: '엄마상어 뚜루루뚜루', startTime: 17.0, endTime: 20.0),
      SongSection(index: 7, text: '엄마상어', startTime: 20.0, endTime: 22.0),
    ];

    await FirebaseService().updateActivityWithLyricTimings(
      'activity_6',
      sections,
    );
    print('아기상어 가사 타이밍 업데이트 완료');
  }
}
