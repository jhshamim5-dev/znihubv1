import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/custom_api_service.dart';

class FullScreenMangaReader extends StatefulWidget {
  final int anilistId;
  final int chapterNum;
  final String title;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool hasNext;
  final bool hasPrev;

  const FullScreenMangaReader({
    Key? key,
    required this.anilistId,
    required this.chapterNum,
    required this.title,
    required this.onNext,
    required this.onPrev,
    required this.hasNext,
    required this.hasPrev,
  }) : super(key: key);

  @override
  State<FullScreenMangaReader> createState() => _FullScreenMangaReaderState();
}

class _FullScreenMangaReaderState extends State<FullScreenMangaReader> {
  late Future<List<String>> _pagesFuture;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _pagesFuture =
        CustomApiService.fetchMangaPages(widget.anilistId, widget.chapterNum);
  }

  // Reload when switching chapters natively without destroying widget
  @override
  void didUpdateWidget(FullScreenMangaReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterNum != widget.chapterNum) {
      setState(() {
        _pagesFuture = CustomApiService.fetchMangaPages(
            widget.anilistId, widget.chapterNum);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: FutureBuilder<List<String>>(
              future: _pagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.pinkAccent));
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Failed to load manga pages.",
                          style: TextStyle(color: Colors.white)));
                }

                final pages = snapshot.data ?? [];
                // Automatically scales images 100% horizontally!
                return ListView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: pages[index],
                      fit: BoxFit.fitWidth,
                      placeholder: (context, url) => Container(
                          height: 300,
                          color: Colors.grey[900],
                          child:
                              const Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, err) => const SizedBox(
                          height: 100,
                          child:
                              Icon(Icons.broken_image, color: Colors.white54)),
                      httpHeaders: const {'Referer': 'https://weebcentral.com'},
                    );
                  },
                );
              },
            ),
          ),
          if (_showUI) ...[
            // TOP BAR
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 12,
                    left: 8,
                    right: 16),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                    Expanded(
                        child: Text(widget.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
            // BOTTOM BAR
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800]),
                      onPressed: widget.hasPrev ? widget.onPrev : null,
                      child: const Text('Previous',
                          style: TextStyle(color: Colors.white)),
                    ),
                    Text('Ch. ${widget.chapterNum}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent),
                      onPressed: widget.hasNext ? widget.onNext : null,
                      child: const Text('Next',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
