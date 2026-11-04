import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mengatur ukuran layar uji (logical px) dan mengembalikannya saat test selesai.
void useScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewInsets();
  });
}

/// Aplikasi uji standar: ProviderScope + MaterialApp dengan skala teks.
Widget testApp({
  required Widget home,
  List<Override> overrides = const [],
  Map<String, WidgetBuilder> routes = const {},
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: home,
      routes: routes,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
    ),
  );
}
