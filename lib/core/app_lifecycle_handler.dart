import 'package:flutter/material.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onResume;

  const AppLifecycleHandler({super.key, required this.child, this.onResume});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      widget.onResume?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
