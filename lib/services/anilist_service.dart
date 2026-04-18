import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anilist_models.dart';

class AniListService {
  static const String _url = 'https://graphql.anilist.co';

  static Future<Map<String, dynamic>> _query(
      String query, Map<String, dynamic> variables) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({'query': query, 'variables': variables}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception('Failed to load AniList data');
  }

  static Future<List<AniListMedia>> searchMedia(
      String search, String type) async {
    const query = '''
      query (\$search: String, \$type: MediaType) {
        Page(page: 1, perPage: 20) { media(search: \$search, type: \$type, isAdult: false, sort: POPULARITY_DESC) { id type averageScore bannerImage title { english romaji } coverImage { extraLarge large } } }
      }
    ''';
    final data = await _query(query, {'search': search, 'type': type});
    return (data['Page']['media'] as List)
        .map((json) => AniListMedia.fromJson(json))
        .toList();
  }

  static Future<Map<String, List<AniListMedia>>> fetchHomeData(
      String type) async {
    const query = '''
      query (\$type: MediaType) {
        trending: Page(page: 1, perPage: 15) { media(sort: TRENDING_DESC, type: \$type, isAdult: false) { id type bannerImage title { english romaji } coverImage { large extraLarge } } }
        popular: Page(page: 1, perPage: 20) { media(sort: POPULARITY_DESC, type: \$type, isAdult: false) { id type bannerImage averageScore title { english romaji } coverImage { large extraLarge } } }
      }
    ''';
    final data = await _query(query, {'type': type});
    return {
      'trending': (data['trending']['media'] as List)
          .map((j) => AniListMedia.fromJson(j))
          .toList(),
      'popular': (data['popular']['media'] as List)
          .map((j) => AniListMedia.fromJson(j))
          .toList(),
    };
  }

  static Future<AniListMedia> getMediaDetails(int id) async {
    const query = '''
      query (\$id: Int) {
        Media(id: \$id) {
          id type description bannerImage averageScore status format seasonYear episodes chapters duration genres
          title { english romaji }
          coverImage { extraLarge large }
          nextAiringEpisode { airingAt timeUntilAiring episode }
          trailer { id site thumbnail }
          characters(sort: ROLE, perPage: 15) { edges { role node { id name { full } image { large } } } }
          staff(sort: RELEVANCE, perPage: 10) { edges { role node { id name { full } image { large } } } }
          studios(isMain: true) { edges { node { name } } }
          recommendations(perPage: 12, sort: RATING_DESC) { nodes { mediaRecommendation { id type title { english romaji } coverImage { large } } } }
        }
      }
    ''';
    final data = await _query(query, {'id': id});
    return AniListMedia.fromJson(data['Media']);
  }
}
