import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const SystemUiOverlayStyle kineticFullscreenOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.dark,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
);

bool get _supportsFullscreenSystemUi {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> applyFullscreenSystemUi() async {
  if (!_supportsFullscreenSystemUi) {
    return;
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(kineticFullscreenOverlayStyle);
}

class FullscreenBootstrap extends StatefulWidget {
  const FullscreenBootstrap({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<FullscreenBootstrap> createState() => _FullscreenBootstrapState();
}

class _FullscreenBootstrapState extends State<FullscreenBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(applyFullscreenSystemUi());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(applyFullscreenSystemUi());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
