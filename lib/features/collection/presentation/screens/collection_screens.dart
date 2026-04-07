import 'package:flutter/material.dart';
import 'package:httpbot_api/core/widgets/body_empty.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BodyEmpty(
        title: "No Collections",
        subtitle: "Tap '+' to create or import a new collection",
      ),
    );
  }
}
