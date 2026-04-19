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
  final int? outroStart;
  final int? outroEnd;

  CustomStream(
      {required this.ep,
      required this.m3u8,
      this.introStart,
      this.introEnd,
      this.outroStart,
      this.outroEnd});

  factory CustomStream.fromJson(Map<String, dynamic> json) {
    int? iStart, iEnd, oStart, oEnd;

    // Safely parse timeskips whether they are nested in 'timeskip' or root
    final timeskip = json['timeskip'] ?? json;

    // INTRO PARSER
    final introRaw = timeskip['intro'];
    if (introRaw != null) {
      if (introRaw is List && introRaw.length >= 2) {
        iStart = int.tryParse(introRaw[0].toString());
        iEnd = int.tryParse(introRaw[1].toString());
      } else if (introRaw is Map) {
        iStart = int.tryParse(introRaw['start'].toString());
        iEnd = int.tryParse(introRaw['end'].toString());
      }
    }

    // OUTRO PARSER
    final outroRaw = timeskip['outro'];
    if (outroRaw != null) {
      if (outroRaw is List && outroRaw.length >= 2) {
        oStart = int.tryParse(outroRaw[0].toString());
        oEnd = int.tryParse(outroRaw[1].toString());
      } else if (outroRaw is Map) {
        oStart = int.tryParse(outroRaw['start'].toString());
        oEnd = int.tryParse(outroRaw['end'].toString());
      }
    }

    return CustomStream(
      ep: json['ep'] ?? '1',
      m3u8: json['stream'] != null
          ? (json['stream']['m3u8'] ?? '')
          : (json['m3u8'] ?? ''),
      introStart: iStart,
      introEnd: iEnd,
      outroStart: oStart,
      outroEnd: oEnd,
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
