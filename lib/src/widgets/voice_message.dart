import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/custom_track_shape.dart';
import 'package:voice_message_package/src/helpers/utils.dart';
import 'package:voice_message_package/src/widgets/noises.dart';

class VoiceMessage extends StatefulWidget {
  VoiceMessage({
    required this.source,
    this.backgroundColor = const Color(0xFF526BF7),
    this.foregroundColor = const Color(0xffffffff),
    this.onPlay,
    super.key,
  });

  final Source source;
  final Color backgroundColor, foregroundColor;
  Function()? onPlay;

  @override
  State<VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<VoiceMessage> with SingleTickerProviderStateMixin {
  late int durationValue = 0;
  late String _remainingTime = "00:00";

  late StreamSubscription stream;
  late Duration? _audioDuration;
  late AnimationController _controller;

  final AudioPlayer _player = AudioPlayer();
  final double noiseWidth = 28.5.w();

  double maxDurationForSlider = .0000001;
  bool _isPlaying = false;
  bool _audioConfigurationDone = false;

  @override
  void initState() {
    super.initState();
    _setDuration();

    stream = _player.onPlayerStateChanged.listen((event) {
      switch (event) {
        case PlayerState.stopped:
          break;
        case PlayerState.playing:
          setState(
            () => _isPlaying = true,
          );
          break;
        case PlayerState.paused:
          setState(
            () => _isPlaying = false,
          );
          break;
        case PlayerState.completed:
          _player.seek(
            const Duration(
              milliseconds: 0,
            ),
          );
          setState(() {
            durationValue = _audioDuration!.inMilliseconds;
            _remainingTime = formatDuration(_audioDuration!);
          });
          break;
        default:
          break;
      }
    });
    _player.onPositionChanged.listen(
      (Duration p) => setState(
        () => _remainingTime = formatDuration(p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(48, 6, 16, 6),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              color: widget.backgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _playButton(context),
                  ),
                  Expanded(
                    child: SizedBox(
                      child: _durationWithNoise(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _playButton(BuildContext context) => InkWell(
        onTap: () => _audioConfigurationDone ? _changePlayingStatus() : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.foregroundColor,
          ),
          child: Padding(
            padding: !_audioConfigurationDone || _isPlaying
                ? const EdgeInsets.all(
                    6,
                  )
                : const EdgeInsets.only(
                    left: 5,
                  ),
            child: !_audioConfigurationDone
                ? CircularProgressIndicator(
                    color: widget.backgroundColor,
                    strokeCap: StrokeCap.round,
                  )
                : Icon(
                    _isPlaying ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid,
                    color: widget.backgroundColor,
                    size: 20,
                  ),
          ),
        ),
      );

  Widget _durationWithNoise(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //TODO fix layout to match figma
          Stack(
            alignment: Alignment.center,
            children: [
              const Noises(),
              if (_audioConfigurationDone)
                AnimatedBuilder(
                  animation: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.ease,
                  ),
                  builder: (context, child) {
                    return Positioned.fill(
                      left: _controller.value * 2.18,
                      child: Container(
                        color: widget.backgroundColor.withOpacity(0.7),
                      ),
                    );
                  },
                ),
              Opacity(
                opacity: 0,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackShape: CustomTrackShape(),
                    thumbShape: SliderComponentShape.noThumb,
                    minThumbSeparation: 0,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxDurationForSlider,
                    onChangeStart: (__) => _stopPlaying(),
                    onChanged: (_) => _onChangeSlider(_),
                    value: durationValue.toDouble(),
                  ),
                ),
              ),
            ],
          ),
          Text(
            _remainingTime,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: widget.foregroundColor,
                ),
          ),
        ],
      );

  void _startPlaying() async {
    await _player.play(widget.source);
    _controller.forward();
  }

  _stopPlaying() async {
    await _player.pause();
    _controller.stop();
  }

  void _setDuration() async {
    await _player.setSource(widget.source);
    await _player.getDuration().then((value) {
      setState(() {
        _audioDuration = value;
      });
    });

    durationValue = _audioDuration!.inMilliseconds;
    maxDurationForSlider = durationValue.toDouble();

    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: noiseWidth,
      duration: _audioDuration,
    );

    _controller.addListener(() {
      if (_controller.isCompleted) {
        _controller.reset();
        _isPlaying = false;
        setState(() {});
      }
    });
    _setAnimationConfiguration(_audioDuration!);
  }

  void _setAnimationConfiguration(Duration audioDuration) async {
    setState(() {
      _remainingTime = formatDuration(audioDuration);
    });
    debugPrint("_setAnimationConfiguration $_remainingTime");
    _completeAnimationConfiguration();
  }

  void _completeAnimationConfiguration() => setState(
        () => _audioConfigurationDone = true,
      );

  void _changePlayingStatus() async {
    if (widget.onPlay != null) widget.onPlay!();
    _isPlaying ? _stopPlaying() : _startPlaying();
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    stream.cancel();
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  _onChangeSlider(double d) async {
    if (_isPlaying) _changePlayingStatus();
    durationValue = d.round();
    _controller.value = noiseWidth * durationValue / maxDurationForSlider;
    _remainingTime = formatDuration(_audioDuration!);
    await _player.seek(Duration(milliseconds: durationValue));
    setState(() {});
  }
}
