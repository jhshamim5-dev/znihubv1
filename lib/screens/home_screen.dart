import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/anilist_models.dart';
import '../services/anilist_service.dart';
import '../widgets/hero_slider.dart';
import '../widgets/media_row.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String type; // 'ANIME' or 'MANGA'

  const HomeScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, List<AniListMedia>>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = AniListService.fetchHomeData(widget.type);
  }

  void _handleMediaSelect(AniListMedia media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailsScreen(mediaId: media.id, type: widget.type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == 'ANIME';

    return FutureBuilder<Map<String, List<AniListMedia>>>(
      future: _homeDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitFoldingCube(
              color: isAnime ? Colors.indigoAccent : Colors.pinkAccent,
              size: 40.0,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data:\n${snapshot.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        } else if (snapshot.hasData) {
          final trending = snapshot.data!['trending'] ?? [];
          final popular = snapshot.data!['popular'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroSlider(items: trending, onSelect: _handleMediaSelect),
                const SizedBox(height: 10),
                MediaRow(
                  title: isAnime ? 'Trending Anime' : 'Trending Manga',
                  items: trending,
                  onSelect: _handleMediaSelect,
                ),
                MediaRow(
                  title: isAnime ? 'Top Rated' : 'Most Popular',
                  items: popular,
                  onSelect: _handleMediaSelect,
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
