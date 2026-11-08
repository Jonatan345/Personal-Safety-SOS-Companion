import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/utils/app_info.dart';

void main() {
  test('AppInfo matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', multiLine: true)
            .firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml harus punya version: x.y.z+n');
    expect(AppInfo.name, match!.group(1));
    expect(AppInfo.build, int.parse(match.group(2)!));
  });
}
