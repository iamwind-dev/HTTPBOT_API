import 'package:flutter/material.dart';

import '../../generated/assets.gen.dart';

class BodyEmpty extends StatelessWidget {
  const BodyEmpty({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.icons.collections.svg(
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
