import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

class DrawDirect3 extends StatefulWidget {
  final int width;
  final int height;
  final int maxPixels;

  const DrawDirect3({Key key, this.width, this.height, this.maxPixels}) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<DrawDirect3> {
  Int32List pixels;
  Int32List shades;
  Point lastPoint;
  int color;

  void initState() {
    super.initState();
    pixels = Int32List(widget.width * widget.height);
    shades = Int32List(widget.width * widget.height);
    color = Color.fromRGBO(0, 0, 0, 0.7).value;
  }

  Future<ui.Image> makeImage() {
    final c = Completer<ui.Image>();

    // final Int32List pixels = Int32List(widget.width * widget.height);
    // for (int i = 0; i < pixels.length; i++) {
    //   pixels[i] = Color.fromRGBO(0, 255, 0, 0.3).value;
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

  plotLineWidth3(x0, y0, x1, y1, th, screenWidth, Int32List nextPixels) {
    /* plot an anti-aliased line of width th pixel */
    var dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1;
    var dy = (y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
    var err, e2 = sqrt(dx * dx + dy * dy); /* length */

    // if (th <= 1 || e2 == 0) return plotLineAA(x0,y0, x1,y1);         /* assert */
    dx *= 255 / e2;
    dy *= 255 / e2;
    th = 255 * (th - 1); /* scale values */

    if (dx < dy) {
      /* steep line */
      x1 = ((e2 + th / 2) / dy).round(); /* start offset */
      err = x1 * dy - th / 2; /* shift error value to offset width */
      for (x0 -= x1 * sx;; y0 += sy) {
        nextPixels[y0 * screenWidth + (x1 = x0)] = color;
        // setPixelAA(x1 = x0, y0, err);                  /* aliasing pre-pixel */
        for (e2 = dy - err - th; e2 + dy < 255; e2 += dy) {
          nextPixels[y0 * screenWidth + (x1 += sx)] = color;
          // setPixel(x1 += sx, y0);                      /* pixel on the line */
        }
        nextPixels[y0 * screenWidth + (x1 + sx)] = color;
        // setPixelAA(x1+sx, y0, e2);                    /* aliasing post-pixel */
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
      err = y1 * dx - th / 2; /* shift error value to offset width */
      for (y0 -= y1 * sy;; x0 += sx) {
        nextPixels[(y1 = y0) * screenWidth + x0] = color;
        // setPixelAA(x0, y1 = y0, err); /* aliasing pre-pixel */
        for (e2 = dx - err - th; e2 + dx < 255; e2 += dx) {
          nextPixels[(y1 += sy) * screenWidth + x0] = color;
          // setPixel(x0, y1 += sy); /* pixel on the line */
        }
        nextPixels[(y1 + sy) * screenWidth + x0] = color;
        // setPixelAA(x0, y1 + sy, e2); /* aliasing post-pixel */
        if (x0 == x1) break;
        err += dy; /* x-step */
        if (err > 255) {
          err -= dx;
          y0 += sy;
        } /* y-step */
      }
    }

    setState(() {
      pixels = nextPixels;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              // Center(child: Image(fit: BoxFit.cover, image: AssetImage('assets/images/77.webp'))),
              Column(
                children: [
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() =>
                          pixels[(details.localPosition.dy.toInt()) * widget.width + details.localPosition.dx.toInt()] =
                              color);
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
                          plotLineWidth3(lastPoint.x, lastPoint.y, details.localPosition.dx.toInt(),
                              details.localPosition.dy.toInt(), 4, widget.width, pixels);

                          setState(() {
                            lastPoint = Point(details.localPosition.dx.toInt(), details.localPosition.dy.toInt());
                          });
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
                            // Container(
                            //   width: 900,
                            //   height: 1000,
                            //   child: new BackdropFilter(
                            //     filter: new ImageFilter.blur(sigmaX: 0.35, sigmaY: 0.35),
                            //     child: new Container(
                            //       decoration: new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                            //     ),
                            //   ),
                            // )
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
                      FlatButton(
                          onPressed: () => setState(() {
                                color = Color.fromRGBO(0, 0, 0, 0.7).value;
                              }),
                          child: Text('Black')),
                      FlatButton(
                          onPressed: () => setState(() {
                                color = Color.fromRGBO(0, 0, 255, 0.7).value;
                              }),
                          child: Text('Red')),
                      FlatButton(
                          onPressed: () => setState(() {
                                color = Color.fromRGBO(0, 255, 0, 0.7).value;
                              }),
                          child: Text('Green')),
                      FlatButton(
                          onPressed: () => setState(() {
                                color = Color.fromRGBO(255, 0, 0, 0.7).value;
                              }),
                          child: Text('Blue'))
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
