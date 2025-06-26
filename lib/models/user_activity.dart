class UserActivity {
  final String id;
  final String userId;
  final String activityId;
  final DateTime completedAt;
  final bool isCompleted;
  final String? recordingUrl; // 녹음 파일 URL
  final Map<String, String> blankAnswers; // 빈칸 채우기 답변
  final int score; // 0-100점
  final List<String> parentFeedback; // 부모 피드백
  final int stickers; // 획득한 스티커 개수

  // 발음 분석 데이터 추가
  final String? recognizedText; // STT로 인식된 텍스트
  final int? pronunciationScore; // 발음 점수 (0-100)
  final Map<String, double>? wordAccuracies; // 단어별 정확도
  final String? pronunciationFeedback; // 발음 피드백 메시지
  final Map<String, int>? detailedScores; // 상세 점수 (리듬, 발음, 빈칸 등)

  UserActivity({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.completedAt,
    required this.isCompleted,
    this.recordingUrl,
    required this.blankAnswers,
    required this.score,
    required this.parentFeedback,
    this.stickers = 1,
    this.recognizedText,
    this.pronunciationScore,
    this.wordAccuracies,
    this.pronunciationFeedback,
    this.detailedScores,
  });

  // copyWith 메서드 추가
  UserActivity copyWith({
    String? id,
    String? userId,
    String? activityId,
    DateTime? completedAt,
    bool? isCompleted,
    String? recordingUrl,
    Map<String, String>? blankAnswers,
    int? score,
    List<String>? parentFeedback,
    int? stickers,
    String? recognizedText,
    int? pronunciationScore,
    Map<String, double>? wordAccuracies,
    String? pronunciationFeedback,
    Map<String, int>? detailedScores,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      blankAnswers: blankAnswers ?? this.blankAnswers,
      score: score ?? this.score,
      parentFeedback: parentFeedback ?? this.parentFeedback,
      stickers: stickers ?? this.stickers,
      recognizedText: recognizedText ?? this.recognizedText,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      wordAccuracies: wordAccuracies ?? this.wordAccuracies,
      pronunciationFeedback:
          pronunciationFeedback ?? this.pronunciationFeedback,
      detailedScores: detailedScores ?? this.detailedScores,
    );
  }

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      activityId: json['activityId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      isCompleted: json['isCompleted'] as bool,
      recordingUrl: json['recordingUrl'] as String?,
      blankAnswers: Map<String, String>.from(json['blankAnswers'] as Map),
      score: json['score'] as int,
      parentFeedback: List<String>.from(json['parentFeedback'] as List),
      stickers: json['stickers'] as int? ?? 1,
      recognizedText: json['recognizedText'] as String?,
      pronunciationScore: json['pronunciationScore'] as int?,
      wordAccuracies: json['wordAccuracies'] != null
          ? Map<String, double>.from(json['wordAccuracies'] as Map)
          : null,
      pronunciationFeedback: json['pronunciationFeedback'] as String?,
      detailedScores: json['detailedScores'] != null
          ? Map<String, int>.from(json['detailedScores'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'completedAt': completedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'recordingUrl': recordingUrl,
      'blankAnswers': blankAnswers,
      'score': score,
      'parentFeedback': parentFeedback,
      'stickers': stickers,
      'recognizedText': recognizedText,
      'pronunciationScore': pronunciationScore,
      'wordAccuracies': wordAccuracies,
      'pronunciationFeedback': pronunciationFeedback,
      'detailedScores': detailedScores,
    };
  }
}

class ParentFeedback {
  final String id;
  final String userId;
  final String activityId;
  final DateTime date;
  final bool didChildParticipate; // 아이가 잘 참여했나요?
  final bool noticedImprovement; // 언어발달 변화를 체감하나요?
  final int engagementLevel; // 1-5 참여도
  final String? additionalComments; // 추가 의견

  ParentFeedback({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.date,
    required this.didChildParticipate,
    required this.noticedImprovement,
    required this.engagementLevel,
    this.additionalComments,
  });

  factory ParentFeedback.fromJson(Map<String, dynamic> json) {
    return ParentFeedback(
      id: json['id'] as String,
      userId: json['userId'] as String,
      activityId: json['activityId'] as String,
      date: DateTime.parse(json['date'] as String),
      didChildParticipate: json['didChildParticipate'] as bool,
      noticedImprovement: json['noticedImprovement'] as bool,
      engagementLevel: json['engagementLevel'] as int,
      additionalComments: json['additionalComments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'date': date.toIso8601String(),
      'didChildParticipate': didChildParticipate,
      'noticedImprovement': noticedImprovement,
      'engagementLevel': engagementLevel,
      'additionalComments': additionalComments,
    };
  }
}
