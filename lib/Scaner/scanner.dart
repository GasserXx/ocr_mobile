import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:untitled17/Scaner/corner_editor.dart';



class scan_screen extends StatefulWidget {
  @override
  _scan_screenState createState() => _scan_screenState();
}


class _scan_screenState extends State<scan_screen> {
  static const platform = MethodChannel('docscanner_channel');
  String _scannedImagePath = 'No image scanned yet';
  String? _processedImagePath;
  bool _isProcessing = false;
  File? _processedImage;
  String? _errorMessage; // New error message state

  Future<void> scanDocument() async {
    // Reset state at the start of each scan
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _scannedImagePath = 'Processing...';
      _processedImagePath = null;  // Reset processed image path
      _processedImage = null;      // Reset processed image
    });

    try {
      final ByteData data = await rootBundle.load('assets/chart.JPG');
      print('Loading image from assets/chart.JPG');
      print('Image size: ${data.lengthInBytes} bytes');

      final Uint8List bytes = data.buffer.asUint8List();

      // Clear any existing processed files
      if (_processedImage?.existsSync() == true) {
        await _processedImage!.delete();
      }

      final String initialResult = await platform.invokeMethod('scanDocument', {
        'imageBytes': bytes,
      });

      print('Initial scan result: $initialResult');

      final Map<String, dynamic> scanResult = json.decode(initialResult);

      if (scanResult.containsKey('error')) {
        throw Exception(scanResult['error']);
      }

      final adjustedCorners = await showDialog<List<List<double>>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CornerAdjustmentDialog(
          imageBase64: scanResult['image'],
          corners: List<List<double>>.from(scanResult['corners'].map(
                (corner) => List<double>.from(corner),
          )),
          ratio: scanResult['ratio'].toDouble(),
          previewSize: scanResult['preview_size'],
        ),
      );

      if (adjustedCorners != null) {
        // Delete previous processed file if it exists
        final previousFile = File(_scannedImagePath);
        if (previousFile.existsSync()) {
          await previousFile.delete();
        }

        final String finalResult = await platform.invokeMethod('processWithCorners', {
          'imageBytes': bytes,
          'corners': adjustedCorners,
        });

        if (finalResult.startsWith('Error:')) {
          throw Exception(finalResult.substring(7));
        }

        // Verify the new file exists
        final newFile = File(finalResult);
        if (!newFile.existsSync()) {
          throw Exception('Processed file not found');
        }

        setState(() {
          _scannedImagePath = finalResult;
          _processedImagePath = finalResult;
          _processedImage = newFile;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _scannedImagePath = 'Scanning cancelled';
          _errorMessage = null;
        });
      }

    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _scannedImagePath = 'Error occurred';
        _processedImagePath = null;
        _processedImage = null;
      });
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Scanner'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Original Image
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Original Image:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Image.asset(
                      'assets/chart.JPG',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading original image: $error');
                        return Center(
                          child: Text('Error loading original image'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Processed Image
            if (_processedImagePath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Processed Image:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _processedImage != null
                          ? Image.file(
                        _processedImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading processed image: $error');
                          return Center(
                            child: Text('Error loading processed image'),
                          );
                        },
                      )
                          : Center(
                        child: Text('No processed image'),
                      ),
                    ),
                  ],
                ),
              ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Status Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _scannedImagePath,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            // Scan Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : scanDocument,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: _isProcessing ? Colors.grey : Colors.blue,
                ),
                child: _isProcessing
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Processing...'),
                  ],
                )
                    : Text('Scan Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}