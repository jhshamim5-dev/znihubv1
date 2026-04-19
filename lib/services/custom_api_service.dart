import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/custom_api_models.dart';

class CustomApiService {
  static const String animeBaseUrl =
      'https://aniwave-scraper-api.jhshamim81.workers.dev';
  static const String mangaBaseUrl = 'https://weebcentral-scraper.vercel.app';

  // --- ANIME ---
  static Future<List<CustomEpisode>> fetchEpisodes(int anilistId) async {
    final res =
        await http.get(Uri.parse('$animeBaseUrl/api/episodes?id=$anilistId'));
    if (res.statusCode != 200) throw Exception('Failed to fetch episodes');

    final data = jsonDecode(res.body);
    final List episodesList = data['episodes'] ?? [];
    return episodesList.map((e) => CustomEpisode.fromJson(e)).toList();
  }

  static Future<CustomStream> fetchStream(
      int anilistId, int ep, String server, String type) async {
    final res = await http.get(Uri.parse(
        '$animeBaseUrl/api/stream?id=$anilistId&ep=$ep&server=$server&type=$type'));
    if (res.statusCode != 200) throw Exception('Failed to fetch stream');
    return CustomStream.fromJson(jsonDecode(res.body));
  }

  // --- MANGA ---
  static Future<List<CustomChapter>> fetchMangaChapters(int anilistId) async {
    final res = await http
        .get(Uri.parse('$mangaBaseUrl/api/chapter-list?id=$anilistId'));
    if (res.statusCode != 200)
      throw Exception('Failed to fetch manga chapters');

    final data = jsonDecode(res.body);
    final List chaptersList = data['chapters'] ?? [];

    var mappedChapters =
        chaptersList.map((c) => CustomChapter.fromJson(c)).toList();
    // Sort ascending so chapter 1 starts first (Exactly like we fixed in Web!)
    mappedChapters.sort((a, b) => a.number.compareTo(b.number));
    return mappedChapters;
  }

  static Future<List<String>> fetchMangaPages(
      int anilistId, int chapterNum) async {
    final res = await http.get(
        Uri.parse('$mangaBaseUrl/api/chapters?id=$anilistId&cp=$chapterNum'));
    if (res.statusCode != 200) throw Exception('Failed to fetch manga pages');

    final data = jsonDecode(res.body);
    final List imagesList = data['images'] ?? [];
    return imagesList.cast<String>();
  }
}
