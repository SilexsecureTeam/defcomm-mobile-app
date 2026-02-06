import 'package:defcomm/features/settings/domain/entities/shield_settings.dart';
import 'package:flutter/material.dart';

class ShieldMessageWrapper extends StatelessWidget {
  final Widget child;
  final ShieldRevealMethod revealMethod;
  final VoidCallback onReveal;
  final String messageId;

  const ShieldMessageWrapper({
    super.key,
    required this.child,
    required this.revealMethod,
    required this.onReveal,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    switch (revealMethod) {
      case ShieldRevealMethod.tap:
        return GestureDetector(
          onTap: onReveal,
          behavior: HitTestBehavior.opaque, // Ensures the tap is caught
          child: child,
        );
      
      case ShieldRevealMethod.longPress:
        return GestureDetector(
          onLongPress: onReveal,
          behavior: HitTestBehavior.opaque,
          child: child,
        );

      case ShieldRevealMethod.swipe:
        return Dismissible(
          key: Key('shield_$messageId'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            onReveal();
            return false; 
          },
          background: Container(color: Colors.transparent),
          secondaryBackground: Container(color: Colors.transparent),
          child: child,
        );
    }
  }
}