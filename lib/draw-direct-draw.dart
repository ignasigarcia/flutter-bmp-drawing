import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DrawDirect extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawDirect({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

const int black = 4278190080; // Color.fromRGBO(0, 0, 0, 1).value

// void plotLineWidth(int x0, int y0, int x1, int y1, double wd) {
//   int dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
//   int dy = (y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
//   int err = dx - dy, e2, x2, y2; /* error value e_xy */
//   double ed = dx + dy == 0 ? 1 : sqrt(dx * dx + dy * dy);
//
//   for (wd = (wd + 1) / 2;;) {
//     /* pixel loop */
//     // setPixelColor(x0,y0,max(0,255*(abs(err-dx+dy)/ed-wd+1)));
//     e2 = err;
//     x2 = x0;
//     if (2 * e2 >= -dx) {
//       /* x step */
//       for (e2 += dy; e2 < ed * wd && (y1 != y2 || dx > dy); e2 += dx) {
//         // for (e2 += dy, y2 = y0; e2 < ed*wd && (y1 != y2 || dx > dy); e2 += dx) {
//         // setPixelColor(x0, y2 += sy, max(0,255*(abs(e2)/ed-wd+1)));
//         if (x0 == x1) break;
//         e2 = err;
//         err -= dy;
//         x0 += sx;
//       }
//     }
//
//     if (2 * e2 <= dy) {
//       /* y step */
//       for (e2 = dx - e2; e2 < ed * wd && (x1 != x2 || dx < dy); e2 += dy) {
//         // setPixelColor(x2 += sx, y0, max(0,255*(abs(e2)/ed-wd+1)));
//         if (y0 == y1) break;
//         err += dx;
//         y0 += sy;
//       }
//     }
//   }
// }

// wres(x0, y0, x1, y1, width, [fn]) {
//   List<Point> arr = [];
//
//   if (fn == null) {
//     fn = (x, y) {
//       arr.add(Point(x, y));
//     };
//   }
// // Fall back to original bresenham algorihm in case we got a too thin line
// // if (width < 1) {
// // return bresehmham(from[0], from[1], to[0], to[1], callback);
// // }
//
//   int deltaX = (x1 - x0).abs(),
//       stepX = x0 < x1 ? 1 : -1,
//       deltaY = (y1 - y0).abs(),
//       stepY = y0 < y1 ? 1 : -1,
//       err = deltaX - deltaY,
//       e2,
//       x2,
//       y2;
//
//   double ed = deltaX + deltaY == 0 ? 1 : sqrt(deltaX * deltaX + deltaY * deltaY);
//
// //  width = (width+1)/2;
//
//   while (true) {
//     fn(x0, y0);
//     e2 = err;
//     x2 = x0;
//
// // loop over all horizontal parts
//     if (2 * e2 >= -deltaX) {
//       e2 += deltaY;
//       y2 = y0;
//       while (e2 < ed * width && (y1 != y2 || deltaX > deltaY)) {
//         fn(x0, y2 += stepY);
//         e2 += deltaX;
//       }
//       if (x0 == x1) {
//         break;
//       }
//       e2 = err;
//       err -= deltaY;
//       x0 += stepX;
//     }
//
// // loop over all vertical parts
//     if (2 * e2 <= deltaY) {
//       e2 = deltaX - e2;
//       while (e2 < ed * width && (x1 != x2 || deltaX < deltaY)) {
//         fn(x2 += stepX, y0);
//         e2 += deltaY;
//       }
//       if (y0 == y1) {
//         break;
//       }
//       err += deltaX;
//       y0 += stepY;
//     }
//   }
//
//   return arr;
// }

// Int32List bresenhamPixel(x0, y0, x1, y1, width, height, [fn]) {
//   Int32List arr = Int32List(width * height);
//   if (fn == null) {
//     fn = (x, y) {
//       arr[y * width + x] = black;
//     };
//   }
//   var dx = x1 - x0;
//   var dy = y1 - y0;
//   var adx = dx.abs();
//   var ady = dy.abs();
//   var eps = 0;
//   var sx = dx > 0 ? 1 : -1;
//   var sy = dy > 0 ? 1 : -1;
//
//   if (adx > ady) {
//     for (var x = x0, y = y0; sx < 0 ? x >= x1 : x <= x1; x += sx) {
//       fn(x, y);
//       eps += ady;
//       if ((eps << 1) >= adx) {
//         y += sy;
//         eps -= adx;
//       }
//     }
//   } else {
//     for (var x = x0, y = y0; sy < 0 ? y >= y1 : y <= y1; y += sy) {
//       fn(x, y);
//       eps += adx;
//
//       if ((eps << 1) >= ady) {
//         x += sx;
//         eps -= ady;
//       }
//     }
//   }
//   return arr;
// }

bresenham(x0, y0, x1, y1, width, [fn]) {
  List<int> arr = [];
  if (fn == null) {
    fn = (x, y) {
      arr.add(y * width + x);
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

drawCircle(int x, int y) {
  List<Point> points = List<Point>();
  //The center of the circle and its radius.
  int r = 3;
  //This here is sin(45) but i just hard-coded it.
  double sinus = 0.70710678118;
  //This is the distance on the axis from sin(90) to sin(45).
  int range = r ~/ (2 * sinus);
  for (int i = r; i >= range; --i) {
    int j = sqrt(r * r - i * i).toInt();
    for (int k = -j; k <= j; k++) {
      //We draw all the 4 sides at the same time.
      // PutPixel(x-k,y+i);
      points.add(Point(x - k, y + i));
      // PutPixel(x-k,y-i);
      points.add(Point(x - k, y - i));
      // PutPixel(x+i,y+k);
      points.add(Point(x + i, y + k));
      // PutPixel(x-i,y-k);
      points.add(Point(x - i, y - k));
    }
  }
  //To fill the circle we draw the circumscribed square.
  range = (r * sinus).toInt();
  for (int i = x - range + 1; i < x + range; i++) {
    for (int j = y - range + 1; j < y + range; j++) {
      // PutPixel(i,j);
      points.add(Point(i, j));
    }
  }

  return points;
}

class _DrawState extends State<DrawDirect> {
  // List<Point> points = List<Point>();
  Int32List pixels;
  Point lastPoint;

  void initState() {
    super.initState();
    pixels = Int32List(widget.width * widget.height);
  }

  Future<ui.Image> makeImage() {
    final c = Completer<ui.Image>();
    // final Int32List pixels = Int32List(widget.width * widget.height);

    // for (int i = 0; i < points.length; i++) {
    //   pixels[points[i].y * widget.width + points[i].x] = black;
    // }

    // for (int i = 0; i < pixels.length; i++) {
    //   pixels[i] = black;
    // }

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
                    setState(() =>
                        pixels[details.localPosition.dy.toInt() * widget.width + details.localPosition.dx.toInt()] =
                            black);
                  },
                  onPanEnd: (details) {
                    setState(() {
                      lastPoint = null;
                    });
                  },
                  onPanUpdate: (details) {
                    if (details.localPosition.dx.toInt() > 0 &&
                        details.localPosition.dy.toInt() > 0 &&
                        details.localPosition.dy.toInt() * widget.width + details.localPosition.dx.toInt() <=
                            widget.maxPixels) {
                      if (lastPoint != null) {
                        List<int> nextPoints = bresenham(lastPoint.x, lastPoint.y, details.localPosition.dx.toInt(),
                            details.localPosition.dy.toInt(), widget.width);

                        for (int i = 0; i < nextPoints.length; i++) {
                          pixels[nextPoints[i]] = black;
                          setState(() {
                            lastPoint = Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                            pixels = pixels;
                          });
                        }
                        return;
                      }

                      setState(() {
                        lastPoint = Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                      });
                      // var nextPoints = wres(
                      //     lastPoint.x, lastPoint.y, details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), 3);
                      // List<Point> roundPoints = List<Point>();
                      // nextPoints.forEach((point) {
                      //   roundPoints += drawCircle(point.x, point.y);
                      // });
                      // setState(() => points += nextPoints);
                    }
                  },
                  // onPanStart: (details) {
                  //   setState(() {
                  //     pixels[details.localPosition.dy.toInt() * widget.width + details.localPosition.dx.toInt()] =
                  //         black;
                  //   });
                  // },
                  // onPanUpdate: (details) {
                  //   if (details.localPosition.dx.toInt() > 0 &&
                  //       details.localPosition.dy.toInt() > 0 &&
                  //       details.localPosition.dy.toInt() * widget.width + details.localPosition.dx.toInt() <=
                  //           widget.maxPixels) {
                  //     Int32List nextPoints = Int32List(widget.width * widget.height);
                  //     if (lastPoint != null) {
                  //       nextPoints = bresenham(lastPoint.x, lastPoint.y, details.localPosition.dx.toInt());
                  //     }
                  //
                  //     setState(() {
                  //       // pixels[details.localPosition.dy.toInt() * widget.width + details.localPosition.dx.toInt()] =
                  //       //     black;
                  //       // pixels += nextPoints;
                  //       lastPoint = Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                  //     });
                  //   }
                  // },
                  child: FutureBuilder<ui.Image>(
                    future: makeImage(),
                    builder: (context, snapshot) {
                      return RawImage(
                        image: snapshot.data,
                      );
                    },
                  ),
                ),
                // FlatButton(onPressed: () => setState(() => points = []), child: Text('Clear'))
                FlatButton(
                    onPressed: () => setState(() {
                          for (int i = 0; i < pixels.length; i++) {
                            pixels[i] = Color.fromRGBO(0, 0, 0, 0).value;
                          }

                          setState(() {
                            pixels = pixels;
                            lastPoint = null;
                          });
                        }),
                    child: Text('Clear'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
