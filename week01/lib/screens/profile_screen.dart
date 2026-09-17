import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';
import '../theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {

    const ProfileScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: CommonAppBar(
                title: '내 프로필',
                centerTitle: true,
            ),
            body: SafeArea(
                child: SingleChildScrollView(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                    ),
                    child: Column(
                        children: [
                        ProfileHeader(),

                        Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 32,
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                Expanded(
                                    child: StatItem(
                                    label: '본 영화',
                                    value: '24',
                                    ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                    child: StatItem(
                                    label: '평균 평점',
                                    value: '4.3',
                                    ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                    child: StatItem(
                                    label: '즐겨찾기',
                                    value: '8',
                                    ),
                                ),
                                ],
                            ),
                            ),

                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                            '선호 장르',
                            style: AppTextStyles.titleMedium,
                            ),
                        ),

                        const SizedBox(height: 12),

                        const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                            Chip(label: Text('드라마')),
                            Chip(label: Text('SF')),
                            Chip(label: Text('애니메이션')),
                            ],
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                ),
                            ),
                            child: const Text('프로필 수정'),
                            ),
                        ),
                        ],
                    ),
                    ),
                ),
                ),
        );
    }
}