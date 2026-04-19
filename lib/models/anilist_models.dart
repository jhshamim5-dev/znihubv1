class Title {
  final String english;
  final String romaji;
  Title({required this.english, required this.romaji});
  factory Title.fromJson(Map<String, dynamic> json) =>
      Title(english: json['english'] ?? '', romaji: json['romaji'] ?? '');
  String get display => english.isNotEmpty ? english : romaji;
}

class CoverImage {
  final String large;
  final String extraLarge;
  CoverImage({required this.large, required this.extraLarge});
  factory CoverImage.fromJson(Map<String, dynamic> json) => CoverImage(
      large: json['large'] ?? '', extraLarge: json['extraLarge'] ?? '');
}

class Trailer {
  final String id;
  final String site;
  final String thumbnail;
  Trailer({required this.id, required this.site, required this.thumbnail});
  factory Trailer.fromJson(Map<String, dynamic> json) => Trailer(
      id: json['id']?.toString() ?? '',
      site: json['site']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '');
}

class Person {
  final String name;
  final String image;
  final String role;
  Person({required this.name, required this.image, required this.role});
}

class NextAiringEpisode {
  final int timeUntilAiring;
  final int episode;
  NextAiringEpisode({required this.timeUntilAiring, required this.episode});
  factory NextAiringEpisode.fromJson(Map<String, dynamic> json) =>
      NextAiringEpisode(
          timeUntilAiring: json['timeUntilAiring'] ?? 0,
          episode: json['episode'] ?? 0);
}

class AniListMedia {
  final int id;
  final int? idMal; // ADDED MAL ID FOR ANISKIP!
  final String type;
  final Title title;
  final CoverImage coverImage;
  final String? bannerImage;
  final int? averageScore;
  final String description;
  final String status;
  final String format;
  final int? seasonYear;
  final int? episodes;
  final int? chapters;
  final int? duration;
  final List<String> genres;
  final NextAiringEpisode? nextAiringEpisode;
  final List<Person> characters;
  final List<Person> staff;
  final String studio;
  final Trailer? trailer;
  final List<AniListMedia> recommendations;

  AniListMedia(
      {required this.id,
      this.idMal,
      required this.type,
      required this.title,
      required this.coverImage,
      this.bannerImage,
      this.averageScore,
      this.description = '',
      this.status = '',
      this.format = '',
      this.seasonYear,
      this.episodes,
      this.chapters,
      this.duration,
      this.genres = const [],
      this.nextAiringEpisode,
      this.characters = const [],
      this.staff = const [],
      this.studio = '',
      this.trailer,
      this.recommendations = const []});

  factory AniListMedia.fromJson(Map<String, dynamic> json) {
    List<Person> charList = [];
    if (json['characters']?['edges'] != null)
      charList = (json['characters']['edges'] as List)
          .map((e) => Person(
              name: e['node']['name']['full'] ?? '',
              image: e['node']['image']['large'] ?? '',
              role: e['role'] ?? ''))
          .toList();
    List<Person> staffList = [];
    if (json['staff']?['edges'] != null)
      staffList = (json['staff']['edges'] as List)
          .map((e) => Person(
              name: e['node']['name']['full'] ?? '',
              image: e['node']['image']['large'] ?? '',
              role: e['role'] ?? ''))
          .toList();
    List<AniListMedia> recList = [];
    if (json['recommendations']?['nodes'] != null)
      recList = (json['recommendations']['nodes'] as List)
          .where((e) => e['mediaRecommendation'] != null)
          .map((e) => AniListMedia.fromJson(e['mediaRecommendation']))
          .toList();

    return AniListMedia(
      id: json['id'],
      idMal: json['idMal'], // GRAB MAL ID
      type: json['type'] ?? 'ANIME',
      title: Title.fromJson(json['title'] ?? {}),
      coverImage: CoverImage.fromJson(json['coverImage'] ?? {}),
      bannerImage: json['bannerImage'], averageScore: json['averageScore'],
      description: json['description'] ?? 'No description available.',
      status: json['status'] ?? 'UNKNOWN', format: json['format'] ?? '',
      seasonYear: json['seasonYear'], episodes: json['episodes'],
      chapters: json['chapters'], duration: json['duration'],
      genres:
          (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
      characters: charList,
      staff: staffList,
      studio: json['studios']?['edges']?.isNotEmpty == true
          ? json['studios']['edges'][0]['node']['name']
          : '',
      trailer:
          json['trailer'] != null ? Trailer.fromJson(json['trailer']) : null,
      recommendations: recList,
    );
  }
}
