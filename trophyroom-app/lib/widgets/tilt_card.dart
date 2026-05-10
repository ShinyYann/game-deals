import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// ⭐⭐⭐ 3D 倾斜感应卡片包装器
/// 使用设备陀螺仪创建微妙的 3D 透视效果 (±5°)
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt; // max rotation in degrees
  final double perspective; // perspective factor
  final Duration smoothing;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 5.0,
    this.perspective = 0.001,
    this.smoothing = const Duration(milliseconds: 100),
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rotX = 0; // X-axis rotation (pitch)
  double _rotY = 0; // Y-axis rotation (roll)
  StreamSubscription<GyroscopeEvent>? _sub;
  final double _filter = 0.15;

  @override
  void initState() {
    super.initState();
    try {
      _sub = gyroscopeEvents.listen((event) {
        setState(() {
          // Gyro gives rad/s, we integrate smoothly
          _rotX += (event.x * _filter - _rotX) * 0.1;
          _rotY += (event.y * _filter - _rotY) * 0.1;
          _rotX = _rotX.clamp(-widget.maxTilt / 57.3, widget.maxTilt / 57.3);
          _rotY = _rotY.clamp(-widget.maxTilt / 57.3, widget.maxTilt / 57.3);
        });
      });
    } catch (_) {
      // Gyro not available, silently degrade
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.smoothing,
      curve: Curves.easeOut,
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(_rotX)
          ..rotateY(_rotY),
        child: widget.child,
      ),
    );
  }
}
