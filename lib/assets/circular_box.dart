import 'package:flutter/material.dart';
import 'package:disnote/other/constants.dart';

class CircularBox extends StatelessWidget {
  const CircularBox({
    required this.child,
    this.color = kBoxColor,
    this.borderRadius = 12,
    this.edgeInsetMargin = 10.0,
    super.key,
  });

  final Color color;
  final double borderRadius;
  final double edgeInsetMargin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(edgeInsetMargin),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
