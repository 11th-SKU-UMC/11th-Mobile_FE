import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('마이페이지'),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
              SizedBox(height: 16),
              Text(
                '무비러버',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('좋은 영화를 보고 기록하는 것을 좋아합니다.', textAlign: TextAlign.center),
              SizedBox(height: 30),
              ListTile(
                leading: Icon(Icons.movie),
                title: Text('본 영화'),
                trailing: Text('342'),
              ),
              ListTile(
                leading: Icon(Icons.star),
                title: Text('평균 평점'),
                trailing: Text('4.2'),
              ),
              ListTile(
                leading: Icon(Icons.favorite),
                title: Text('즐겨찾기'),
                trailing: Text('58'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
