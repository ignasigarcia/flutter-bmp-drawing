import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

class Signature extends StatefulWidget {
  final Color color;
  final double strokeWidth;
  final CustomPainter backgroundPainter;
  final Function onSign;

  Signature({
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.backgroundPainter,
    this.onSign,
    Key key,
  }) : super(key: key);

  SignatureState createState() => SignatureState();

  static SignatureState of(BuildContext context) {
    return context.findAncestorStateOfType<SignatureState>();
  }
}

class _SignaturePainter extends CustomPainter {
  // Size _lastSize;
  final double strokeWidth;
  final Float32List points;
  final Color strokeColor;
  Paint _linePaint;

  _SignaturePainter({@required this.points, @required this.strokeColor, @required this.strokeWidth}) {
    _linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // var points = Float32List.fromList([300.0, 300.0, 300, 400]);
    canvas.drawRawPoints(PointMode.polygon, Float32List.fromList(points), _linePaint);
    // _lastSize = size;
    // for (int i = 0; i < points.length - 1; i++) {
    //   if (points[i] != null && points[i + 1] != null) {
    //     canvas.drawLine(points[i], points[i + 1], _linePaint);
    //   }
    // }
  }

  @override
  bool shouldRepaint(_SignaturePainter other) => other.points != points;
}

class SignatureState extends State<Signature> {
  List<Offset> _points = <Offset>[];
  int currentPoint = 0;
  Float32List _fpoints = Float32List(10000);
  _SignaturePainter _painter;
  Size _lastSize;
  var rng = new Random();

  SignatureState();

  @override
  void initState() {
    super.initState();
    //   for (int i = 0; i < 200000; i++) {
    //     points.add(Offset(i * 0.5, i * 0.5));
    //   }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => afterFirstLayout(context));
    _painter = _SignaturePainter(points: _fpoints, strokeColor: widget.color, strokeWidth: widget.strokeWidth);
    return ClipRect(
      child: CustomPaint(
        painter: widget.backgroundPainter,
        foregroundPainter: _painter,
        child: GestureDetector(
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onPanStart: _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd),
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    // RenderBox referenceBox = context.findRenderObject();
    // Offset localPostion = referenceBox.globalToLocal(details.globalPosition);
    // setState(() {
    //   _points = List.from(_points)..add(localPostion)..add(localPostion);
    // });

    // _fpoints[currentPoint] = details.localPosition.dx;
    // _fpoints[currentPoint + 1] = details.localPosition.dy;
    // print('${_fpoints[currentPoint]} ${_fpoints[currentPoint + 1]}');
    // var tas = 1;
    // setState(() {
    //   _fpoints = _fpoints;
    //   currentPoint = currentPoint + 1;
    // });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _fpoints[currentPoint] = details.globalPosition.dx;
    _fpoints[currentPoint + 1] = details.globalPosition.dy;

    print('${_fpoints[currentPoint]} ${_fpoints[currentPoint + 1]}');
    setState(() {
      _fpoints = _fpoints;
      currentPoint = currentPoint + 1;
    });

    // RenderBox referenceBox = context.findRenderObject();
    // Offset localPosition = referenceBox.globalToLocal(details.globalPosition);
    //
    // setState(() {
    //   _points = List.from(_points)..add(localPosition);
    //   if (widget.onSign != null) {
    //     widget.onSign();
    //   }
    // });
  }

  // void _onDragEnd(DragEndDetails details) => _points.add(null);
  void _onDragEnd(DragEndDetails details) {}

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
