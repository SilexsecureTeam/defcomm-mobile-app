import 'package:flutter/material.dart';

class CommsActionGrid extends StatelessWidget {
  const CommsActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> iconPaths = [
      'images/secure_docs_icon.png',
      'images/secure_call_icon.png',
      'images/secure_upload_icon.png',
      'images/secure_mail_icon.png',
      'images/secure_network_icon.png',
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2810), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(iconPaths.length, (index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index == 0 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              iconPaths[index],
              width: 32,
              height: 32,
              color: index == 0 ? Colors.black : Colors.white,
            ),
          );
        }),
      ),
    );
  }
}