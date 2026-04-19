import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/custom_api_service.dart';

class FullScreenMangaReader extends StatefulWidget {
  final int anilistId;
  final int chapterNum;
  final String title;
  final bool hasNext;
  final bool hasPrev;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;

  const FullScreenMangaReader({
    Key? key,
    required this.anilistId,
    required this.chapterNum,
    required this.title,
    required this.hasNext,
    required this.hasPrev,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FullScreenMangaReader> createState() => _FullScreenMangaReaderState();
}

class _FullScreenMangaReaderState extends State<FullScreenMangaReader> {
  List<String> _pages = [];
  bool _isLoading = true;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    try {
      // FIXED ERROR: Now passing both anilistId and chapterNum correctly as an int!
      final pages = await CustomApiService.fetchMangaPages(
          widget.anilistId, widget.chapterNum);
      if (mounted)
        setState(() {
          _pages = pages;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // INCLUDES THE PINCH TO ZOOM VIEWER FOR MANGA
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI), // Tap to toggle UI
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent))
                : InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: ListView.builder(
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: _pages[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const SizedBox(
                              height: 400,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white24))),
                          errorWidget: (context, url, error) => const SizedBox(
                              height: 200,
                              child: Center(
                                  child: Icon(Icons.error,
                                      color: Colors.white38))),
                        );
                      },
                    ),
                  ),
          ),

          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 12,
                    left: 16,
                    right: 16),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent
                    ])),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onClose),
                    Expanded(
                        child: Text(
                            '${widget.title} - Ch. ${widget.chapterNum}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16))),
                  ],
                ),
              ),
            ),

          if (_showUI && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                    top: 12,
                    left: 24,
                    right: 24),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent
                    ])),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon:
                          const Icon(Icons.skip_previous, color: Colors.white),
                      label: const Text('Prev',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent),
                      onPressed: widget.hasPrev ? widget.onPrev : null,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      label: const Text('Next',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent),
                      onPressed: widget.hasNext ? widget.onNext : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
