import 'package:bmp/draw-direct-6-targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    print('logical dimensions $width x $height');

    int realWidth = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt();
    int realHeight = (MediaQuery.of(context).size.height * MediaQuery.of(context).devicePixelRatio).toInt();
    print('real dimensions $realWidth x $realHeight');

    // return DrawDirect72(
    //   // width: realWidth,
    //   width: width * 2,
    //   // height: realHeight - 1300,
    //   height: height * 2 - 1090,
    //   // maxPixels: realWidth * realHeight,
    //   maxPixels: width * height,
    // );

    int hdWidth = (MediaQuery.of(context).size.width * 1.5).toInt();
    int hdHeight = (MediaQuery.of(context).size.height * 1.5).toInt();
    print('real dimensions $realWidth x $realHeight');

    // return DrawDirect10Circle(
    //   width: width,
    //   height: height,
    //   maxPixels: width * height,
    // );

    return DrawDirect6Targets(
      width: width,
      height: height,
      maxPixels: width * height,
    );
  }
}
