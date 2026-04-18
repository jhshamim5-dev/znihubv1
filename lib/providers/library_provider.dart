import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anilist_models.dart';

class HistoryEntry {
  final AniListMedia media;
  final int progress;
  final int updatedAt;

  HistoryEntry(
      {required this.media, required this.progress, required this.updatedAt});

  Map<String, dynamic> toJson() => {
        'media': {
          'id': media.id,
          'type': media.type,
          'title': {
            'english': media.title.english,
            'romaji': media.title.romaji
          },
          'coverImage': {
            'large': media.coverImage.large,
            'extraLarge': media.coverImage.extraLarge
          },
        },
        'progress': progress,
        'updatedAt': updatedAt,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      media: AniListMedia.fromJson(json['media']),
      progress: json['progress'],
      updatedAt: json['updatedAt'],
    );
  }
}

class LibraryProvider with ChangeNotifier {
  bool isLoggedIn = false;
  List<AniListMedia> favorites = [];
  List<HistoryEntry> history = [];

  late SharedPreferences _prefs;

  LibraryProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    _prefs = await SharedPreferences.getInstance();
    isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;

    // Load History
    final histString = _prefs.getString('library_history');
    if (histString != null) {
      final List decoded = jsonDecode(histString);
      history = decoded.map((e) => HistoryEntry.fromJson(e)).toList();
    }

    // Load Favorites
    final favString = _prefs.getString('library_favorites');
    if (favString != null) {
      final List decoded = jsonDecode(favString);
      favorites = decoded.map((e) => AniListMedia.fromJson(e)).toList();
    }

    notifyListeners();
  }

  void login() {
    isLoggedIn = true;
    _prefs.setBool('isLoggedIn', true);
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    favorites.clear();
    _prefs.setBool('isLoggedIn', false);
    _prefs.remove('library_favorites');
    notifyListeners();
  }

  bool isFavorite(int mediaId) {
    return favorites.any((f) => f.id == mediaId);
  }

  void toggleFavorite(AniListMedia media) {
    if (!isLoggedIn) return;

    if (isFavorite(media.id)) {
      favorites.removeWhere((f) => f.id == media.id);
    } else {
      favorites.add(media);
    }

    _prefs.setString(
        'library_favorites',
        jsonEncode(favorites
            .map((e) => {
                  'id': e.id,
                  'type': e.type,
                  'title': {
                    'english': e.title.english,
                    'romaji': e.title.romaji
                  },
                  'coverImage': {
                    'large': e.coverImage.large,
                    'extraLarge': e.coverImage.extraLarge
                  }
                })
            .toList()));

    notifyListeners();
  }

  void updateHistory(AniListMedia media, int progress) {
    history.removeWhere((h) => h.media.id == media.id);
    history.insert(
        0,
        HistoryEntry(
            media: media,
            progress: progress,
            updatedAt: DateTime.now().millisecondsSinceEpoch));

    _prefs.setString(
        'library_history', jsonEncode(history.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void removeFromHistory(int mediaId) {
    history.removeWhere((h) => h.media.id == mediaId);
    _prefs.setString(
        'library_history', jsonEncode(history.map((e) => e.toJson()).toList()));
    notifyListeners();
  }
}
