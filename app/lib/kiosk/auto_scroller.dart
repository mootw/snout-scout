import 'dart:async';

import 'package:flutter/material.dart';

class AutoScroller extends StatefulWidget {
  final Widget child;
  const AutoScroller({super.key, required this.child});

  @override
  State<AutoScroller> createState() => _AutoScrollerState();
}

class _AutoScrollerState extends State<AutoScroller> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _isResetting = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (_isHovering) return;
          if (_controller.hasClients) {
            if (_isResetting) {
              return;
            }
            if (_controller.position.pixels >=
                _controller.position.maxScrollExtent) {
              _isResetting = true;
              _controller
                  .animateTo(
                    0,
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                  )
                  .then((value) => _isResetting = false);
            } else {
              _controller.animateTo(
                _controller.position.pixels + 2,
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear,
              );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovering = true,
      onExit: (_) => _isHovering = false,
      child: PrimaryScrollController(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}
