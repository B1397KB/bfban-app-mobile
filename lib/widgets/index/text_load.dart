/// 抛光字符

import 'package:flutter/material.dart';

class textLoad extends StatefulWidget {
  final String? value;

  final double? fontSize;

  const textLoad({
    Key? key,
    this.value,
    this.fontSize,
  }) : super(key: key);

  @override
  _textLoadState createState() => _textLoadState();
}

class _textLoadState extends State<textLoad> with TickerProviderStateMixin {
  var _animation;

  var _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 2.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double value = _animation.value;

        Gradient gradient = LinearGradient(
          colors: [
            Theme.of(context).textTheme.titleMedium!.color!,
            Theme.of(context).textTheme.displayMedium!.color!,
            Theme.of(context).textTheme.titleMedium!.color!,
          ],
          stops: [value - 0.2, value, value + 0.2],
        );

        Shader shader = gradient.createShader(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
        );

        return Text(
          widget.value.toString(),
          style: TextStyle(
            fontSize: widget.fontSize ?? 28.0,
            foreground: Paint()..shader = shader,
          ),
        );
      },
    );
  }
}
