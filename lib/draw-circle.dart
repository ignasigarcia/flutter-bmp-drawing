import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrawCircle extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawCircle({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<DrawCircle> {
  Int32List pixels;
  Point lastPoint;
  int color;
  double thickness = 2;
  int radius = 1;
  bool isStylus = false;

  void initState() {
    super.initState();
    pixels = Int32List(widget.width * widget.height);
    color = Color.fromRGBO(0, 0, 0, 1).value;
  }

  Future<ui.Image> makeImage() {
    final c = Completer<ui.Image>();

    ui.decodeImageFromPixels(
        pixels.buffer.asUint8List(), widget.width, widget.height, ui.PixelFormat.rgba8888, c.complete,
        targetWidth: widget.width, targetHeight: widget.height, allowUpscaling: true);

    return c.future;
  }

  setPixel(x, y) {
    pixels[y * widget.width + x] = color;
  }

  setPixelAA(x, y, s, {bool override = true}) {
    int index = y.toInt() * widget.width + x.toInt();
    // if (!override && pixels[index] != 0) {
    if (pixels[index] != 0) {
      setPixel(x, y);
      return;
    }

    int color = s.toInt();
    pixels[index] = Color.fromRGBO(color, color, color, 1).value;
  }

  drawFilledCircle(int originX, int originY, int radius) {
    for (int y = -radius; y <= radius; y++) {
      for (int x = -radius; x <= radius; x++) {
        if (x * x + y * y <= radius * radius) setPixel(originX + x, originY + y);
      }
    }

    // setState(() {
    //   pixels = pixels;
    // });
  }

  plotCircleAA(xm, ym, r) {
    // drawFilledCircle(xm, ym, r - 1);

    var x = r, y = 0;
    var i, x2, e2, err = 2 - 2 * r;
    r = 1 - err;

    for (;;) {
      i = 255 * (err + 2 * (x + y) - 2).abs() / r;
      setPixelAA(xm + x, ym - y, i, override: true);
      setPixelAA(xm + y, ym + x, i, override: true);
      setPixelAA(xm - x, ym + y, i, override: true);
      setPixelAA(xm - y, ym - x, i, override: true);

      if (x == 0) break;

      e2 = err;
      x2 = x;

      if (err > y) {
        i = 255 * (err + 2 * x - 1) / r;
        if (i < 255) {
          setPixelAA(xm + x, ym - y + 1, i, override: true);
          setPixelAA(xm + y - 1, ym + x, i, override: true);
          setPixelAA(xm - x, ym + y - 1, i, override: true);
          setPixelAA(xm - y + 1, ym - x, i, override: true);
        }
        err -= --x * 2 - 1;
      }

      if (e2 <= x2--) {
        i = 255 * (1 - 2 * y - e2) / r;

        if (i < 255) {
          setPixelAA(xm + x2, ym - y, i, override: true);
          setPixelAA(xm + y, ym + x2, i, override: true);
          setPixelAA(xm - x2, ym + y, i, override: true);
          setPixelAA(xm - y, ym - x2, i, override: true);
        }
        err -= --y * 2 - 1;
      }
    }

    setState(() => pixels = pixels);
  }

  bresenham(x0, y0, x1, y1, [fn]) {
    List<Point> arr = List<Point>();

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

  Future<ui.Image> loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final list = Uint8List.view(data.buffer);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(list, completer.complete);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Center(child: Image(fit: BoxFit.fitHeight, image: AssetImage('assets/images/80.png'))),
              Listener(
                onPointerDown: (details) {
                  if (!isStylus && details.kind == ui.PointerDeviceKind.stylus) {
                    setState(() => isStylus = true);
                  }

                  if (isStylus && details.kind == ui.PointerDeviceKind.touch) {
                    setState(() => isStylus = false);
                  }
                },
                child: Column(
                  children: [
                    GestureDetector(
                      onPanStart: (details) {
                        if (!isStylus) return;
                        drawFilledCircle(details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), radius);
                      },
                      // plotCircleAA(details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), radius),
                      onPanEnd: (details) => setState(() => lastPoint = null),
                      onPanUpdate: (details) {
                        if (!isStylus) return;
                        int x = details.localPosition.dx.toInt();
                        int y = details.localPosition.dy.toInt();

                        if (x > 0 && y > 0 && y * widget.width + x <= widget.maxPixels && lastPoint != null) {
                          List<Point> points = bresenham(lastPoint.x, lastPoint.y, x, y);

                          points.forEach((point) {
                            drawFilledCircle(point.x, point.y, radius);
                            // plotCircleAA(point.x, point.y, 1);
                          });
                          // plotCircleAA(x, y, radius);

                          setState(() => lastPoint = Point(x, y));
                          return;
                        }

                        setState(() => lastPoint = Point(x, y));
                      },
                      child: FutureBuilder<ui.Image>(
                        future: makeImage(),
                        // future: loadUiImage('assets/images/4k.jpg'),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            // return RawImage(
                            //   image: snapshot.data,
                            // );
                            return CustomPaint(
                                isComplex: true,
                                willChange: false,
                                size: Size(widget.width.toDouble(), widget.height.toDouble()),
                                painter:
                                    ImagePresenter(image: snapshot.data, width: widget.width, height: widget.height));
                          }

                          return Container();
                        },
                      ),
                    ),
                    Row(
                      children: [
                        FlatButton(
                            onPressed: () {
                              for (int i = 0; i < pixels.length; i++) {
                                pixels[i] = Color.fromRGBO(0, 0, 0, 0).value;
                              }

                              setState(() {
                                pixels = pixels;
                                lastPoint = null;
                              });
                            },
                            child: Text('Clear')),
                        FlatButton(onPressed: () => setState(() => radius = 1), child: Text('Size 1')),
                        FlatButton(onPressed: () => setState(() => radius = 2), child: Text('Size 2')),
                        FlatButton(onPressed: () => setState(() => radius = 3), child: Text('Size 3'))
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePresenter extends CustomPainter {
  ImagePresenter({this.width, this.height, this.image});

  final ui.Image image;
  final int width;
  final int height;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(
        image,
        new Offset(0.0, 0.0),
        new Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high);

    // var tas = 1;
    // paintImage(
    //     canvas: canvas,
    //     rect:
    //         Rect.fromCenter(center: Offset(width / 2, height / 2), width: width.toDouble(), height: height.toDouble()),
    //     image: image,
    //     scale: 1,
    //     fit: BoxFit.none,
    //     filterQuality: FilterQuality.low,
    //     isAntiAlias: true);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
