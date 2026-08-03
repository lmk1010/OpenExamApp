import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';

class PlatformInfoCard extends StatelessWidget {
  const PlatformInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = Platform.isIOS
        ? 'iOS'
        : (Platform.isAndroid ? 'Android' : 'Other');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.phone_iphone),
        title: const Text(AppConstants.appDescription),
        subtitle: Text('当前运行平台：$platform'),
      ),
    );
  }
}
