import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/utils.dart';

/// document will be added
class Noises extends StatelessWidget {
  const Noises({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 51; i++) _singleNoise(context),
      ],
    );
  }

  Widget _singleNoise(BuildContext context) {
    return Container(
      width: .56.w(),
      height: 5.9.w() * math.Random().nextDouble() + .26.w(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
    );
  }
}
