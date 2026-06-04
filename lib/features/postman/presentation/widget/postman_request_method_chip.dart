import 'package:flutter/material.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';

class PostmanRequestMethodChip extends StatelessWidget {
  const PostmanRequestMethodChip({
    super.key,
    required this.method,
  });

  final String method;

  Color _backgroundColor(BuildContext context) {
    final colors = context.appColors;

    switch (method.toUpperCase()) {
      case 'GET':
        return colors.methodGet;
      case 'POST':
        return colors.methodPost;
      case 'PUT':
        return colors.methodPut;
      case 'DELETE':
        return colors.methodDelete;
      case 'PATCH':
        return colors.methodPatch;
      default:
        return colors.chipNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          method.toUpperCase(),
          style: TextStyle(
            color: colors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
