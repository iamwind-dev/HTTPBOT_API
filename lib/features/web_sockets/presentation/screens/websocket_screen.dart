import 'package:flutter/widgets.dart';
import 'package:httpbot_api/core/keys/widget_keys.dart';
import 'package:httpbot_api/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:httpbot_api/core/theme/app_theme_context.dart';
import 'package:httpbot_api/generated/assets.gen.dart';

class WebsocketScreen extends StatelessWidget {
  const WebsocketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: colors.background,
      child: SingleChildScrollView(
        key: const ValueKey<String>(AppWidgetKeys.websocketsList),
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          0,
          AppSpacing.medium,
          0,
          AppSpacing.xxxLarge + AppSpacing.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 25,
                      height: 25,
                      child: Assets.icons.websocketIc.svg(
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Unititled Request ",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text("wss://", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: colors.divider, thickness: 1),
          ],
        ),
      ),
    );
  }
}
