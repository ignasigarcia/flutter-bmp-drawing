// TODO
// Graphics options
//    Make image double the size
//    Tune current plotLineWidth
//    use Xiao Wu's
// Save image
// Pass parameters for color and thickness
// Do not write on top of a solid color
// Zoom

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

class DrawDirect6Overlap extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawDirect6Overlap({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<DrawDirect6Overlap> {
  Int32List pixels;
  Point lastPoint;
  int color;
  double thickness = 2;

  void initState() {
    super.initState();
    pixels = Int32List(widget.width * widget.height);
    color = Color.fromRGBO(0, 0, 0, 1).value;
  }

  Future<ui.Image> makeImage() {
    final c = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      widget.width,
      widget.height,
      ui.PixelFormat.rgba8888,
      c.complete,
    );

    return c.future;
  }

  setPixel(x, y) {
    pixels[y * widget.width + x] = color;
  }

  setPixelAA(x, y, s) {
    int index = y * widget.width + x;
    if (pixels[index] != 0) {
      setPixel(x, y);
      return;
    }

    int color = s.toInt();
    pixels[index] = Color.fromRGBO(color, color, color, 1).value;
  }

  plotCircle(xm, ym, r) {
    var x = -r, y = 0, err = 2 - 2 * r;
    do {
      setPixel(xm - x, ym + y);
      setPixel(xm - y, ym - x);
      setPixel(xm + x, ym - y);
      setPixel(xm + y, ym + x);
      r = err;

      if (r <= y) err += ++y * 2 + 1;

      if (r > x || err > y) err += ++x * 2 + 1;
    } while (x < 0);

    setState(() => pixels = pixels);
  }

  plotCircleAA(xm, ym, r) {
    var x = r, y = 0;
    var i, x2, e2, err = 2 - 2 * r;
    r = 1 - err;

    for (;;) {
      i = 255 * (err + 2 * (x + y) - 2).abs() / r;
      setPixelAA(xm + x, ym - y, i);
      setPixelAA(xm + y, ym + x, i);
      setPixelAA(xm - x, ym + y, i);
      setPixelAA(xm - y, ym - x, i);

      if (x == 0) break;

      e2 = err;
      x2 = x;

      if (err > y) {
        i = 255 * (err + 2 * x - 1) / r;
        if (i < 255) {
          setPixelAA(xm + x, ym - y + 1, i);
          setPixelAA(xm + y - 1, ym + x, i);
          setPixelAA(xm - x, ym + y - 1, i);
          setPixelAA(xm - y + 1, ym - x, i);
        }
        err -= --x * 2 - 1;
      }
      if (e2 <= x2--) {
        i = 255 * (1 - 2 * y - e2) / r;

        if (i < 255) {
          setPixelAA(xm + x2, ym - y, i);
          setPixelAA(xm + y, ym + x2, i);
          setPixelAA(xm - x2, ym + y, i);
          setPixelAA(xm - y, ym - x2, i);
        }
        err -= --y * 2 - 1;
      }
    }

    setState(() => pixels = pixels);
  }

  plotLine(x0, y0, x1, y1) {
    var dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
    var dy = -(y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
    var err = dx + dy, e2;

    for (;;) {
      setPixel(x0, y0);
      if (x0 == x1 && y0 == y1) break;
      e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }

      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  plotLineWidth(x0, y0, x1, y1, th) {
    var dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
    var dy = (y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
    var err, e2 = sqrt(dx * dx + dy * dy);

    if (th <= 1 || e2 == 0) {
      return plotLineWidth(x0, y0, x1, y1, thickness);
    }

    dx *= 255 / e2;
    dy *= 255 / e2;
    th = 255 * (th - 1);

    if (dx < dy) {
      x1 = ((e2 + th / 2) / dy).round();
      err = x1 * dy - th / 1.5;

      for (x0 -= x1 * sx;; y0 += sy) {
        setPixelAA(x1 = x0, y0, err);

        for (e2 = dy - err - th; e2 + dy < 255; e2 += dy) {
          setPixel(x1 += sx, y0);
        }

        setPixelAA(x1 + sx, y0, e2);

        if (y0 == y1) break;
        err += dx;

        if (err > 255) {
          err -= dy;
          x0 += sx;
        }
      }
    } else {
      y1 = ((e2 + th / 2) / dx).round();
      err = y1 * dx - th / 1.5;

      for (y0 -= y1 * sy;; x0 += sx) {
        setPixelAA(x0, y1 = y0, err);
        for (e2 = dx - err - th; e2 + dx < 255; e2 += dx) {
          setPixel(x0, y1 += sy);
        }

        setPixelAA(x0, y1 + sy, e2);
        if (x0 == x1) break;
        err += dy;

        if (err > 255) {
          err -= dx;
          y0 += sy;
        }
      }
    }

    setState(() => pixels = pixels);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Center(child: Image(fit: BoxFit.cover, image: AssetImage('assets/images/80.png'))),
              Column(
                children: [
                  GestureDetector(
                    onPanStart: (details) {
                      // TODO plot circle
                    },
                    onPanEnd: (details) => setState(() => lastPoint = null),
                    onPanUpdate: (details) {
                      int x = details.localPosition.dx.toInt();
                      int y = details.localPosition.dy.toInt();

                      if (x > 0 && y > 0 && y * widget.width + x <= widget.maxPixels && lastPoint != null) {
                        plotLineWidth(lastPoint.x, lastPoint.y, x, y, thickness);
                        setState(() => lastPoint = Point(x, y));
                        return;
                      }

                      setState(() => lastPoint = Point(x, y));
                    },
                    child: FutureBuilder<ui.Image>(
                      future: makeImage(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return CustomPaint(
                              size: Size(widget.width.toDouble(), widget.height.toDouble()),
                              painter: ImagePresenter(image: snapshot.data));
                        }

                        return null;
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
                      // FlatButton(
                      //     onPressed: () => setState(() {
                      //           color = Color.fromRGBO(0, 0, 0, 0.7).value;
                      //         }),
                      //     child: Text('Black')),
                      // FlatButton(
                      //     onPressed: () => setState(() {
                      //           color = Color.fromRGBO(0, 0, 255, 0.7).value;
                      //         }),
                      //     child: Text('Red')),
                      // FlatButton(
                      //     onPressed: () => setState(() {
                      //           color = Color.fromRGBO(0, 255, 0, 0.7).value;
                      //         }),
                      //     child: Text('Green')),
                      // FlatButton(
                      //     onPressed: () => setState(() {
                      //           color = Color.fromRGBO(255, 0, 0, 0.7).value;
                      //         }),
                      //     child: Text('Blue'))
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePresenter extends CustomPainter {
  ImagePresenter({this.image});

  ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    // var sigma = 0.0;
    canvas.drawImage(
        image,
        new Offset(0.0, 0.0),
        new Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.low);
    // ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
