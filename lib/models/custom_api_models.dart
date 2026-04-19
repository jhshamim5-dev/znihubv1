class CustomEpisode {
  final String title;
  final num number;
  final bool isSub;
  final bool isDub;

  CustomEpisode(
      {required this.title,
      required this.number,
      required this.isSub,
      required this.isDub});

  factory CustomEpisode.fromJson(Map<String, dynamic> json) {
    return CustomEpisode(
      title: json['title'] ?? '',
      number: num.tryParse(json['number'].toString()) ?? 0,
      isSub: json['isSub'] ?? true,
      isDub: json['isDub'] ?? true,
    );
  }
}

class CustomStream {
  final String ep;
  final String m3u8;
  // Removed 'final' so we can overwrite these with accurate AniSkip data later!
  int? introStart;
  int? introEnd;
  int? outroStart;
  int? outroEnd;

  CustomStream(
      {required this.ep,
      required this.m3u8,
      this.introStart,
      this.introEnd,
      this.outroStart,
      this.outroEnd});

  factory CustomStream.fromJson(Map<String, dynamic> json) {
    return CustomStream(
      ep: json['ep'] ?? '1',
      m3u8: json['stream'] != null
          ? (json['stream']['m3u8'] ?? '')
          : (json['m3u8'] ?? ''),
    );
  }
}

class CustomChapter {
  final String title;
  final num number;
  final String id;

  CustomChapter({required this.title, required this.number, required this.id});
  factory CustomChapter.fromJson(Map<String, dynamic> json) => CustomChapter(
      title: json['title'] ?? '',
      number: num.tryParse(json['number'].toString()) ?? 0,
      id: json['id'] ?? '');
}
