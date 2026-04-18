import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/custom_api_models.dart';

class NativeVideoPlayer extends StatefulWidget {
  final CustomStream streamData;

  const NativeVideoPlayer({Key? key, required this.streamData})
      : super(key: key);

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _showIntroSkip = false;

  @override
  void initState() {
    super.initState();
    // FORCE FULLSCREEN LANDSCAPE & HIDE BATTERY/WIFI NOTIFICATION BAR
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.streamData.m3u8));
    await _videoPlayerController.initialize();

    // Listen for Intro skip timing
    _videoPlayerController.addListener(_checkIntroSkip);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      allowedScreenSleep: false,
      allowFullScreen:
          false, // Disabling internal fullscreen because this *is* a full screen route
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.indigoAccent,
        handleColor: Colors.white,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white38,
      ),
    );
    if (mounted) setState(() {});
  }

  void _checkIntroSkip() {
    if (widget.streamData.introStart != null &&
        widget.streamData.introEnd != null) {
      final pos = _videoPlayerController.value.position.inSeconds;
      final inIntro = pos >= widget.streamData.introStart! &&
          pos < widget.streamData.introEnd!;
      if (_showIntroSkip != inIntro) {
        if (mounted) setState(() => _showIntroSkip = inIntro);
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_checkIntroSkip);
    _videoPlayerController.dispose();
    _chewieController?.dispose();

    // RESTORE THE PHONE BACK TO PORTRAIT WHEN LEAVING PLAYER
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand, // Expands fully to screen edges
        children: [
          if (_chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.indigoAccent)),

          // Custom Back Button to forcefully exit Landscape mode
          Positioned(
            top: 20,
            left: 24,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(50)),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // INTRO SKIP BUTTON
          if (_showIntroSkip)
            Positioned(
              bottom: 80,
              right: 30,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fast_forward, color: Colors.black),
                label: const Text('Skip Intro',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: () {
                  _videoPlayerController
                      .seekTo(Duration(seconds: widget.streamData.introEnd!));
                },
              ),
            ),
        ],
      ),
    );
  }
}
