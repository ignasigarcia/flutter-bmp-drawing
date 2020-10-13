import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'draw-direct-6.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
    int width = (MediaQuery.of(context).size.width).toInt();
    int height = (MediaQuery.of(context).size.height).toInt() - 100;

    // int realWidth = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt();
    // print(realWidth);
    // int realHeight = (MediaQuery.of(context).size.height * MediaQuery.of(context).devicePixelRatio).toInt();
    // print(realHeight);

    // return DrawDirect72(
    //   // width: realWidth,
    //   width: width * 2,
    //   // height: realHeight - 1300,
    //   height: height * 2 - 1090,
    //   // maxPixels: realWidth * realHeight,
    //   maxPixels: width * height,
    // );

    return DrawDirect6(
      width: width,
      height: height,
      maxPixels: width * height,
    );
  }
}
