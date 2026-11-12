import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });
  final bool isLoading;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isLoading)
        const ModalBarrier(dismissible: false, color: Colors.black45),
      if (isLoading)
        const Center(child: CircularProgressIndicator(color: Colors.white)),
    ],
  );
}
