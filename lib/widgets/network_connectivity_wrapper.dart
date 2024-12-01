import 'package:flutter/material.dart';

class NetworkConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const NetworkConnectivityWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => child;
} 