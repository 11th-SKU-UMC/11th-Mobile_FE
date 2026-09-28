// 상태

import 'package:flutter/material.dart';
import 'package:movielog/widgets/stat_item.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // ← 좌우 여백
      child: Column(
        children: [
          Container(
            //  decoration: BoxDecoration(border: ...),
            // margin: EdgeInsets.symmetric(horizontal: 2),
            //padding: EdgeInsets.all(1),
            child: Row(
              //mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: StatItem(label: '본 영화', value: '342'),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: StatItem(value: '4.2', label: '평점'),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: StatItem(label: '즐겨찾기', value: '58'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
