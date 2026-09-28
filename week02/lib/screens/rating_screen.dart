import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _selectedRating = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 평점'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              const Text(
                '이 영화는 어땠나요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '별점을 선택해 주세요.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              Center(
                child: RatingBar.builder(
                  initialRating: _selectedRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 48,
                  itemPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _selectedRating == 0
                    ? '별점을 선택하지 않았습니다.'
                    : '${_selectedRating.toStringAsFixed(1)} / 5.0',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _selectedRating == 0
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_selectedRating.toStringAsFixed(1)}점으로 저장했습니다.',
                            ),
                          ),
                        );
                      },
                child: const Text('평점 저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}