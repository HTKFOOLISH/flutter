import 'package:flutter/material.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Văn Hiếu - Thiện Khải'),
        ),
        body: Center(
          child: AnalogClock(
            dialColor: Colors.white, // Màu nền của mặt đồng hồ
            markingColor: Colors.black, // Màu của các số chỉ giờ
            hourNumbers: const ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'], // Các số La Mã giờ
            hourNumberColor: Colors.black, // Màu số giờ
            secondHandColor: Colors.red, // Màu kim giây
            minuteHandColor: Colors.blue, // Màu kim phút
            hourHandColor: Colors.black, // Màu kim giờ
            dateTime: DateTime.now(), // Cập nhật thời gian hiện tại
          ),
        ),
      ),
    );
  }
}
