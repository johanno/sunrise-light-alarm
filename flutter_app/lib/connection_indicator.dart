import 'package:flutter/material.dart';

class ConnectionIndicator extends StatelessWidget {
  final bool isConnected;

  const ConnectionIndicator({Key? key, required this.isConnected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? Colors.green : Colors.red,
      ),
    );
  }
}
