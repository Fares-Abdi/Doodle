import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doodle/widgets/simple_drawing_canvas.dart';
import '../../widgets/custom_loading_screen.dart';

class SketchPredictionPage extends StatefulWidget {
  const SketchPredictionPage({Key? key}) : super(key: key);

  @override
  State<SketchPredictionPage> createState() => _SketchPredictionPageState();
}

class _SketchPredictionPageState extends State<SketchPredictionPage> {
  final GlobalKey<AdvancedDrawingCanvasState> _canvasKey = GlobalKey();
  String _prediction = "";
  bool _isLoading = false;

  Future<void> _getPrediction() async {
    setState(() {
      _isLoading = true;
      _prediction = "";
    });

    try {
      // Get the canvas image
      final renderObject =
          _canvasKey.currentContext!.findRenderObject() as RenderBox;
      final boundary =
          renderObject.debugNeedsLayout ? null : renderObject.paintBounds;

      if (boundary == null) {
        throw Exception('Unable to get canvas boundary');
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint the canvas content
      _canvasKey.currentState!.drawingPoints.forEach((point) {
        if (point != null) {
          canvas.drawPoints(ui.PointMode.points, [point.offset], point.paint);
        }
      });

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        boundary.width.toInt(),
        boundary.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final base64Image = base64Encode(bytes);

      // Send to API
      final response = await http.post(
        Uri.parse('http://10.80.10.14:8000/predict/sketch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sketch_data': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final predictions = result['data']['predictions'] as List;
        if (predictions.isNotEmpty) {
          final topPrediction = predictions[0];
          setState(() {
            _prediction = 'Class ${topPrediction['class_index']} (${(topPrediction['probability'] * 100).toStringAsFixed(2)}%)';
          });
        }
      } else {
        throw Exception('Failed to get prediction');
      }
    } catch (e) {
      setState(() {
        _prediction = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick, Draw!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Play'),
                  content: const Text(
                      'Draw something and click "Predict" to see if the AI can guess what it is!'),
                  actions: [
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: SimpleDrawingCanvas(
                  key: _canvasKey,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                if (_isLoading)
                  CompactLoadingSpinner(
                    color: Colors.deepPurple,
                    size: 32,
                  )
                else if (_prediction.isNotEmpty)
                  Text(
                    'Prediction: $_prediction',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getPrediction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text('Predict'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
