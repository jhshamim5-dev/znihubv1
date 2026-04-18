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
  final int? introStart;
  final int? introEnd;

  CustomStream(
      {required this.ep, required this.m3u8, this.introStart, this.introEnd});

  factory CustomStream.fromJson(Map<String, dynamic> json) {
    int? iStart;
    int? iEnd;

    // Parse Intro Timeskits (different scrapers use different keys)
    final introRaw = json['intro'] ??
        (json['timeskip'] != null ? json['timeskip']['intro'] : null);
    if (introRaw != null) {
      if (introRaw is List && introRaw.length == 2) {
        iStart = int.tryParse(introRaw[0].toString());
        iEnd = int.tryParse(introRaw[1].toString());
      } else if (introRaw is Map) {
        iStart = int.tryParse(introRaw['start'].toString());
        iEnd = int.tryParse(introRaw['end'].toString());
      }
    }

    return CustomStream(
      ep: json['ep'] ?? '1',
      m3u8: json['stream'] != null
          ? (json['stream']['m3u8'] ?? '')
          : (json['m3u8'] ?? ''),
      introStart: iStart,
      introEnd: iEnd,
    );
  }
}

class CustomChapter {
  final String title;
  final num number;
  final String id;

  CustomChapter({required this.title, required this.number, required this.id});
  factory CustomChapter.fromJson(Map<String, dynamic> json) {
    return CustomChapter(
      title: json['title'] ?? '',
      number: num.tryParse(json['number'].toString()) ?? 0,
      id: json['id'] ?? '',
    );
  }
}
