import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../models/custom_api_models.dart';

class NativeVideoPlayer extends StatefulWidget {
  final CustomStream streamData;
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback onChangeServer;

  const NativeVideoPlayer({
    Key? key,
    required this.streamData,
    required this.title,
    required this.onClose,
    this.onNext,
    this.onPrev,
    required this.onChangeServer,
  }) : super(key: key);

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;

  String _seekIndicator = '';
  Timer? _seekTimer;

  // Handles which skip button to show ('Intro' or 'Outro')
  String? _activeSkipType;

  @override
  void initState() {
    super.initState();
    _forceLandscape();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(NativeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seamlessly swap video controllers when next episode is clicked
    if (oldWidget.streamData.m3u8 != widget.streamData.m3u8) {
      _controller.removeListener(_playerListener);
      _controller.dispose();
      _activeSkipType = null;
      _initializePlayer();
    }
  }

  void _forceLandscape() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.streamData.m3u8));
    await _controller.initialize();
    _controller.addListener(_playerListener);
    _controller.play();
    _startHideTimer();
    if (mounted) setState(() {});
  }

  void _playerListener() {
    if (!mounted) return;
    setState(() {}); // Updates Scrubber

    // Check Intro / Outro Skip intelligently
    final pos = _controller.value.position.inSeconds;
    String? currentSkip;

    if (widget.streamData.introStart != null &&
        widget.streamData.introEnd != null) {
      if (pos >= widget.streamData.introStart! &&
          pos < widget.streamData.introEnd!) {
        currentSkip = 'Intro';
      }
    }
    if (widget.streamData.outroStart != null &&
        widget.streamData.outroEnd != null) {
      if (pos >= widget.streamData.outroStart! &&
          pos < widget.streamData.outroEnd!) {
        currentSkip = 'Outro';
      }
    }

    if (_activeSkipType != currentSkip) {
      setState(() => _activeSkipType = currentSkip);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying)
        setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    final isLeft = details.globalPosition.dx < width / 2;

    final currentPos = _controller.value.position;
    final seekAmount = const Duration(seconds: 10);

    setState(() {
      _seekIndicator = isLeft ? '-10s' : '+10s';
      _controller
          .seekTo(isLeft ? currentPos - seekAmount : currentPos + seekAmount);
      _showControls = true;
    });

    _seekTimer?.cancel();
    _seekTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _seekIndicator = '');
    });
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0
        ? '${twoDigits(d.inHours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekTimer?.cancel();
    _controller.removeListener(_playerListener);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: _handleDoubleTap,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),

          if (_seekIndicator.isNotEmpty)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (_seekIndicator == '-10s')
                    _buildSeekIcon(Icons.fast_rewind, '-10s')
                  else
                    const Spacer(),
                  if (_seekIndicator == '+10s')
                    _buildSeekIcon(Icons.fast_forward, '+10s')
                  else
                    const Spacer(),
                ],
              ),
            ),

          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 28),
                              onPressed: widget.onClose),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(widget.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1)),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.dns, size: 16),
                            label: const Text('Server'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigoAccent,
                                foregroundColor: Colors.white),
                            onPressed: widget.onChangeServer,
                          )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white, size: 40),
                            onPressed: widget.onPrev,
                            color: widget.onPrev != null
                                ? Colors.white
                                : Colors.white38),
                        const SizedBox(width: 30),
                        IconButton(
                          icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 70),
                          onPressed: () {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                            _startHideTimer();
                          },
                        ),
                        const SizedBox(width: 30),
                        IconButton(
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white, size: 40),
                            onPressed: widget.onNext,
                            color: widget.onNext != null
                                ? Colors.white
                                : Colors.white38),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Row(
                        children: [
                          Text(_formatDuration(_controller.value.position),
                              style: const TextStyle(color: Colors.white)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                  thumbColor: Colors.indigoAccent,
                                  activeTrackColor: Colors.indigoAccent,
                                  inactiveTrackColor: Colors.white24,
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6)),
                              child: Slider(
                                min: 0,
                                max: _controller.value.duration.inMilliseconds
                                    .toDouble(),
                                value: _controller.value.position.inMilliseconds
                                    .toDouble()
                                    .clamp(
                                        0,
                                        _controller
                                            .value.duration.inMilliseconds
                                            .toDouble()),
                                onChanged: (val) => _controller.seekTo(
                                    Duration(milliseconds: val.toInt())),
                              ),
                            ),
                          ),
                          Text(_formatDuration(_controller.value.duration),
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // SKIP BUTTON (INTRO OR OUTRO)
          if (_activeSkipType != null)
            Positioned(
              bottom: 80,
              right: 30,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fast_forward, color: Colors.black),
                label: Text('Skip $_activeSkipType',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: () {
                  if (_activeSkipType == 'Intro')
                    _controller
                        .seekTo(Duration(seconds: widget.streamData.introEnd!));
                  if (_activeSkipType == 'Outro')
                    _controller
                        .seekTo(Duration(seconds: widget.streamData.outroEnd!));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeekIcon(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(50)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 40),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
