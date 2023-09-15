import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/utils.dart';

import './noises.dart';

// ignore: must_be_immutable
class VoiceMessage extends StatefulWidget {
  VoiceMessage({
    Key? key,
    this.audioSrc,
    this.audioFile,
    this.duration,
    this.formatDuration,
    this.showDuration = false,
    this.waveForm,
    this.noiseCount = 27,
    this.backgroundColor = const Color(0xFF526BF7),
    this.radius = 24,
    this.foregroundColor = const Color(0xffffffff),
    this.played = false,
    this.onPlay,
  }) : super(key: key);

  final String? audioSrc;
  Future<File>? audioFile;
  final Duration? duration;
  final bool showDuration;
  final List<double>? waveForm;
  final double radius;

  final int noiseCount;
  final Color backgroundColor, foregroundColor;
  final bool played;
  Function()? onPlay;
  String Function(Duration duration)? formatDuration;

  @override
  State<VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<VoiceMessage> with SingleTickerProviderStateMixin {
  late StreamSubscription stream;
  final AudioPlayer _player = AudioPlayer();
  final double maxNoiseHeight = 6.w(), noiseWidth = 28.5.w();
  Duration? _audioDuration;
  double maxDurationForSlider = .0000001;
  bool _isPlaying = false, x2 = false, _audioConfigurationDone = false;
  int duration = 00;
  String _remainingTime = '';
  AnimationController? _controller;

  @override
  void initState() {
    widget.formatDuration ??= (Duration duration) {
      return duration.toString().substring(2, 11);
    };

    _setDuration();
    super.initState();
    stream = _player.onPlayerStateChanged.listen((event) {
      switch (event) {
        case PlayerState.stopped:
          break;
        case PlayerState.playing:
          setState(() => _isPlaying = true);
          break;
        case PlayerState.paused:
          setState(() => _isPlaying = false);
          break;
        case PlayerState.completed:
          _player.seek(const Duration(milliseconds: 0));
          setState(() {
            duration = _audioDuration!.inMilliseconds;
            _remainingTime = widget.formatDuration!(_audioDuration!);
          });
          break;
        default:
          break;
      }
    });
    _player.onPositionChanged.listen(
      (Duration p) => setState(
        () => _remainingTime = p.toString().substring(2, 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _sizerChild(context);

  Widget _sizerChild(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          48,
          6,
          16,
          6,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.radius),
                bottomLeft: Radius.circular(widget.radius),
                topRight: Radius.circular(widget.radius),
              ),
              color: widget.backgroundColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                  child: _playButton(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _durationWithNoise(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _playButton(BuildContext context) => InkWell(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.foregroundColor,
          ),
          width: 36,
          height: 36,
          child: InkWell(
            onTap: () => !_audioConfigurationDone ? null : _changePlayingStatus(),
            child: !_audioConfigurationDone
                ? Container(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      color: widget.backgroundColor,
                    ),
                  )
                : Icon(
                    _isPlaying ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid,
                    color: widget.backgroundColor,
                    size: 5.w(),
                  ),
          ),
        ),
      );

  Widget _durationWithNoise(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _noise(context),
          Row(
            children: [
              if (widget.showDuration)
                Padding(
                  padding: EdgeInsets.only(left: 1.2.w()),
                  child: Text(
                    widget.formatDuration!(widget.duration!),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.foregroundColor,
                    ),
                  ),
                ),
              SizedBox(width: 1.5.w()),
              SizedBox(
                width: 50,
                child: Text(
                  _remainingTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _noise(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      children: [
        const Noises(),
        if (_audioConfigurationDone)
          AnimatedBuilder(
            animation: CurvedAnimation(parent: _controller!, curve: Curves.ease),
            builder: (context, child) {
              return Positioned(
                left: _controller!.value,
                child: Container(
                  width: noiseWidth,
                  height: 6.w(),
                  color: widget.backgroundColor.withOpacity(.4),
                ),
              );
            },
          ),
        Opacity(
          opacity: .0,
          child: Container(
            width: noiseWidth,
            color: Colors.amber.withOpacity(0),
            child: Slider(
              min: 0.0,
              max: maxDurationForSlider,
              onChangeStart: (__) => _stopPlaying(),
              onChanged: (_) => _onChangeSlider(_),
              value: duration + .0,
            ),
          ),
        ),
      ],
    );
  }

  void _startPlaying() async {
    if (widget.audioFile != null) {
      String path = (await widget.audioFile!).path;
      debugPrint("> _startPlaying path $path");
      await _player.play(DeviceFileSource(path));
    } else if (widget.audioSrc != null) {
      await _player.play(UrlSource(widget.audioSrc!));
    }
    _controller!.forward();
  }

  _stopPlaying() async {
    await _player.pause();
    _controller!.stop();
  }

  void _setDuration() async {
    if (widget.duration != null) {
      _audioDuration = widget.duration;
    } else {
      _audioDuration = await _player.getDuration();
    }
    duration = _audioDuration!.inMilliseconds;
    maxDurationForSlider = duration + .0;

    ///
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: noiseWidth,
      duration: _audioDuration,
    );

    ///
    _controller!.addListener(() {
      if (_controller!.isCompleted) {
        _controller!.reset();
        _isPlaying = false;
        x2 = false;
        setState(() {});
      }
    });
    _setAnimationConfiguration(_audioDuration!);
  }

  void _setAnimationConfiguration(Duration audioDuration) async {
    setState(() {
      _remainingTime = widget.formatDuration!(audioDuration);
    });
    debugPrint("_setAnimationConfiguration $_remainingTime");
    _completeAnimationConfiguration();
  }

  void _completeAnimationConfiguration() => setState(() => _audioConfigurationDone = true);

  void _changePlayingStatus() async {
    if (widget.onPlay != null) widget.onPlay!();
    _isPlaying ? _stopPlaying() : _startPlaying();
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    stream.cancel();
    _player.dispose();
    _controller?.dispose();
    super.dispose();
  }

  _onChangeSlider(double d) async {
    if (_isPlaying) _changePlayingStatus();
    duration = d.round();
    _controller?.value = (noiseWidth) * duration / maxDurationForSlider;
    _remainingTime = widget.formatDuration!(_audioDuration!);
    await _player.seek(Duration(milliseconds: duration));
    setState(() {});
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 10;
    final double trackLeft = offset.dx, trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
