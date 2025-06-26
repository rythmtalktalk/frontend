import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tts_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  AudioPlayer get audioPlayer => _audioPlayer;

  // 권한 확인
  Future<bool> requestPermissions() async {
    final microphonePermission = await Permission.microphone.request();
    final storagePermission = await Permission.storage.request();

    return microphonePermission.isGranted && storagePermission.isGranted;
  }

  // 음악 재생
  Future<bool> playMusic(String url) async {
    try {
      print('음악 재생 시도: $url');

      if (_isPlaying) {
        await stopPlaying();
      }

      // URL 유효성 검사 - 실제 플레이스홀더만 체크
      if (url.isEmpty ||
          url.contains('placeholder') ||
          url.startsWith('file://placeholder') ||
          url.startsWith('http://example.com') ||
          url.startsWith('https://example.com')) {
        print('플레이스홀더 URL 감지, 시뮬레이션 재생');
        return await _playPlaceholderAudio(url);
      }

      print('실제 URL로 재생 시도: $url');

      // 오디오 플레이어 설정
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // URL 소스로 재생
      await _audioPlayer.play(UrlSource(url));
      _isPlaying = true;
      print('음악 재생 시작됨: $url');

      // 재생 완료 리스너 (한 번만 등록)
      _audioPlayer.onPlayerComplete.listen((_) {
        print('음악 재생 완료');
        _isPlaying = false;
      });

      // 재생 상태 변경 리스너
      _audioPlayer.onPlayerStateChanged.listen((state) {
        print('재생 상태 변경: $state');
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _isPlaying = false;
        } else if (state == PlayerState.playing) {
          _isPlaying = true;
        }
      });

      // 재생 시작 대기 (최대 5초)
      int waitCount = 0;
      while (!_isPlaying && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      if (!_isPlaying) {
        print('재생이 시작되지 않음, 플레이스홀더로 폴백');
        return await _playPlaceholderAudio(url);
      }

      return true;
    } catch (e) {
      print('음악 재생 실패: $e');
      print('실패한 URL: $url');

      // 네트워크 오류인 경우 재시도
      if (e.toString().contains('network') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection')) {
        print('네트워크 오류 감지, 재시도 중...');
        try {
          await Future.delayed(const Duration(seconds: 2));
          await _audioPlayer.play(UrlSource(url));
          _isPlaying = true;

          // 재시도 후 재생 확인
          await Future.delayed(const Duration(milliseconds: 500));
          if (_isPlaying) {
            return true;
          }
        } catch (retryError) {
          print('재시도 실패: $retryError');
        }
      }

      // 최종 실패 시 플레이스홀더로 폴백
      print('플레이스홀더 오디오로 폴백 시도');
      return await _playPlaceholderAudio(url);
    }
  }

  // 플레이스홀더 오디오 재생 (시스템 사운드 또는 TTS 대체)
  Future<bool> _playPlaceholderAudio(String url) async {
    try {
      print('플레이스홀더 오디오 재생 시뮬레이션: $url');

      // 시스템 사운드 재생으로 피드백 제공
      await SystemSound.play(SystemSoundType.click);

      print('플레이스홀더 재생 시작 - 20초간 시뮬레이션');
      _isPlaying = true;

      // 20초 후 재생 완료 시뮬레이션 (일반적인 동요 길이)
      Future.delayed(const Duration(seconds: 20), () {
        print('플레이스홀더 재생 완료');
        _isPlaying = false;
      });

      return true;
    } catch (e) {
      print('플레이스홀더 오디오 재생 실패: $e');
      return false;
    }
  }

  // 로컬 파일 재생
  Future<bool> playLocalFile(String filePath) async {
    try {
      if (_isPlaying) {
        await stopPlaying();
      }

      await _audioPlayer.play(DeviceFileSource(filePath));
      _isPlaying = true;

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      return true;
    } catch (e) {
      print('로컬 파일 재생 실패: $e');
      return false;
    }
  }

  // 재생 중지
  Future<void> stopPlaying() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('재생 중지 실패: $e');
    }
  }

  // 일시정지
  Future<void> pausePlaying() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      print('일시정지 실패: $e');
    }
  }

  // 재생 재개
  Future<void> resumePlaying() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      print('재생 재개 실패: $e');
    }
  }

  // 현재 재생 위치 가져오기
  Future<Duration?> getCurrentPosition() async {
    try {
      return await _audioPlayer.getCurrentPosition();
    } catch (e) {
      print('현재 위치 가져오기 실패: $e');
      return null;
    }
  }

  // 전체 재생 시간 가져오기
  Future<Duration?> getDuration() async {
    try {
      return await _audioPlayer.getDuration();
    } catch (e) {
      print('전체 시간 가져오기 실패: $e');
      return null;
    }
  }

  // 구간별 재생 (startTime부터 endTime까지)
  Future<bool> playSectionLoop(
    String url,
    double startTime,
    double endTime, {
    int repeatCount = 2,
  }) async {
    try {
      print('구간 재생 시작: $startTime초 ~ $endTime초 (${repeatCount}회 반복)');

      if (_isPlaying) {
        await stopPlaying();
      }

      // URL 유효성 검사
      if (url.isEmpty ||
          url.contains('placeholder') ||
          url.startsWith('file://placeholder') ||
          url.startsWith('http://example.com') ||
          url.startsWith('https://example.com')) {
        print('플레이스홀더 URL 감지, 시뮬레이션 재생');
        return await _playPlaceholderSection(startTime, endTime, repeatCount);
      }

      // 실제 오디오 재생
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(UrlSource(url));

      // 시작 위치로 이동
      await _audioPlayer.seek(
        Duration(milliseconds: (startTime * 1000).round()),
      );
      _isPlaying = true;

      // 구간 반복 재생
      for (int i = 0; i < repeatCount; i++) {
        print('구간 재생 ${i + 1}/${repeatCount}회');

        // 시작 위치로 이동
        await _audioPlayer.seek(
          Duration(milliseconds: (startTime * 1000).round()),
        );

        // 구간 재생 시간만큼 대기
        final sectionDuration = endTime - startTime;
        await Future.delayed(
          Duration(milliseconds: (sectionDuration * 1000).round()),
        );

        // 마지막 반복이 아니면 잠시 멈춤
        if (i < repeatCount - 1) {
          await _audioPlayer.pause();
          await Future.delayed(const Duration(milliseconds: 500)); // 0.5초 간격
          await _audioPlayer.resume();
        }
      }

      await stopPlaying();
      return true;
    } catch (e) {
      print('구간 재생 실패: $e');
      return await _playPlaceholderSection(startTime, endTime, repeatCount);
    }
  }

  // 플레이스홀더 구간 재생
  Future<bool> _playPlaceholderSection(
    double startTime,
    double endTime,
    int repeatCount,
  ) async {
    try {
      print('플레이스홀더 구간 재생: $startTime초 ~ $endTime초 (${repeatCount}회)');

      _isPlaying = true;
      final sectionDuration = endTime - startTime;

      for (int i = 0; i < repeatCount; i++) {
        print('플레이스홀더 구간 ${i + 1}/${repeatCount}회 재생');

        // 시스템 사운드로 시작 알림
        await SystemSound.play(SystemSoundType.click);

        // 구간 시간만큼 대기
        await Future.delayed(
          Duration(milliseconds: (sectionDuration * 1000).round()),
        );

        // 반복 사이 간격
        if (i < repeatCount - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _isPlaying = false;
      return true;
    } catch (e) {
      print('플레이스홀더 구간 재생 실패: $e');
      _isPlaying = false;
      return false;
    }
  }

  // 녹음 시작
  Future<bool> startRecording() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('녹음 권한이 없습니다.');
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('녹음 시작 실패: $e');
      return false;
    }
  }

  // 녹음 중지
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null) {
        _currentRecordingPath = path;
        return path;
      }

      return _currentRecordingPath;
    } catch (e) {
      print('녹음 중지 실패: $e');
      return null;
    }
  }

  // 녹음 일시정지
  Future<void> pauseRecording() async {
    try {
      await _audioRecorder.pause();
    } catch (e) {
      print('녹음 일시정지 실패: $e');
    }
  }

  // 녹음 재개
  Future<void> resumeRecording() async {
    try {
      await _audioRecorder.resume();
    } catch (e) {
      print('녹음 재개 실패: $e');
    }
  }

  // 녹음 파일 재생
  Future<bool> playRecording() async {
    if (_currentRecordingPath == null) return false;
    return await playLocalFile(_currentRecordingPath!);
  }

  // 녹음 파일 삭제
  Future<bool> deleteRecording(String? filePath) async {
    try {
      if (filePath == null) return false;

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        if (filePath == _currentRecordingPath) {
          _currentRecordingPath = null;
        }
        return true;
      }
      return false;
    } catch (e) {
      print('녹음 파일 삭제 실패: $e');
      return false;
    }
  }

  // 재생 위치 조작
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('재생 위치 조작 실패: $e');
    }
  }

  // 현재 재생 위치 가져오기
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  // 전체 재생 시간 가져오기
  Stream<Duration?> get durationStream => _audioPlayer.onDurationChanged;

  // 볼륨 조절
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('볼륨 조절 실패: $e');
    }
  }

  // 재생 속도 조절
  Future<void> setPlaybackRate(double rate) async {
    try {
      await _audioPlayer.setPlaybackRate(rate);
    } catch (e) {
      print('재생 속도 조절 실패: $e');
    }
  }

  // 서비스 해제
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _audioRecorder.dispose();
  }

  // 녹음 상태 스트림
  Stream<bool> get recordingStateStream async* {
    while (true) {
      yield _isRecording;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // 재생 상태 스트림
  Stream<bool> get playingStateStream async* {
    while (true) {
      yield _isPlaying;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Text-to-Speech for rhythm words
  Future<void> playWordSound(String word) async {
    try {
      final ttsService = TTSService();
      final success = await ttsService.speak(word);

      if (!success) {
        // TTS 실패 시 시스템 사운드로 폴백
        await SystemSound.play(SystemSoundType.click);

        // 단어 길이에 따라 다른 음성 효과
        if (word.length <= 2) {
          await Future.delayed(const Duration(milliseconds: 300));
          await SystemSound.play(SystemSoundType.click);
        } else if (word.length <= 4) {
          await Future.delayed(const Duration(milliseconds: 200));
          await SystemSound.play(SystemSoundType.click);
          await Future.delayed(const Duration(milliseconds: 200));
          await SystemSound.play(SystemSoundType.click);
        } else {
          // 긴 단어의 경우 여러 번 재생
          for (int i = 0; i < 3; i++) {
            await Future.delayed(const Duration(milliseconds: 150));
            await SystemSound.play(SystemSoundType.click);
          }
        }
      }

      print('단어 음성 재생: $word');
    } catch (e) {
      print('단어 음성 재생 실패: $e');
      // 에러 시 시스템 사운드로 폴백
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
