// 노래 구간 정보
class SongSection {
  final int index; // 구간 순서
  final String text; // 해당 구간의 가사
  final double startTime; // 시작 시간 (초)
  final double endTime; // 끝 시간 (초)

  SongSection({
    required this.index,
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory SongSection.fromJson(Map<String, dynamic> json) {
    return SongSection(
      index: json['index'] as int,
      text: json['text'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'text': text,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class MusicActivity {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String lyrics;
  final List<String> blanks; // 빈칸 채우기 문제
  final List<String> rhythmWords; // 리듬 따라하기 단어들
  final List<SongSection> sections; // 노래 구간들
  final int difficulty; // 1-5 난이도
  final String ageGroup; // "3-4", "5-7" 등
  final List<String> tags;
  final DateTime createdAt;
  final int likeCount;
  final bool isPopular;

  MusicActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.lyrics,
    required this.blanks,
    required this.rhythmWords,
    required this.sections,
    required this.difficulty,
    required this.ageGroup,
    required this.tags,
    required this.createdAt,
    this.likeCount = 0,
    this.isPopular = false,
  });

  factory MusicActivity.fromJson(Map<String, dynamic> json) {
    return MusicActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      audioUrl: json['audioUrl'] as String,
      lyrics: json['lyrics'] as String,
      blanks: List<String>.from(json['blanks'] as List),
      rhythmWords: List<String>.from(json['rhythmWords'] as List),
      sections: (json['sections'] as List? ?? [])
          .map((e) => SongSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: json['difficulty'] as int,
      ageGroup: json['ageGroup'] as String,
      tags: List<String>.from(json['tags'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'lyrics': lyrics,
      'blanks': blanks,
      'rhythmWords': rhythmWords,
      'sections': sections.map((e) => e.toJson()).toList(),
      'difficulty': difficulty,
      'ageGroup': ageGroup,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'isPopular': isPopular,
    };
  }
}
