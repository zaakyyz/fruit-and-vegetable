import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIService {
  Interpreter? _interpreter;
  List<String>? _labels;
  List<String>? _displayLabels;
  Map<String, dynamic>? _descriptions;

  Future<void> loadDescriptions() async {
    String data = await rootBundle.loadString('assets/data/descriptions.json');
    _descriptions = json.decode(data);
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_fruits_vegetables.tflite');
      
      // Load labels
      String labelsData = await rootBundle.loadString('assets/labels/fruit_vegetable_labels.txt');
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      String displayLabelsData = await rootBundle.loadString('assets/labels/fruit_vegetable_display_labels.txt');
      _displayLabels = displayLabelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      await loadDescriptions();
      
      print('Model loaded successfully');
      print('Labels count: ${_labels?.length}');
      print('Display labels count: ${_displayLabels?.length}');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<Map<String, dynamic>?> predictImage(File imageFile) async {
    if (_interpreter == null || _labels == null || _displayLabels == null) {
      await loadModel();
    }

    try {
      // Read and preprocess image
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) return null;

      // Resize to 224x224 (MobileNetV2 input size)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to input tensor with MobileNetV2 preprocessing
      var input = _imageToByteListFloat32(resizedImage);

      // Prepare output tensor for 36 classes
      var output = List.filled(1 * 36, 0.0).reshape([1, 36]);

      // Run inference
      _interpreter!.run(input, output);

      // Get results (output already has softmax, so values are probabilities)
      List<double> predictions = output[0].cast<double>();
      
      // Find best prediction
      double maxConfidence = 0.0;
      int maxIndex = 0;
      
      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          maxIndex = i;
        }
      }

      // Ensure index is within bounds
      if (maxIndex >= _labels!.length || maxIndex >= _displayLabels!.length) {
        print('Index out of bounds: $maxIndex');
        return null;
      }

      print('Predictions: $predictions');
      print('Max index: $maxIndex, confidence: $maxConfidence');

      return {
        'label': _labels![maxIndex],
        'displayLabel': _displayLabels![maxIndex],
        'confidence': maxConfidence,
        'index': maxIndex,
      };
    } catch (e) {
      print('Error during prediction: $e');
      return null;
    }
  }

  // MobileNetV2 preprocessing: normalize to [-1, 1]
  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    List<List<List<double>>> imageMatrix = [];
    for (int i = 0; i < image.height; i++) {
      List<List<double>> row = [];
      for (int j = 0; j < image.width; j++) {
        final pixel = image.getPixel(j, i);
        row.add([
          (pixel.r / 255.0) * 2.0 - 1.0,
          (pixel.g / 255.0) * 2.0 - 1.0,
          (pixel.b / 255.0) * 2.0 - 1.0,
        ]);
      }
      imageMatrix.add(row);
    }
    // Tambahkan batch dimension
    return [imageMatrix];
  }

  String? getDescription(String label) {
    return _descriptions?[label];
  }

  void dispose() {
    _interpreter?.close();
  }
}