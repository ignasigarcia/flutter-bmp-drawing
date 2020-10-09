import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DrawPixel extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawPixel({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

const int black = 4278190080; // Color.fromRGBO(0, 0, 0, 1).value

bresenham(x0, y0, x1, y1, [fn]) {
  List<Point> arr = [];
  if (fn == null) {
    fn = (x, y) {
      arr.add(Point(x, y));
    };
  }
  var dx = x1 - x0;
  var dy = y1 - y0;
  var adx = dx.abs();
  var ady = dy.abs();
  var eps = 0;
  var sx = dx > 0 ? 1 : -1;
  var sy = dy > 0 ? 1 : -1;

  if (adx > ady) {
    for (var x = x0, y = y0; sx < 0 ? x >= x1 : x <= x1; x += sx) {
      fn(x, y);
      eps += ady;
      if ((eps << 1) >= adx) {
        y += sy;
        eps -= adx;
      }
    }
  } else {
    for (var x = x0, y = y0; sy < 0 ? y >= y1 : y <= y1; y += sy) {
      fn(x, y);
      eps += adx;

      if ((eps << 1) >= ady) {
        x += sx;
        eps -= ady;
      }
    }
  }
  return arr;
}

class _DrawState extends State<DrawPixel> {
  List<Point> points = List<Point>();

  Future<ui.Image> makeImage() {
    final c = Completer<ui.Image>();
    final Int32List pixels = Int32List(widget.width * widget.height);

    for (int i = 0; i < points.length; i++) {
      pixels[points[i].y * widget.width + points[i].x] = black;
    }

    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      widget.width,
      widget.height,
      ui.PixelFormat.rgba8888,
      c.complete,
    );

    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Image(image: AssetImage('assets/images/77.webp')),
            Column(
              children: [
                GestureDetector(
                  onPanStart: (details) {
                    setState(
                        () => points.add(Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt())));
                  },
                  onPanUpdate: (details) {
                    if (details.localPosition.dx.toInt() > 0 &&
                        details.localPosition.dy.toInt() > 0 &&
                        details.localPosition.dy.toInt() * widget.width + details.localPosition.dx.toInt() <=
                            widget.maxPixels) {
                      var lastPoint = points.last;
                      var nextPoints = bresenham(
                          lastPoint.x, lastPoint.y, details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                      setState(() => points += nextPoints);
                    }
                  },
                  child: FutureBuilder<ui.Image>(
                    future: makeImage(),
                    builder: (context, snapshot) {
                      return RawImage(
                        image: snapshot.data,
                      );
                    },
                  ),
                ),
                FlatButton(onPressed: () => setState(() => points = []), child: Text('Clear'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
