import 'package:flutter/material.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}