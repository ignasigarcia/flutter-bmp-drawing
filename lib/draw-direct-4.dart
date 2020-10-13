// TODO
// Tune current plotLineWidth
// Pass parameters for color and thickness
// Do not write on top of a solid color
// Zoom

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

class DrawDirect4 extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawDirect4({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<DrawDirect4> {
  Int32List pixels;
  Int32List shades;
  Point lastPoint;
  int color;

  void initState() {
    super.initState();
    pixels = Int32List(widget.width * widget.height);
    shades = Int32List(widget.width * widget.height);
    color = Color.fromRGBO(0, 0, 0, 1).value;
  }

  Future<ui.Image> makeImage() {
    final c = Completer<ui.Image>();

    // final Int32List pixels = Int32List(widget.width * widget.height);
    // for (int i = 0; i < pixels.length; i++) {
    //   pixels[i] = pixels[i] != 0 ? pixels[i] : Color.fromRGBO(0, 255, 0, 0.3).value;
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

  // plotLineWidth3(x0, y0, x1, y1, th, screenWidth, Int32List nextPixels) {
  //   /* plot an anti-aliased line of width th pixel */
  //   var dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
  //   var dy = (y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
  //   var err, e2 = sqrt(dx * dx + dy * dy); /* length */
  //
  //   // if (th <= 1 || e2 == 0) return plotLineAA(x0,y0, x1,y1);         /* assert */
  //   dx *= 255 / e2;
  //   dy *= 255 / e2;
  //   th = 255 * (th - 1); /* scale values */
  //
  //   if (dx < dy) {
  //     /* steep line */
  //     x1 = ((e2 + th / 2) / dy).round(); /* start offset */
  //     err = x1 * dy - th / 2; /* shift error value to offset width */
  //     for (x0 -= x1 * sx;; y0 += sy) {
  //       nextPixels[y0 * screenWidth + (x1 = x0)] = color;
  //       // setPixelAA(x1 = x0, y0, err);                  /* aliasing pre-pixel */
  //       for (e2 = dy - err - th; e2 + dy < 255; e2 += dy) {
  //         nextPixels[y0 * screenWidth + (x1 += sx)] = color;
  //         // setPixel(x1 += sx, y0);                      /* pixel on the line */
  //       }
  //       nextPixels[y0 * screenWidth + (x1 + sx)] = color;
  //       // setPixelAA(x1+sx, y0, e2);                    /* aliasing post-pixel */
  //       if (y0 == y1) break;
  //       err += dx; /* y-step */
  //       if (err > 255) {
  //         err -= dy;
  //         x0 += sx;
  //       } /* x-step */
  //     }
  //   } else {
  //     /* flat line */
  //     y1 = ((e2 + th / 2) / dx).round(); /* start offset */
  //     err = y1 * dx - th / 2; /* shift error value to offset width */
  //     for (y0 -= y1 * sy;; x0 += sx) {
  //       nextPixels[(y1 = y0) * screenWidth + x0] = color;
  //       // setPixelAA(x0, y1 = y0, err); /* aliasing pre-pixel */
  //       for (e2 = dx - err - th; e2 + dx < 255; e2 += dx) {
  //         nextPixels[(y1 += sy) * screenWidth + x0] = color;
  //         // setPixel(x0, y1 += sy); /* pixel on the line */
  //       }
  //       nextPixels[(y1 + sy) * screenWidth + x0] = color;
  //       // setPixelAA(x0, y1 + sy, e2); /* aliasing post-pixel */
  //       if (x0 == x1) break;
  //       err += dy; /* x-step */
  //       if (err > 255) {
  //         err -= dx;
  //         y0 += sy;
  //       } /* y-step */
  //     }
  //   }
  //
  //   setState(() {
  //     pixels = nextPixels;
  //   });
  // }

  setPixel(x, y) {
    pixels[y * widget.width + x] = color;
  }

  plotCircle(xm, ym, r) {
    var x = -r, y = 0, err = 2 - 2 * r; /* bottom left to top right */
    do {
      setPixel(xm - x, ym + y); /*   I. Quadrant +x +y */
      setPixel(xm - y, ym - x); /*  II. Quadrant -x +y */
      setPixel(xm + x, ym - y); /* III. Quadrant -x -y */
      setPixel(xm + y, ym + x); /*  IV. Quadrant +x -y */
      r = err;
      if (r <= y) err += ++y * 2 + 1; /* y step */
      if (r > x || err > y) err += ++x * 2 + 1; /* x step */
    } while (x < 0);

    setState(() {
      pixels = pixels;
    });
  }

  setPixelAA(x, y, s) {
    int color = s.toInt();
    pixels[y * widget.width + x] = Color.fromRGBO(color, color, color, 1).value;
  }

  plotLineAA(x0, y0, x1, y1) {
    /* draw a black (0) anti-aliased line on white (255) background */
    var dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
    var dy = (y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
    var err = dx - dy, e2, x2; /* error value e_xy */
    var ed = dx + dy == 0 ? 1 : sqrt(dx * dx + dy * dy);

    for (;;) {
      /* pixel loop */
      setPixelAA(x0, y0, 255 * (err - dx + dy).abs() / ed);
      e2 = err;
      x2 = x0;
      if (2 * e2 >= -dx) {
        /* x step */
        if (x0 == x1) break;
        if (e2 + dy < ed) setPixelAA(x0, y0 + sy, 255 * (e2 + dy) / ed);
        err -= dy;
        x0 += sx;
      }
      if (2 * e2 <= dy) {
        /* y step */
        if (y0 == y1) break;
        if (dx - e2 < ed) setPixelAA(x2 + sx, y0, 255 * (dx - e2) / ed);
        err += dx;
        y0 += sy;
      }
    }

    setState(() {
      pixels = pixels;
    });
  }

  plotCircleAA(xm, ym, r) {
    /* draw a black anti-aliased circle on white background */
    var x = r, y = 0; /* II. quadrant from bottom left to top right */
    var i, x2, e2, err = 2 - 2 * r; /* error of 1.step */
    r = 1 - err;
    for (;;) {
      i = 255 * (err + 2 * (x + y) - 2).abs() / r; /* get blend value of pixel */
      setPixelAA(xm + x, ym - y, i); /*   I. Quadrant */
      setPixelAA(xm + y, ym + x, i); /*  II. Quadrant */
      setPixelAA(xm - x, ym + y, i); /* III. Quadrant */
      setPixelAA(xm - y, ym - x, i); /*  IV. Quadrant */
      if (x == 0) break;
      e2 = err;
      x2 = x; /* remember values */
      if (err > y) {
        /* x step */
        i = 255 * (err + 2 * x - 1) / r; /* outward pixel */
        if (i < 255) {
          setPixelAA(xm + x, ym - y + 1, i);
          setPixelAA(xm + y - 1, ym + x, i);
          setPixelAA(xm - x, ym + y - 1, i);
          setPixelAA(xm - y + 1, ym - x, i);
        }
        err -= --x * 2 - 1;
      }
      if (e2 <= x2--) {
        /* y step */
        i = 255 * (1 - 2 * y - e2) / r; /* inward pixel */
        if (i < 255) {
          setPixelAA(xm + x2, ym - y, i);
          setPixelAA(xm + y, ym + x2, i);
          setPixelAA(xm - x2, ym + y, i);
          setPixelAA(xm - y, ym - x2, i);
        }
        err -= --y * 2 - 1;
      }

      // Fill circle
      // for (int y = -r; y <= r; y++) for (int x = -r; x <= r; x++) if (x * x + y * y <= r * r) setPixel(xm + x, ym + y);
    }

    setState(() {
      pixels = pixels;
    });
  }

  plotLineWidth(x0, y0, x1, y1, th) {
    /* plot an anti-aliased line of width th pixel */
    var dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
    var dy = (y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
    var err, e2 = sqrt(dx * dx + dy * dy); /* length */

    if (th <= 1 || e2 == 0) return plotLineAA(x0, y0, x1, y1); /* assert */
    dx *= 255 / e2;
    dy *= 255 / e2;
    th = 255 * (th - 1); /* scale values */

    if (dx < dy) {
      /* steep line */
      x1 = ((e2 + th / 2) / dy).round(); /* start offset */
      err = x1 * dy - th / 1.5; /* shift error value to offset width */
      for (x0 -= x1 * sx;; y0 += sy) {
        setPixelAA(x1 = x0, y0, err); /* aliasing pre-pixel */
        for (e2 = dy - err - th; e2 + dy < 255; e2 += dy) setPixel(x1 += sx, y0); /* pixel on the line */
        setPixelAA(x1 + sx, y0, e2); /* aliasing post-pixel */
        if (y0 == y1) break;
        err += dx; /* y-step */
        if (err > 255) {
          err -= dy;
          x0 += sx;
        } /* x-step */
      }
    } else {
      /* flat line */
      y1 = ((e2 + th / 2) / dx).round(); /* start offset */
      err = y1 * dx - th / 1.5; /* shift error value to offset width */
      for (y0 -= y1 * sy;; x0 += sx) {
        setPixelAA(x0, y1 = y0, err); /* aliasing pre-pixel */
        for (e2 = dx - err - th; e2 + dx < 255; e2 += dx) setPixel(x0, y1 += sy); /* pixel on the line */
        setPixelAA(x0, y1 + sy, e2); /* aliasing post-pixel */
        if (x0 == x1) break;
        err += dy; /* x-step */
        if (err > 255) {
          err -= dx;
          y0 += sy;
        } /* y-step */
      }
    }

    setState(() {
      pixels = pixels;
    });
  }

  @override
  Widget build(BuildContext context) {
    // var rng = new Random();
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

                      // plotLineAA(
                      //     details.localPosition.dx.toInt(),
                      //     details.localPosition.dy.toInt(),
                      //     details.localPosition.dx.toInt() + rng.nextInt(100),
                      //     details.localPosition.dy.toInt() + rng.nextInt(100));
                      // plotCircle(details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), 20);
                      // plotCircleAA(details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), 20);
                      // setState(() =>
                      //     pixels[(details.localPosition.dy.toInt()) * widget.width + details.localPosition.dx.toInt()] =
                      //         color);
                      plotLineWidth(details.localPosition.dx.toInt(), details.localPosition.dy.toInt(),
                          details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), 4);
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
                          // plotLineAA(lastPoint.x, lastPoint.y, details.localPosition.dx.toInt(),
                          //     details.localPosition.dy.toInt());
                          plotLineWidth(lastPoint.x, lastPoint.y, details.localPosition.dx.toInt(),
                              details.localPosition.dy.toInt(), 2);
                          // plotCircleAA(details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), 2);

                          setState(() {
                            lastPoint = Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                          });
                          return;
                        }

                        setState(() {
                          lastPoint = Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                        });
                      }
                    },
                    child: FutureBuilder<ui.Image>(
                      future: makeImage(),
                      builder: (context, snapshot) {
                        return Stack(
                          children: [
                            RawImage(
                              image: snapshot.data,
                              fit: BoxFit.contain,
                            ),
                            Container(
                              width: 900,
                              height: 1000,
                              child: new BackdropFilter(
                                filter: new ImageFilter.blur(sigmaX: 0.2, sigmaY: 0.2),
                                child: new Container(
                                  decoration: new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                                ),
                              ),
                            )
                          ],
                        );
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
