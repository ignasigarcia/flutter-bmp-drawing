import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class Signature extends StatefulWidget {
  final Color color;
  final double strokeWidth;
  final CustomPainter backgroundPainter;
  final Function onSign;
  final int width;
  final int height;

  Signature({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.backgroundPainter,
    this.onSign,
    this.width,
    this.height,
    Key key,
  }) : super(key: key);

  SignatureState createState() => SignatureState();

  static SignatureState of(BuildContext context) {
    return context.findAncestorStateOfType<SignatureState>();
  }
}

class _SignaturePainter extends CustomPainter {
  final double strokeWidth;
  final List<Offset> points;
  final Color strokeColor;
  Paint _linePaint;

  _SignaturePainter({@required this.points, @required this.strokeColor, @required this.strokeWidth}) {
    _linePaint = Paint()
      ..isAntiAlias = true
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // _lastSize = size;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i], points[i + 1], _linePaint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter other) => other.points != points;
}

class SignatureState extends State<Signature> {
  List<Offset> _points = <Offset>[];
  _SignaturePainter _painter;
  Size _lastSize;

  SignatureState();

  Future<ui.Image> makeImage() async {
    final c = Completer<ui.Image>();

    // var image = await getData();
    // ui.decodeImageFromPixels(
    //   widget.width,
    //   widget.height,
    //   ui.PixelFormat.rgba8888,
    //   c.complete,
    // );

    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => afterFirstLayout(context));
    _painter = _SignaturePainter(points: _points, strokeColor: widget.color, strokeWidth: widget.strokeWidth);
    return ClipRect(
      child: Stack(
        children: [
          FutureBuilder<ui.Image>(
            future: makeImage(),
            builder: (context, snapshot) {
              return RawImage(
                image: snapshot.data,
                fit: BoxFit.contain,
              );
            },
          ),
          CustomPaint(
            // painter: widget.backgroundPainter,
            foregroundPainter: _painter,
            child: GestureDetector(
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
            ),
          )
        ],
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    RenderBox referenceBox = context.findRenderObject();
    Offset localPostion = referenceBox.globalToLocal(details.globalPosition);
    setState(() {
      _points = List.from(_points)..add(localPostion)..add(localPostion);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // RenderBox referenceBox = context.findRenderObject();
    // Offset localPosition = referenceBox.globalToLocal(details.globalPosition);

    setState(() {
      _points = List.from(_points)..add(details.localPosition);
      // if (widget.onSign != null) {
      //   widget.onSign();
      // }
    });
  }

  void _onDragEnd(DragEndDetails details) => _points.add(null);

  Future<ui.Image> getData() {
    var recorder = ui.PictureRecorder();
    var origin = Offset(0.0, 0.0);
    var paintBounds = Rect.fromPoints(_lastSize.topLeft(origin), _lastSize.bottomRight(origin));
    var canvas = Canvas(recorder, paintBounds);
    if (widget.backgroundPainter != null) {
      widget.backgroundPainter.paint(canvas, _lastSize);
    }
    _painter.paint(canvas, _lastSize);
    var picture = recorder.endRecording();
    return picture.toImage(_lastSize.width.round(), _lastSize.height.round());
  }

  void clear() {
    setState(() {
      _points = [];
    });
  }

  bool get hasPoints => _points.length > 0;

  List<Offset> get points => _points;

  afterFirstLayout(BuildContext context) {
    _lastSize = context.size;
  }
}
