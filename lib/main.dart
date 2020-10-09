import 'package:flutter/material.dart';

import 'draw-direct-3.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(body: ScreenInfo()),
    );
  }
}

class ScreenInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // int width = (MediaQuery.of(context).size.width * 2).toInt();
    // int height = (MediaQuery.of(context).size.height * 2).toInt() - 200;
    int width = (MediaQuery.of(context).size.width).toInt();
    int height = (MediaQuery.of(context).size.height).toInt() - 100;

    return DrawDirect3(
      width: width,
      height: height,
      maxPixels: width * height,
    );
  }
}
