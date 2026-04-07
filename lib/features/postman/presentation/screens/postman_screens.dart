import 'package:flutter/material.dart';
import 'package:httpbot_api/core/widgets/body_empty.dart';

class PostmanScreens extends StatelessWidget {
  const PostmanScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyEmpty(
      title: "No Collections",
      subtitle: "Tap `+` to import a new collections",
    );
  }
}
