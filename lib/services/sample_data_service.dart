import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/activity.dart';
import 'firebase_service.dart';

class SampleDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> addSampleActivities() async {
    try {
      // 기존 데이터 확인
      final existingData = await _firestore
          .collection('activities')
          .limit(1)
          .get();
      if (existingData.docs.isNotEmpty) {
        print('샘플 데이터가 이미 존재합니다.');
        return;
      }

      // 실제 Firebase Storage에 업로드할 수 있는 샘플 오디오 URL들
      // 이 URL들은 실제 동요 음원이나 TTS로 생성된 오디오 파일들입니다
      final sampleActivities = [
        MusicActivity(
          id: 'activity_1',
          title: '곰 세 마리',
          description: '귀여운 곰 세 마리와 함께 노래해요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%80%E1%85%A9%E1%86%B7%E1%84%89%E1%85%A6%E1%84%86%E1%85%A1%E1%84%85%E1%85%B5.mp3',
          lyrics:
              '곰 세 마리가 한 집에 있어\n아빠 곰, 엄마 곰, 애기 곰\n아빠 곰은 뚱뚱해\n엄마 곰은 날씬해\n애기 곰은 너무 귀여워\n으쓱으쓱 잘한다',
          blanks: ['곰', '아빠', '엄마', '애기'],
          rhythmWords: ['곰곰곰', '뚱뚱해', '날씬해', '귀여워', '으쓱으쓱'],
          sections: [
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
            SongSection(
              index: 2,
              text: '아빠 곰은 뚱뚱해',
              startTime: 8.0,
              endTime: 11.5,
            ),
            SongSection(
              index: 3,
              text: '엄마 곰은 날씬해',
              startTime: 11.5,
              endTime: 15.0,
            ),
            SongSection(
              index: 4,
              text: '애기 곰은 너무 귀여워',
              startTime: 15.0,
              endTime: 18.5,
            ),
            SongSection(
              index: 5,
              text: '으쓱으쓱 잘한다',
              startTime: 18.5,
              endTime: 22.0,
            ),
          ],
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['동물', '가족', '기초'],
          likeCount: 45,
          isPopular: true,
          createdAt: DateTime.now(),
        ),
        MusicActivity(
          id: 'activity_2',
          title: '나비야',
          description: '예쁜 나비와 함께 춤춰요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%82%E1%85%A1%E1%84%87%E1%85%B5%E1%84%8B%E1%85%A3.mp3',
          lyrics:
              '나비야 나비야 이리 날아와\n노랑나비 흰나비 어서 날아와\n봄바람에 꽃잎도 방긋방긋 웃는데\n너도 나도 즐겁게 춤을 추어라',
          blanks: ['나비야', '노랑나비', '봄바람', '참새'],
          rhythmWords: ['나비야', '날아와', '춤을춰', '웃으며', '노래해'],
          sections: [
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
          ],
          difficulty: 2,
          ageGroup: '4-6세',
          tags: ['자연', '곤충', '봄'],
          likeCount: 38,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        MusicActivity(
          id: 'activity_3',
          title: '동물농장',
          description: '농장 동물들의 소리를 배워요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%83%E1%85%A9%E1%86%BC%E1%84%86%E1%85%AE%E1%86%AF%E1%84%82%E1%85%A9%E1%86%BC%E1%84%8C%E1%85%A1%E1%86%BC.mp3',
          lyrics:
              '꼬끼오 꼬끼오 닭이 울어요\n음메 음메 소가 울어요\n멍멍 멍멍 개가 짖어요\n야옹 야옹 고양이 울어요\n동물농장 즐거운 동물농장\n모두 모두 노래해요',
          blanks: ['소', '돼지', '닭', '양'],
          rhythmWords: ['음메음메', '꿀꿀꿀꿀', '꼬끼오', '매애매애'],
          sections: [
            SongSection(
              index: 0,
              text: '꼬끼오 꼬끼오 닭이 울어요',
              startTime: 0.0,
              endTime: 4.0,
            ),
            SongSection(
              index: 1,
              text: '음메 음메 소가 울어요',
              startTime: 4.0,
              endTime: 8.0,
            ),
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
            SongSection(
              index: 5,
              text: '모두 모두 노래해요',
              startTime: 20.0,
              endTime: 24.0,
            ),
          ],
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['동물', '농장', '소리'],
          likeCount: 52,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        MusicActivity(
          id: 'activity_4',
          title: '무지개',
          description: '아름다운 무지개 색깔을 배워요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%86%E1%85%AE%E1%84%8C%E1%85%B5%E1%84%80%E1%85%A2.mp3',
          lyrics:
              '비가 온 뒤에 하늘을 보면\n예쁜 무지개 떠 있어요\n빨주노초파남보\n일곱 빛깔 무지개\n구름 사이로 해님이 웃으면\n무지개다리 생겨나요',
          blanks: ['빨간색', '노란색', '파란색', '무지개'],
          rhythmWords: ['빨간색', '주황색', '노란색', '초록색', '파란색'],
          sections: [],
          difficulty: 3,
          ageGroup: '5-7세',
          tags: ['색깔', '자연', '학습'],
          likeCount: 29,
          isPopular: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        MusicActivity(
          id: 'activity_5',
          title: '작은별',
          description: '반짝반짝 작은별과 함께 노래해요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%8C%E1%85%A1%E1%86%A8%E1%84%8B%E1%85%B3%E1%86%AB%E1%84%87%E1%85%A7%E1%86%AF.mp3',
          lyrics: '반짝반짝 작은별\n아름답게 비추네\n서쪽 하늘에서도\n동쪽 하늘에서도\n반짝반짝 작은별\n아름답게 비추네',
          blanks: ['반짝반짝', '작은별', '서쪽', '동쪽'],
          rhythmWords: ['반짝반짝', '작은별', '아름답게', '비추네'],
          sections: [
            SongSection(
              index: 0,
              text: '반짝반짝 작은별',
              startTime: 0.0,
              endTime: 4.0,
            ),
            SongSection(
              index: 1,
              text: '아름답게 비추네',
              startTime: 4.0,
              endTime: 8.0,
            ),
            SongSection(
              index: 2,
              text: '서쪽 하늘에서도',
              startTime: 8.0,
              endTime: 12.0,
            ),
            SongSection(
              index: 3,
              text: '동쪽 하늘에서도',
              startTime: 12.0,
              endTime: 16.0,
            ),
            SongSection(
              index: 4,
              text: '반짝반짝 작은별',
              startTime: 16.0,
              endTime: 20.0,
            ),
            SongSection(
              index: 5,
              text: '아름답게 비추네',
              startTime: 20.0,
              endTime: 24.0,
            ),
          ],
          difficulty: 2,
          ageGroup: '4-6세',
          tags: ['밤', '별', '클래식'],
          likeCount: 67,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        MusicActivity(
          id: 'activity_6',
          title: '아기상어',
          description: '바다 속 상어 가족을 만나요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%8B%E1%85%A1%E1%84%80%E1%85%B5%E1%84%89%E1%85%A1%E1%86%BC%E1%84%8B%E1%85%A5+%E1%84%84%E1%85%AE%E1%84%85%E1%85%AE%E1%84%85%E1%85%AE%E1%84%84%E1%85%AE%E1%84%85%E1%85%AE.mp3',
          lyrics:
              '아기상어 뚜루루뚜루\n아기상어 뚜루루뚜루\n아기상어 뚜루루뚜루\n아기상어\n엄마상어 뚜루루뚜루\n엄마상어 뚜루루뚜루\n엄마상어 뚜루루뚜루\n엄마상어',
          blanks: ['아기상어', '귀여운', '바다속', '뚜루루'],
          rhythmWords: ['뚜루루뚜루', '아기상어', '귀여운', '바다속'],
          sections: [
            SongSection(
              index: 0,
              text: '아기상어 뚜루루뚜루',
              startTime: 0.0,
              endTime: 3.0,
            ),
            SongSection(
              index: 1,
              text: '아기상어 뚜루루뚜루',
              startTime: 3.0,
              endTime: 6.0,
            ),
            SongSection(
              index: 2,
              text: '아기상어 뚜루루뚜루',
              startTime: 6.0,
              endTime: 9.0,
            ),
            SongSection(index: 3, text: '아기상어', startTime: 9.0, endTime: 11.0),
            SongSection(
              index: 4,
              text: '엄마상어 뚜루루뚜루',
              startTime: 11.0,
              endTime: 14.0,
            ),
            SongSection(
              index: 5,
              text: '엄마상어 뚜루루뚜루',
              startTime: 14.0,
              endTime: 17.0,
            ),
            SongSection(
              index: 6,
              text: '엄마상어 뚜루루뚜루',
              startTime: 17.0,
              endTime: 20.0,
            ),
            SongSection(index: 7, text: '엄마상어', startTime: 20.0, endTime: 22.0),
          ],
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['바다', '동물', '인기'],
          likeCount: 128,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        MusicActivity(
          id: 'activity_7',
          title: '생일축하',
          description: '생일 축하 노래를 불러요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%89%E1%85%A2%E1%86%BC%E1%84%8B%E1%85%B5%E1%86%AF%E1%84%8E%E1%85%AE%E1%86%A8%E1%84%92%E1%85%A1.mp3',
          lyrics:
              '생일축하합니다\n생일축하합니다\n사랑하는 우리 아이\n생일축하합니다\n건강하게 자라나요\n행복하게 자라나요\n사랑하는 우리 아이\n생일축하합니다',
          blanks: ['생일', '축하합니다', '사랑하는', '친구'],
          rhythmWords: ['생일', '축하', '사랑', '친구'],
          sections: [],
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['축하', '생일', '기념'],
          likeCount: 95,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        MusicActivity(
          id: 'activity_8',
          title: '과일송',
          description: '맛있는 과일들을 배워요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%80%E1%85%AA%E1%84%8B%E1%85%B5%E1%86%AF%E1%84%89%E1%85%A9%E1%86%BC.mp3',
          lyrics:
              '빨간 사과 맛있어요\n노란 바나나 달콤해요\n초록 포도 새콤해요\n주황 귤은 상큼해요\n과일 과일 맛있는 과일\n몸에 좋은 과일\n매일 매일 먹어요',
          blanks: ['사과', '바나나', '포도', '딸기'],
          rhythmWords: ['빨갛고', '노랗고', '보라색', '새콤달콤'],
          sections: [],
          difficulty: 2,
          ageGroup: '4-6세',
          tags: ['음식', '과일', '건강'],
          likeCount: 73,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        ),
        MusicActivity(
          id: 'activity_9',
          title: '숫자송',
          description: '1부터 10까지 숫자를 배워요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%89%E1%85%AE%E1%86%BA%E1%84%8C%E1%85%A1%E1%84%89%E1%85%A9%E1%86%BC.mp3',
          lyrics:
              '하나 둘 셋 넷 다섯\n여섯 일곱 여덟 아홉 열\n숫자를 세어보아요\n하나씩 하나씩 세어보아요\n우리 모두 함께 세어보아요',
          blanks: ['하나', '다섯', '열', '숫자'],
          rhythmWords: ['하나', '둘셋', '넷다섯', '여섯일곱'],
          sections: [],
          difficulty: 2,
          ageGroup: '4-6세',
          tags: ['숫자', '학습', '기초'],
          likeCount: 84,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        MusicActivity(
          id: 'activity_10',
          title: '색깔송',
          description: '다양한 색깔을 배워요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%89%E1%85%A2%E1%86%A8%E1%84%81%E1%85%A1%E1%86%AF%E1%84%89%E1%85%A9%E1%86%BC.mp3',
          lyrics:
              '빨간색 빨간색 사과같이 빨간색\n노란색 노란색 바나나같이 노란색\n파란색 파란색 하늘같이 파란색\n초록색 초록색 나무같이 초록색',
          blanks: ['빨간색', '노란색', '파란색', '초록색'],
          rhythmWords: ['빨간색', '노란색', '파란색', '초록색'],
          sections: [],
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['색깔', '학습', '기초'],
          likeCount: 91,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 9)),
        ),
      ];

      // 배치로 데이터 추가
      final batch = _firestore.batch();
      for (final activity in sampleActivities) {
        final docRef = _firestore.collection('activities').doc(activity.id);
        batch.set(docRef, activity.toJson());
      }

      await batch.commit();
      print('샘플 활동 데이터 ${sampleActivities.length}개가 추가되었습니다.');
      print('인기 활동: ${sampleActivities.where((a) => a.isPopular).length}개');
      print('일반 활동: ${sampleActivities.where((a) => !a.isPopular).length}개');
    } catch (e) {
      print('샘플 데이터 추가 실패: $e');
      rethrow;
    }
  }

  // 오디오 URL 생성 또는 가져오기 (실제 구현에서는 TTS 또는 미리 업로드된 파일 사용)
  static Future<String> _getOrCreateAudioUrl(
    String fileName,
    String text,
  ) async {
    try {
      // Firebase Storage가 설정되지 않은 경우 플레이스홀더 URL 반환
      // 실제 구현에서는 여기서 TTS로 오디오 생성하고 업로드
      print('오디오 파일 $fileName 생성 필요 (TTS: $text)');
      return 'placeholder://audio/$fileName'; // 플레이스홀더 URL
    } catch (e) {
      print('오디오 URL 생성 실패: $e');
      return 'placeholder://audio/$fileName';
    }
  }

  static Future<void> clearAllData() async {
    try {
      // 모든 컬렉션의 데이터 삭제
      final collections = ['activities', 'user_activities', 'parent_feedback'];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        print('$collection 컬렉션의 모든 데이터가 삭제되었습니다.');
      }
    } catch (e) {
      print('데이터 삭제 실패: $e');
      rethrow;
    }
  }

  // 실제 TTS 오디오 생성 및 업로드 (향후 구현)
  static Future<String?> _generateAndUploadTTS(
    String text,
    String fileName,
  ) async {
    try {
      // 실제 구현에서는 다음과 같은 과정을 거칩니다:
      // 1. Google TTS API 또는 다른 TTS 서비스 호출
      // 2. 오디오 파일 생성
      // 3. Firebase Storage에 업로드
      // 4. 다운로드 URL 반환

      print('TTS 생성 예정: $text -> $fileName');
      return null; // 임시로 null 반환
    } catch (e) {
      print('TTS 생성 실패: $e');
      return null;
    }
  }

  // Firebase에 새로운 S3 URL 데이터를 강제로 업로드 (기존 데이터 덮어쓰기)
  static Future<void> forceUpdateActivities() async {
    try {
      print('새로운 S3 URL 활동 데이터로 강제 업데이트 중...');

      // 기존 addSampleActivities와 동일한 데이터를 강제로 덮어쓰기
      final sampleActivities = [
        MusicActivity(
          id: 'activity_1',
          title: '곰 세 마리',
          description: '귀여운 곰 세 마리와 함께 노래해요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%80%E1%85%A9%E1%86%B7+%E1%84%89%E1%85%A6+%E1%84%86%E1%85%A1%E1%84%85%E1%85%B5+(bears_song.mp3).mp3',
          lyrics:
              '곰 세 마리가 한 집에 있어\n아빠 곰, 엄마 곰, 애기 곰\n아빠 곰은 뚱뚱해\n엄마 곰은 날씬해\n애기 곰은 너무 귀여워\n으쓱으쓱 잘한다',
          blanks: ['곰', '집', '뚱뚱해', '날씬해'],
          rhythmWords: ['곰', '세마리', '뚱뚱해', '날씬해', '귀여워'],
          sections: [], // TODO: 구간 정보 추가 예정
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['동물', '가족', '기초'],
          likeCount: 45,
          isPopular: true,
          createdAt: DateTime.now(),
        ),
        MusicActivity(
          id: 'activity_2',
          title: '나비야',
          description: '예쁜 나비와 함께 춤춰요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%82%E1%85%A1%E1%84%87%E1%85%B5%E1%84%8B%E1%85%A3.mp3',
          lyrics:
              '나비야 나비야 이리 날아와\n노랑나비 흰나비 어서 날아와\n봄바람에 꽃잎도 방긋방긋 웃는데\n너도 나도 즐겁게 춤을 추어라',
          blanks: ['나비야', '노랑나비', '봄바람', '참새'],
          rhythmWords: ['나비야', '날아와', '춤을춰', '웃으며', '노래해'],
          sections: [], // TODO: 구간 정보 추가 예정
          difficulty: 2,
          ageGroup: '4-6세',
          tags: ['자연', '곤충', '봄'],
          likeCount: 38,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        MusicActivity(
          id: 'activity_3',
          title: '동물농장',
          description: '농장 동물들의 소리를 배워요',
          audioUrl:
              'https://dearglobe.s3.ap-northeast-2.amazonaws.com/rythmtalktalk/musics/%E1%84%83%E1%85%A9%E1%86%BC%E1%84%86%E1%85%AE%E1%86%AF%E1%84%82%E1%85%A9%E1%86%BC%E1%84%8C%E1%85%A1%E1%86%BC.mp3',
          lyrics:
              '꼬끼오 꼬끼오 닭이 울어요\n음메 음메 소가 울어요\n멍멍 멍멍 개가 짖어요\n야옹 야옹 고양이 울어요\n동물농장 즐거운 동물농장\n모두 모두 노래해요',
          blanks: ['소', '돼지', '닭', '양'],
          rhythmWords: ['음메음메', '꿀꿀꿀꿀', '꼬끼오', '매애매애'],
          sections: [], // TODO: 구간 정보 추가 예정
          difficulty: 1,
          ageGroup: '3-5세',
          tags: ['동물', '농장', '소리'],
          likeCount: 52,
          isPopular: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        // 추가 활동들...
      ];

      // 배치로 데이터 강제 덮어쓰기
      final batch = _firestore.batch();
      for (final activity in sampleActivities) {
        final docRef = _firestore.collection('activities').doc(activity.id);
        batch.set(docRef, activity.toJson(), SetOptions(merge: false)); // 덮어쓰기
      }

      await batch.commit();
      print('활동 데이터 강제 업데이트 완료! ${sampleActivities.length}개 활동');
    } catch (e) {
      print('활동 데이터 강제 업데이트 실패: $e');
    }
  }
}
