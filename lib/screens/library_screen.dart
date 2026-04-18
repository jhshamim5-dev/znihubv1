import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/library_provider.dart';
import '../models/anilist_models.dart';
import 'details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleMediaSelect(AniListMedia media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailsScreen(mediaId: media.id, type: media.type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.deepPurpleAccent,
              tabs: const [
                Tab(icon: Icon(Icons.history), text: 'History'),
                Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(library),
                  _buildFavoritesTab(library),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab(LibraryProvider library) {
    if (library.history.isEmpty) {
      return const Center(
          child: Text('No watch history yet.',
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: library.history.length,
      itemBuilder: (context, index) {
        final entry = library.history[index];
        final media = entry.media;
        return ListTile(
          onTap: () => _handleMediaSelect(media),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: media.coverImage.large,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(media.title.display,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            media.type == 'ANIME'
                ? 'Episode ${entry.progress}'
                : 'Chapter ${entry.progress}',
            style: TextStyle(
                color: media.type == 'ANIME'
                    ? Colors.indigoAccent
                    : Colors.pinkAccent),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () {
              library.removeFromHistory(media.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab(LibraryProvider library) {
    if (!library.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Login to sync favorites across devices',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () => library.login(),
              child: const Text('Simulate Login',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (library.favorites.isEmpty) {
      return const Center(
          child: Text('No favorites yet.',
              style: TextStyle(color: Colors.white54)));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: library.favorites.length,
      itemBuilder: (context, index) {
        final media = library.favorites[index];
        return GestureDetector(
          onTap: () => _handleMediaSelect(media),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: media.coverImage.large,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                media.title.display,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
