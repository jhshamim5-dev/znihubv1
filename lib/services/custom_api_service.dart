import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/custom_api_models.dart';

class CustomApiService {
  static const String baseUrl = 'https://aniwave-scraper-api.workers.dev';
  static const String mangaUrl = 'https://weebcentral-scraper.vercel.app';

  static Future<List<CustomEpisode>> fetchEpisodes(int anilistId) async {
    final response = await http.get(Uri.parse('$baseUrl/episodes/$anilistId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['episodes'] == null) return [];
      return (data['episodes'] as List)
          .map((json) => CustomEpisode.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<CustomStream> fetchStream(
      int anilistId, int epNum, String server, String type) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/stream/$anilistId/$epNum?server=$server&type=$type'));
    if (response.statusCode == 200) {
      return CustomStream.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load stream');
  }

  // ===== ANISKIP FETCHER WITH CORS PROXY =====
  static Future<Map<String, Map<String, int>>> fetchAniSkip(
      int malId, int episode) async {
    try {
      final targetUrl =
          'https://api.aniskip.com/v2/skip-times/$malId/episodes/$episode?types=op&types=ed&episodeLength=0';

      // Use the proxy and encode the URL as requested!
      final proxyUrl =
          'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

      final res = await http.get(Uri.parse(proxyUrl));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        Map<String, Map<String, int>> skips = {};
        for (var item in data['results'] ?? []) {
          if (item['skipType'] == 'op') {
            skips['Intro'] = {
              'start': item['interval']['startTime'].toInt(),
              'end': item['interval']['endTime'].toInt()
            };
          }
          if (item['skipType'] == 'ed') {
            skips['Outro'] = {
              'start': item['interval']['startTime'].toInt(),
              'end': item['interval']['endTime'].toInt()
            };
          }
        }
        return skips;
      }
    } catch (_) {
      // Silently fail if proxy or API errors out, so it doesn't break the video
    }
    return {};
  }

  static Future<List<CustomChapter>> fetchMangaChapters(int anilistId) async {
    final response = await http.get(Uri.parse('$mangaUrl/chapters/$anilistId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['chapters'] as List)
          .map((json) => CustomChapter.fromJson(json))
          .toList();
      list.sort((a, b) => a.number.compareTo(b.number)); // Ensure 1 To X order
      return list;
    }
    return [];
  }

  static Future<List<String>> fetchMangaPages(
      int anilistId, int chapterNum) async {
    final response =
        await http.get(Uri.parse('$mangaUrl/pages/$anilistId/$chapterNum'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['pages'] as List)
          .map((page) => page['url'].toString())
          .toList();
    }
    throw Exception('Failed to load pages');
  }
}
