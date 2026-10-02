import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            width: 300,
            height: 10,
            color: Colors.grey,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Container(
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
