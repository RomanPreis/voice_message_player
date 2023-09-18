import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/utils.dart';

class Noises extends StatelessWidget {
  const Noises({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        51,
        (_) => Container(
          width: .56.w(),
          height: 5.9.w() * math.Random().nextDouble() + .26.w(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
