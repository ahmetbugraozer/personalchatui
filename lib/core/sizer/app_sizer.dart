import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension AppSizerExtension on num {
  double get h => _AppSizer.dimension(this, Axis.vertical);
  double get w => _AppSizer.dimension(this, Axis.horizontal);
  double get sp => _AppSizer.scaled(this);

  double ch(BuildContext context) =>
      _AppSizer.dimension(this, Axis.vertical, context: context);
  double cw(BuildContext context) =>
      _AppSizer.dimension(this, Axis.horizontal, context: context);
  double csp(BuildContext context) => _AppSizer.scaled(this, context: context);
}

class _AppSizer {
  static double dimension(num value, Axis axis, {BuildContext? context}) {
    final size = _logicalSize(context);
    final length = axis == Axis.vertical ? size.height : size.width;
    return (value.toDouble() * length) / 100;
  }

  static double scaled(num value, {BuildContext? context}) {
    final base = value.toDouble();
    final size = _logicalSize(context);
    final ratio = _devicePixelRatio(context);
    final aspect = size.aspectRatio == 0 ? 1.0 : size.aspectRatio;
    final hVal = dimension(base, Axis.vertical, context: context);
    final wVal = dimension(base, Axis.horizontal, context: context);
    return base * ((hVal + wVal + (ratio * aspect)) / 2.08) / 100;
  }

  static Size _logicalSize(BuildContext? context) {
    final mq = _mediaQuery(context);
    if (mq != null) return mq.size;
    final view = _flutterView;
    final ratio = view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
    final physical = view.physicalSize;
    return Size(physical.width / ratio, physical.height / ratio);
  }

  static double _devicePixelRatio(BuildContext? context) {
    final mq = _mediaQuery(context);
    if (mq != null) return mq.devicePixelRatio;
    final view = _flutterView;
    return view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
  }

  static MediaQueryData? _mediaQuery(BuildContext? context) {
    final ctx = context ?? _rootContext;
    return ctx == null ? null : MediaQuery.maybeOf(ctx);
  }

  static BuildContext? get _rootContext =>
      Get.context ?? Get.key.currentContext;

  static ui.FlutterView get _flutterView {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    if (dispatcher.views.isNotEmpty) return dispatcher.views.first;
    final implicit = dispatcher.implicitView;
    if (implicit != null) return implicit;
    throw StateError('No Flutter views are available');
  }
}
