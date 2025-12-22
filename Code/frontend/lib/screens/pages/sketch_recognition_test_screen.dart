import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class SketchRecognitionTestScreen extends StatefulWidget {
  final String serverUrl;

  const SketchRecognitionTestScreen({
    Key? key,
    required this.serverUrl,
  }) : super(key: key);

  @override
  _SketchRecognitionTestScreenState createState() =>
      _SketchRecognitionTestScreenState();
}

class _SketchRecognitionTestScreenState
    extends State<SketchRecognitionTestScreen> {
  late GlobalKey<_DrawingCanvasState> _canvasKey;
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  String? _topPrediction;
  String _predictionMessage = 'Draw something to test!';

  @override
  void initState() {
    super.initState();
    _canvasKey = GlobalKey<_DrawingCanvasState>();
  }

  Future<void> _submitDrawing() async {
    if (_canvasKey.currentState == null) return;

    // Get the canvas image
    final imageBytes = await _canvasKey.currentState!.getCanvasImage();
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw something first!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _predictions = [];
      _topPrediction = null;
      _predictionMessage = 'Analyzing your drawing...';
    });

    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Build server URL - remove port and add 5000
      String baseUrl = widget.serverUrl
          .replaceFirst('ws://', 'http://')
          .replaceFirst('wss://', 'https://');
      
      // Remove existing port if present
      if (baseUrl.contains(':')) {
        baseUrl = baseUrl.substring(0, baseUrl.lastIndexOf(':'));
      }
      
      final predictionUrl = '$baseUrl:5000/predict';

      final response = await http.post(
        Uri.parse(predictionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': 'data:image/png;base64,$base64Image',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Server request timed out'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _predictions =
                List<Map<String, dynamic>>.from(data['predictions']);
            _topPrediction = data['top_prediction'];
            _predictionMessage =
                'I think you drew: ${_topPrediction ?? 'Unknown'}';
          });
        } else {
          setState(() {
            _predictionMessage =
                'Error: ${data['error'] ?? 'Unknown error'}';
          });
        }
      } else {
        setState(() {
          _predictionMessage =
              'Server error: ${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _predictionMessage =
            'Server request timed out. Make sure the Python server is running on port 5000.';
      });
    } catch (e) {
      setState(() {
        _predictionMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearCanvas() {
    _canvasKey.currentState?.clear();
    setState(() {
      _predictions = [];
      _topPrediction = null;
      _predictionMessage = 'Draw something to test!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Sketch Recognition Test',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              const Divider(color: Colors.white30),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Drawing Canvas
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white54,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DrawingCanvas(
                              key: _canvasKey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _clearCanvas,
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  disabledBackgroundColor:
                                      Colors.red.shade300,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _submitDrawing,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Predict'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  disabledBackgroundColor:
                                      Colors.green.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Loading indicator
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Analyzing your drawing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Prediction Results
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurpleAccent
                                      .withOpacity(0.2),
                                  Colors.purpleAccent.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.purpleAccent.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Top prediction
                                if (_topPrediction != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'My Best Guess:',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurpleAccent
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.deepPurpleAccent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          _topPrediction ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // All predictions
                                if (_predictions.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Top 5 Predictions:',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._predictions
                                          .map((pred) {
                                            final confidence =
                                                (pred['confidence']
                                                        as num)
                                                    .toDouble();
                                            final percentage =
                                                (confidence * 100)
                                                    .toStringAsFixed(1);
                                            return Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .only(
                                                bottom: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration:
                                                        BoxDecoration(
                                                      shape: BoxShape
                                                          .circle,
                                                      color: Colors
                                                          .deepPurpleAccent,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${pred['rank']}',
                                                        style:
                                                            const TextStyle(
                                                          color: Colors
                                                              .white,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 12,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      pred['class'],
                                                      style:
                                                          const TextStyle(
                                                        color: Colors
                                                            .white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: Colors
                                                          .deepPurpleAccent
                                                          .withOpacity(0.5),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(4),
                                                    ),
                                                    child: Text(
                                                      '$percentage%',
                                                      style:
                                                          const TextStyle(
                                                        color: Colors
                                                            .white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ],
                                  ),

                                // Message
                                if (_predictionMessage.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 16),
                                    child: Text(
                                      _predictionMessage,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(
                                          0.9,
                                        ),
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Server: ${widget.serverUrl.replaceFirst('ws://', 'http://')}:5000',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({Key? key}) : super(key: key);

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Offset?> _points = [];
  late CustomPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = DrawingPainter(_points);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        setState(() {
          _points.add(details.localPosition);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        setState(() {
          _points.add(null);
        });
      },
      child: CustomPaint(
        painter: DrawingPainter(_points),
        size: const Size(280, 280),
      ),
    );
  }

  void clear() {
    setState(() {
      _points.clear();
    });
  }

  Future<Uint8List?> getCanvasImage() async {
    if (_points.isEmpty) return null;

    try {
      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, 280, 280),
      );

      // Draw black background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 280, 280),
        Paint()..color = Colors.black,
      );

      // Draw the painting
      DrawingPainter(_points).paint(canvas, const Size(280, 280));

      // Get the image
      final picture = recorder.endRecording();
      final image = await picture.toImage(280, 280);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing canvas: $e');
      return null;
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw black background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Draw the points
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 8.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!, 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
