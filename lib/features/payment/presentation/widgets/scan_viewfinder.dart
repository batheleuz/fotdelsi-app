import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';

/// Cadre de visée du scanner : 4 coins en crochets + ligne de balayage animée.
class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key, this.size = 220});

  final double size;

  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          ..._corners(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final top = 8 + (_controller.value * (widget.size - 18));
              return Positioned(
                top: top,
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const length = 34.0;
    const thickness = 3.0;
    const radius = Radius.circular(14);
    BorderSide side() =>
        const BorderSide(color: AppColors.secondary, width: thickness);

    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: length,
          height: length,
          decoration: BoxDecoration(
            border: Border(top: side(), left: side()),
            borderRadius: const BorderRadius.only(topLeft: radius),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: length,
          height: length,
          decoration: BoxDecoration(
            border: Border(top: side(), right: side()),
            borderRadius: const BorderRadius.only(topRight: radius),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: length,
          height: length,
          decoration: BoxDecoration(
            border: Border(bottom: side(), left: side()),
            borderRadius: const BorderRadius.only(bottomLeft: radius),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: length,
          height: length,
          decoration: BoxDecoration(
            border: Border(bottom: side(), right: side()),
            borderRadius: const BorderRadius.only(bottomRight: radius),
          ),
        ),
      ),
    ];
  }
}
