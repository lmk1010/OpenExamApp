import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/constants/app_constants.dart';

/// 「关于」里那个版本号得是真的。
///
/// 它以前是设置页里一个写死的 'v1.0.1'，pubspec 都发到 1.1.0 了它还挂着
/// 上一版 —— 用户照着它报 bug，报的是个不存在的版本。发版改 pubspec 而忘了
/// 改它，这条就红。
void main() {
  test('关于页的版本号跟 pubspec.yaml 对得上', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    // version: 1.1.0+3 —— 只比 + 前面那截，build number 不给用户看。
    final pubspec = line.split(':')[1].trim().split('+').first;
    expect(AppConstants.appVersion, pubspec);
  });
}
