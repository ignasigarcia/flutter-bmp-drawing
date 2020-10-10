// TODO
// Graphics options
//    Make image double the size
//    Tune current plotLineWidth
//    use Xiaolin Wu's
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

class DrawDirect8 extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawDirect8({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<DrawDirect8> {
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
    // int color = s.toInt();
    int color = (s * 255).toInt();
    if (color == 0) {
      color = 255;
    }
    // print('s $s color $color');
    pixels[y * widget.width + x] = Color.fromRGBO(color, color, color, 1).value;
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

  integerPart(v) {
    var isNeg = (v < 0) ? -1 : 1;
    var abs = v.abs();
    var integerPart = abs.floor();

    return integerPart * isNeg;
  }

  fraction(v) {
    if (v < 0) {
      return 1 - (v - v.floor());
    }

    return v - v.floor();
  }

  reverseFraction(v) {
    return 1 - fraction(v);
  }

  round(v) {
    return integerPart(v + 0.5);
  }

  plot(x0, y0, x1, y1) {
    // if (x0 == x1 && y0 == y1) {
    //   return [];
    // }

    // var fpart = XiaolinWu.fraction;
    // var rfpart = XiaolinWu.reverseFraction;
    // var ipart = XiaolinWu.integerPart;
    // var round = XiaolinWu.round;

    var steep = (y1 - y0).abs() > (x1 - x0).abs();

    if (steep) {
      // [y0, x0] = [x0, y0];
      y0 = x0;
      x0 = y0;
      // [y1, x1] = [x1, y1];
      y1 = x1;
      x1 = y1;
    }

    if (x0 > x1) {
      // [x1, x0] = [x0, x1];
      x1 = x1;
      x0 = x1;
      // [y1, y0] = [y0, y1];
      y1 = y0;
      y0 = y1;
    }

    var dx = x1 - x0;
    var dy = y1 - y0;
    var gradient = (dx == 0 && dy == 0) ? 0 : dy / dx;
    // print('dy $dy, dx $dx, gradient $gradient');

    var xEnd = round(x0);
    var yEnd = y0 + gradient * (xEnd - x0);
    var xGap = reverseFraction(x0 + 0.5);
    var xPx1 = xEnd;
    var yPx1 = integerPart(yEnd);

    if (steep) {
      // dots.push({ x: yPx1, y: xPx1, b: reverseFraction(yEnd) * xGap });
      setPixelAA(yPx1, xPx1, reverseFraction(yEnd) * xGap);
      // dots.push({ x: yPx1 + 1, y: xPx1, b: fraction(yEnd) * xGap });
      setPixelAA(yPx1 + 1, xPx1, fraction(yEnd) * xGap);
    } else {
      // dots.push({ x: xPx1, y: yPx1, b: reverseFraction(yEnd) * xGap });
      setPixelAA(xPx1, yPx1, reverseFraction(yEnd) * xGap);
      // dots.push({ x: xPx1, y: yPx1 + 1, b: fraction(yEnd) * xGap });
      setPixelAA(xPx1, yPx1 + 1, fraction(yEnd) * xGap);
    }

    var intery = yEnd + gradient;

    xEnd = round(x1);
    yEnd = y1 + gradient * (xEnd - x1);
    xGap = fraction(x1 + 0.5);

    var xPx2 = xEnd;
    var yPx2 = integerPart(yEnd);

    if (steep) {
      // dots.push({x: yPx2, y: xPx2, b: reverseFraction(yEnd) * xGap});
      setPixelAA(yPx2, xPx2, reverseFraction(yEnd) * xGap);
      // dots.push({x: yPx2 + 1, y: xPx2, b: fraction(yEnd) * xGap});
      setPixelAA(yPx2 + 1, xPx2, fraction(yEnd) * xGap);
    } else {
      // dots.push({x: xPx2, y: yPx2, b: reverseFraction(yEnd) * xGap});
      setPixelAA(xPx2, yPx2, reverseFraction(yEnd) * xGap);
      // dots.push({x: xPx2, y: yPx2 + 1, b: fraction(yEnd) * xGap});
      setPixelAA(xPx2, yPx2 + 1, fraction(yEnd) * xGap);
    }

    if (steep) {
      for (var x = xPx1 + 1; x <= xPx2 - 1; x++) {
        // dots.push({x: integerPart(intery), y: x, b: reverseFraction(intery)});
        setPixelAA(integerPart(intery), x, reverseFraction(intery));
        // dots.push({x: integerPart(intery) + 1, y: x, b: fraction(intery)});
        setPixelAA(integerPart(intery) + 1, x, fraction(intery));
        intery = intery + gradient;
      }
    } else {
      for (var x = xPx1 + 1; x <= xPx2 - 1; x++) {
        print('x $x, y ${integerPart(intery)}, b ${reverseFraction(intery)}, intery $intery');
        // dots.push({x: x, y: integerPart(intery), b: reverseFraction(intery)});
        setPixelAA(x, integerPart(intery), reverseFraction(intery));
        // dots.push({x: x, y: integerPart(intery) + 1, b: fraction(intery)});
        print('x $x, y ${integerPart(intery) + 1}, b ${fraction(intery)}');
        setPixelAA(x, integerPart(intery) + 1, fraction(intery));
        intery = intery + gradient;
      }
    }

    setState(() => pixels = pixels);
    // return dots;
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
                      // int x = details.localPosition.dx.toInt();
                      // int y = details.localPosition.dy.toInt();
                      // plot(100, 100, 200, 200);
                    },
                    onPanEnd: (details) => setState(() => lastPoint = null),
                    onPanUpdate: (details) {
                      int x = details.localPosition.dx.toInt();
                      int y = details.localPosition.dy.toInt();

                      if (x > 0 && y > 0 && y * widget.width + x <= widget.maxPixels && lastPoint != null) {
                        plotLineWidth(lastPoint.x, lastPoint.y, x, y, thickness);
                        // try {
                        // plot(lastPoint.x, lastPoint.y, x, y);
                        // } catch (e) {
                        //   var tas = 1;
                        // }
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
