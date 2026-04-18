import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../models/anilist_models.dart';
import '../models/custom_api_models.dart';
import '../providers/library_provider.dart';
import '../services/custom_api_service.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/manga_reader.dart';

class PlayerScreen extends StatefulWidget {
  final AniListMedia media;
  final String type;

  const PlayerScreen({Key? key, required this.media, required this.type})
      : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isLoading = true;
  List<CustomEpisode> _episodes = [];
  List<CustomChapter> _chapters = [];

  int _currentChunk = 0;
  static const int _chunkSize = 50;
  num? _activeMangaChapter;

  List<String> _gallery = [];
  int _galleryIndex = 0;
  Timer? _galleryTimer;

  @override
  void initState() {
    super.initState();
    _gallery = [
      if (widget.media.bannerImage != null) widget.media.bannerImage!,
      widget.media.coverImage.extraLarge,
      'https://picsum.photos/seed/${widget.media.id}a/800/400?blur=1',
      'https://picsum.photos/seed/${widget.media.id}b/800/400?blur=1'
    ];
    _galleryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted)
        setState(() => _galleryIndex = (_galleryIndex + 1) % _gallery.length);
    });

    _fetchData();
  }

  @override
  void dispose() {
    _galleryTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      if (widget.type == 'ANIME') {
        _episodes = await CustomApiService.fetchEpisodes(widget.media.id);
      } else {
        _chapters = await CustomApiService.fetchMangaChapters(widget.media.id);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _openServerModal(num itemNum) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildServerModal(itemNum),
    );
  }

  String _formatNumber(num n) {
    return n == n.toInt() ? n.toInt().toString() : n.toString();
  }

  Widget _buildServerModal(num itemNum) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF171717),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Episode ${_formatNumber(itemNum)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Text('Select premium streaming server',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              _serverButton(
                  'Server-1', 'vidplay', 'sub', Icons.live_tv, itemNum.toInt()),
              const SizedBox(height: 12),
              _serverButton('Server-1 (Dub)', 'vidplay', 'dub', Icons.mic,
                  itemNum.toInt()),
              const SizedBox(height: 12),
              _serverButton('Server-2 BackUp', 'mycloud', 'sub', Icons.live_tv,
                  itemNum.toInt()),
              const SizedBox(height: 12),
              // ADDED SERVER 2 DUB!
              _serverButton('Server-2 BackUp (Dub)', 'mycloud', 'dub',
                  Icons.mic, itemNum.toInt()),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serverButton(String label, String server, String endpointType,
      IconData icon, int epNum) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context); // Close Modal Sheet
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
                child: CircularProgressIndicator(color: Colors.indigoAccent)));
        try {
          // Fetch Stream Data
          final CustomStream streamData = await CustomApiService.fetchStream(
              widget.media.id, epNum, server, endpointType);
          Provider.of<LibraryProvider>(context, listen: false)
              .updateHistory(widget.media, epNum);

          Navigator.pop(context); // Close Loading Dialog

          // FORCEFULLY PUSH THE FULLSCREEN PLAYER
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NativeVideoPlayer(streamData: streamData)));
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Stream failed to start (or Server down)')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(50)),
                child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
            const Icon(Icons.play_arrow, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _openMangaChapter(num chapterNum) {
    Provider.of<LibraryProvider>(context, listen: false)
        .updateHistory(widget.media, chapterNum.toInt());
    setState(() => _activeMangaChapter = chapterNum);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'MANGA' && _activeMangaChapter != null) {
      final index =
          _chapters.indexWhere((c) => c.number == _activeMangaChapter);
      final hasNext = index < _chapters.length - 1;
      final hasPrev = index > 0;
      final nextNum =
          hasNext ? _chapters[index + 1].number : _activeMangaChapter!;
      final prevNum =
          hasPrev ? _chapters[index - 1].number : _activeMangaChapter!;
      return FullScreenMangaReader(
        anilistId: widget.media.id,
        chapterNum: _activeMangaChapter!.toInt(),
        title: widget.media.title.display,
        hasNext: hasNext,
        hasPrev: hasPrev,
        onNext: () {
          Provider.of<LibraryProvider>(context, listen: false)
              .updateHistory(widget.media, nextNum.toInt());
          setState(() => _activeMangaChapter = nextNum);
        },
        onPrev: () {
          Provider.of<LibraryProvider>(context, listen: false)
              .updateHistory(widget.media, prevNum.toInt());
          setState(() => _activeMangaChapter = prevNum);
        },
      );
    }

    final isAnime = widget.type == 'ANIME';
    final totalItems = isAnime ? _episodes.length : _chapters.length;
    final numChunks = (totalItems > 0) ? (totalItems / _chunkSize).ceil() : 0;
    final startItem = _currentChunk * _chunkSize;
    final endItem = (startItem + _chunkSize) > totalItems
        ? totalItems
        : (startItem + _chunkSize);

    final currentEpisodes = isAnime
        ? (totalItems > 0 ? _episodes.sublist(startItem, endItem) : [])
        : [];
    final currentChapters = !isAnime
        ? (totalItems > 0 ? _chapters.sublist(startItem, endItem) : [])
        : [];

    return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: const Color(0xFF0A0A0A),
              title: Text(widget.media.title.display,
                  style: const TextStyle(fontSize: 16)),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      child: CachedNetworkImage(
                        key: ValueKey<int>(_galleryIndex),
                        imageUrl: _gallery.isNotEmpty
                            ? _gallery[_galleryIndex]
                            : widget.media.coverImage.extraLarge,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black87,
                            Colors.transparent,
                            const Color(0xFF0A0A0A).withOpacity(0.9),
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
              child: _isLoading
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: Colors.indigoAccent)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (numChunks > 1) ...[
                            const Text('SELECT RANGE',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: numChunks,
                                itemBuilder: (context, index) {
                                  final start = (index * _chunkSize) + 1;
                                  final end = ((index + 1) * _chunkSize)
                                      .clamp(1, totalItems);
                                  final isActive = _currentChunk == index;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _currentChunk = index),
                                    child: Container(
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      decoration: BoxDecoration(
                                          color: isActive
                                              ? (isAnime
                                                  ? Colors.indigoAccent
                                                  : Colors.pinkAccent)
                                              : Colors.grey[900],
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text('$start - $end',
                                          style: TextStyle(
                                              color: isActive
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                              '${isAnime ? "Episodes" : "Chapters"} ($totalItems)',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (totalItems == 0 && !_isLoading)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                    child: Text("No items available yet.",
                                        style:
                                            TextStyle(color: Colors.white54)))),
                          GridView.builder(
                            padding: const EdgeInsets.only(bottom: 40),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.1),
                            itemCount: isAnime
                                ? currentEpisodes.length
                                : currentChapters.length,
                            itemBuilder: (context, index) {
                              if (isAnime) {
                                final ep = currentEpisodes[index];
                                return InkWell(
                                  onTap: () => _openServerModal(ep.number),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.grey[900],
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_formatNumber(ep.number),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (ep.isSub)
                                              Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 2),
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                                  color: Colors.black38,
                                                  child: const Text('SUB',
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          color:
                                                              Colors.white54))),
                                            if (ep.isDub)
                                              Container(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                                  color: Colors.indigoAccent
                                                      .withOpacity(0.2),
                                                  child: const Text('DUB',
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          color: Colors
                                                              .indigoAccent))),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                final ch = currentChapters[index];
                                return InkWell(
                                  onTap: () => _openMangaChapter(ch.number),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.grey[900],
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.menu_book,
                                            color: Colors.pinkAccent, size: 16),
                                        const SizedBox(height: 4),
                                        Text(_formatNumber(ch.number),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        ],
                      ),
                    ),
            )
          ],
        ));
  }
}
