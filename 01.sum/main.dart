import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SumCalculator(),
    );
  }
}

class SumCalculator extends StatefulWidget {
  @override
  _SumCalculatorState createState() => _SumCalculatorState();
}

class _SumCalculatorState extends State<SumCalculator> {
  final TextEditingController _firstNumberController = TextEditingController();
  final TextEditingController _secondNumberController = TextEditingController();
  String _result = "";

  void calculateSum() {
    // Lấy giá trị từ TextField và tính tổng
    double? num1 = double.tryParse(_firstNumberController.text);
    double? num2 = double.tryParse(_secondNumberController.text);

    if (num1 != null && num2 != null) {
      setState(() {
        _result = (num1 + num2).toString();
      });
    } else {
      setState(() {
        _result = "Vui lòng nhập số hợp lệ!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        title: Text("Tính Tổng Hai Số"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nhập số đầu tiên
            TextField(
              controller: _firstNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nhập số đầu tiên",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Nhập số thứ hai
            TextField(
              controller: _secondNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nhập số thứ hai",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Nút tính tổng
            ElevatedButton(
              onPressed: calculateSum,
              child: Text("Tính Tổng"),
            ),
            SizedBox(height: 16),

            // Hiển thị kết quả
            Text(
              "Kết quả: $_result",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
