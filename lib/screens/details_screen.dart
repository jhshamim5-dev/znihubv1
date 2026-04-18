import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart'; // Added URL Launcher!
import '../models/anilist_models.dart';
import '../services/anilist_service.dart';
import '../providers/library_provider.dart';
import 'player_screen.dart';

class DetailsScreen extends StatefulWidget {
  final int mediaId;
  final String type;

  const DetailsScreen({Key? key, required this.mediaId, required this.type})
      : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  AniListMedia? _media;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final media = await AniListService.getMediaDetails(widget.mediaId);
      if (mounted)
        setState(() {
          _media = media;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return "Airing Now";
    int d = seconds ~/ 86400;
    int h = (seconds % 86400) ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    return "${d}d ${h}h ${m}m";
  }

  Widget _buildMetaBox(String label, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width / 3) - 20,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent)));
    if (_media == null)
      return const Scaffold(
          body: Center(
              child: Text("Failed to load details",
                  style: TextStyle(color: Colors.white))));

    final isAnime = widget.type == 'ANIME';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            top: 12,
            left: 16,
            right: 16),
        decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.95),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(isAnime ? Icons.play_arrow : Icons.menu_book,
                    color: Colors.white),
                label: Text(isAnime ? 'Watch Now' : 'Read Now',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAnime ? Colors.indigoAccent : Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PlayerScreen(media: _media!, type: widget.type))),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<LibraryProvider>(
              builder: (context, library, child) {
                final isFav = library.isFavorite(_media!.id);
                return InkWell(
                  onTap: () => library.toggleFavorite(_media!),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10)),
                    child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white),
                  ),
                );
              },
            )
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                      imageUrl:
                          _media!.bannerImage ?? _media!.coverImage.extraLarge,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                          const Color(0xFF0A0A0A).withOpacity(0.8),
                          const Color(0xFF0A0A0A)
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster & Title Block
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Fixed alignment
                    children: [
                      Container(
                        width: 110, height: 160,
                        // REMOVED THE NEGATIVE TRANSFORM THAT CAUSED FLUTLAB CLIPPING
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5))
                            ]),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                                imageUrl: _media!.coverImage.extraLarge,
                                fit: BoxFit.cover)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_media!.title.display,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2),
                                maxLines: 4),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (_media!.averageScore != null)
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.yellow, size: 14),
                                        const SizedBox(width: 4),
                                        Text('${_media!.averageScore! / 10}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13))
                                      ]),
                                Text(_media!.status.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                if (_media!.seasonYear != null)
                                  Text('${_media!.seasonYear}',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  // Countdown
                  if (_media!.nextAiringEpisode != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 24, bottom: 8),
                      decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.indigoAccent.withOpacity(0.3))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Episode ${_media!.nextAiringEpisode!.episode} Airing In',
                              style: const TextStyle(
                                  color: Colors.indigoAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(
                              _formatTime(
                                  _media!.nextAiringEpisode!.timeUntilAiring),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18))
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  // Metadata Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMetaBox('Format',
                          _media!.format.isNotEmpty ? _media!.format : 'TV'),
                      if (_media!.episodes != null)
                        _buildMetaBox('Episodes', '${_media!.episodes}'),
                      if (_media!.chapters != null)
                        _buildMetaBox('Chapters', '${_media!.chapters}'),
                      if (_media!.duration != null)
                        _buildMetaBox('Duration', '${_media!.duration}m'),
                      if (_media!.studio.isNotEmpty)
                        _buildMetaBox('Studio', _media!.studio),
                    ],
                  ),

                  // Synopsis
                  const SizedBox(height: 8),
                  _buildSectionTitle('Synopsis'),
                  Text(
                      _media!.description
                          .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.5)),

                  // Genres
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _media!.genres
                        .map((g) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(g,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12))))
                        .toList(),
                  ),

                  // CLICKABLE TRAILER BOX
                  if (_media!.trailer != null &&
                      _media!.trailer!.site == 'youtube') ...[
                    _buildSectionTitle('Trailer'),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse(
                            'https://www.youtube.com/watch?v=${_media!.trailer!.id}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode
                                  .externalApplication); // Opens YouTube App or Browser Native Tab!
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open YouTube.')));
                        }
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                                image: NetworkImage(_media!.trailer!.thumbnail),
                                fit: BoxFit.cover)),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black45),
                          child: const Center(
                              child: Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 60)),
                        ),
                      ),
                    ),
                  ],

                  // Characters
                  if (_media!.characters.isNotEmpty) ...[
                    _buildSectionTitle('Characters'),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _media!.characters.length,
                        itemBuilder: (context, index) {
                          final char = _media!.characters[index];
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Expanded(
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                            imageUrl: char.image,
                                            fit: BoxFit.cover,
                                            width: 90))),
                                const SizedBox(height: 8),
                                Text(char.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(char.role,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Staff
                  if (_media!.staff.isNotEmpty) ...[
                    _buildSectionTitle('Staff'),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _media!.staff.length,
                        itemBuilder: (context, index) {
                          final st = _media!.staff[index];
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Expanded(
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                            imageUrl: st.image,
                                            fit: BoxFit.cover,
                                            width: 90))),
                                const SizedBox(height: 8),
                                Text(st.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(st.role,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
