import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class CornerAdjustmentDialog extends StatefulWidget {
  final String imageBase64;
  final List<dynamic> corners;
  final double ratio;
  final Map<String, dynamic> previewSize;

  CornerAdjustmentDialog({
    required this.imageBase64,
    required this.corners,
    required this.ratio,
    required this.previewSize,
  });

  @override
  _CornerAdjustmentDialogState createState() => _CornerAdjustmentDialogState();
}

class _CornerAdjustmentDialogState extends State<CornerAdjustmentDialog> {
  late List<Offset> _corners;
  Size? _imageSize;
  bool _initialized = false;
  late Image _cachedImage;

  @override
  void initState() {
    super.initState();
    _corners = (widget.corners as List).map((corner) {
      List point = corner as List;
      return Offset(
        (point[0] as num).toDouble(),
        (point[1] as num).toDouble(),
      );
    }).toList();
    // Cache the image
    _cachedImage = Image.memory(
      base64Decode(widget.imageBase64),
      fit: BoxFit.contain,
      gaplessPlayback: true, // Prevents flashing during updates
    );
  }

  Size getActualImageDimensions(double containerWidth, double containerHeight) {
    double imageAspectRatio = widget.previewSize['width'] / widget.previewSize['height'];
    double containerAspectRatio = containerWidth / containerHeight;

    double actualWidth;
    double actualHeight;

    if (containerAspectRatio > imageAspectRatio) {
      actualHeight = containerHeight;
      actualWidth = containerHeight * imageAspectRatio;
    } else {
      actualWidth = containerWidth;
      actualHeight = containerWidth / imageAspectRatio;
    }

    return Size(actualWidth, actualHeight);
  }

  void _updateCorner(int index, Offset delta, BoxConstraints constraints) {
    if (_imageSize == null) return;

    setState(() {
      Size actualSize = getActualImageDimensions(constraints.maxWidth, constraints.maxHeight);
      double offsetX = (constraints.maxWidth - actualSize.width) / 2;
      double offsetY = (constraints.maxHeight - actualSize.height) / 2;

      Offset newPosition = _corners[index] + delta;

      // Constrain the corner within the actual image bounds
      _corners[index] = Offset(
        newPosition.dx.clamp(offsetX, offsetX + actualSize.width),
        newPosition.dy.clamp(offsetY, offsetY + actualSize.height),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Adjust Document Corners',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!_initialized) {
                  Size actualSize = getActualImageDimensions(
                      constraints.maxWidth,
                      constraints.maxHeight
                  );

                  double offsetX = (constraints.maxWidth - actualSize.width) / 2;
                  double offsetY = (constraints.maxHeight - actualSize.height) / 2;

                  _corners = _corners.map((corner) => Offset(
                    (corner.dx * actualSize.width / widget.previewSize['width']) + offsetX,
                    (corner.dy * actualSize.height / widget.previewSize['height']) + offsetY,
                  )).toList();

                  _initialized = true;
                }

                _imageSize = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Use cached image
                    _cachedImage,
                    CustomPaint(
                      painter: CornerLinesPainter(
                        corners: _corners,
                        constraints: constraints,
                      ),
                    ),
                    ..._corners.asMap().entries.map((entry) {
                      int index = entry.key;
                      Offset corner = entry.value;
                      return Positioned(
                        left: corner.dx - 15,
                        top: corner.dy - 15,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) => _updateCorner(index, details.delta, constraints),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final actualSize = getActualImageDimensions(
                        _imageSize!.width,
                        _imageSize!.height
                    );
                    final offsetX = (_imageSize!.width - actualSize.width) / 2;
                    final offsetY = (_imageSize!.height - actualSize.height) / 2;

                    final adjustedCorners = _corners.map((corner) {
                      double adjustedX = (corner.dx - offsetX) * (widget.previewSize['width'] / actualSize.width);
                      double adjustedY = (corner.dy - offsetY) * (widget.previewSize['height'] / actualSize.height);

                      return [
                        adjustedX / widget.ratio,
                        adjustedY / widget.ratio,
                      ];
                    }).toList();

                    Navigator.of(context).pop(adjustedCorners);
                  },
                  child: Text('Confirm'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CornerLinesPainter extends CustomPainter {
  final List<Offset> corners;
  final BoxConstraints constraints;

  CornerLinesPainter({
    required this.corners,
    required this.constraints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();

    // Draw semi-transparent overlay outside the selection
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    backgroundPath.addPath(path, Offset.zero);

    canvas.drawPath(
      backgroundPath,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0,
    );

    // Draw the selection border
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerLinesPainter oldDelegate) => true;
}