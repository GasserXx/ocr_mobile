import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/Scaner/corner_editor.dart';

class DocScreen extends StatefulWidget {
  const DocScreen({Key? key}) : super(key: key);

  @override
  State<DocScreen> createState() => _DocScreenState();
}

class _DocScreenState extends State<DocScreen> {
  static const platform = MethodChannel('docscanner_channel');
  File? _imageFile;
  File? _scannedImage;
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;
  String? _errorMessage;
  String? _currentScannedPath;

  @override
  void dispose() {
    _cleanupFiles();
    super.dispose();
  }

  void _cleanupFiles() {
    if (_scannedImage?.existsSync() == true) {
      try {
        _scannedImage!.deleteSync();
      } catch (e) {
        print('Error disposing scanned image: $e');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        _cleanupFiles();

        setState(() {
          _imageFile = File(pickedFile.path);
          _scannedImage = null;
          _currentScannedPath = null;
          _errorMessage = null;
        });

        print('New image picked: ${_imageFile!.path}');
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveImage() async {
    try {
      // Request appropriate permissions based on Android version
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // For Android 13 and above
          var photos = await Permission.photos.status;
          if (!photos.isGranted) {
            photos = await Permission.photos.request();
            if (!photos.isGranted) {
              throw Exception('Photos permission denied');
            }
          }
        } else {
          // For Android 12 and below
          var storage = await Permission.storage.status;
          if (!storage.isGranted) {
            storage = await Permission.storage.request();
            if (!storage.isGranted) {
              throw Exception('Storage permission denied');
            }
          }
        }
      }

      if (_scannedImage != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColor.primeColor,
                    ),
                    SizedBox(height: 16),
                    Text('Saving image...'),
                  ],
                ),
              ),
            );
          },
        );

        // Save image using platform channel
        final bool success = await platform.invokeMethod('saveImageToGallery', {
          'sourcePath': _scannedImage!.path,
        });

        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Image saved to gallery successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          throw Exception('Failed to save image');
        }
      }
    } catch (e) {
      // Close loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to save image: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _scanDocument() async {
    if (_imageFile == null) return;

    setState(() {
      isProcessing = true;
      _errorMessage = null;
      _scannedImage = null;
      _currentScannedPath = null;
    });

    try {
      final List<int> imageBytes = await _imageFile!.readAsBytes();
      final ByteData imageData = ByteData(imageBytes.length);
      for (var i = 0; i < imageBytes.length; i++) {
        imageData.setUint8(i, imageBytes[i]);
      }

      print('Processing image of size: ${imageData.lengthInBytes} bytes');

      final String initialResult = await platform.invokeMethod('scanDocument', {
        'imageBytes': imageData.buffer.asUint8List(),
      });

      print('Initial scan completed');

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
        print('Processing with adjusted corners');

        final String finalResult = await platform.invokeMethod('processWithCorners', {
          'imageBytes': imageData.buffer.asUint8List(),
          'corners': adjustedCorners,
        });

        if (finalResult.startsWith('Error:')) {
          throw Exception(finalResult.substring(7));
        }

        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String newPath = finalResult.replaceAll(
          RegExp(r'\.([^\.]+)$'),
          '_$timestamp.\$1',
        );

        final File processedFile = File(finalResult);
        if (processedFile.existsSync()) {
          final File newFile = await processedFile.copy(newPath);

          setState(() {
            _currentScannedPath = newPath;
            _scannedImage = newFile;
            _errorMessage = null;
          });

          await processedFile.delete();

          print('Scan completed successfully: ${_scannedImage!.path}');
        } else {
          throw Exception('Processed file not found');
        }
      }

    } catch (e) {
      print('Error during scanning: $e');
      setState(() {
        _errorMessage = e.toString();
        _scannedImage = null;
        _currentScannedPath = null;
      });
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        isProcessing = false;
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
        backgroundColor: AppColor.primeColor,
        title: Text(
          'Document Scanner',
          style: TextAppStyle.subTittel.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: SizedBox(
                height: 200.h,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: Radius.circular(12.r),
                  color: AppColor.primeColor,
                  strokeWidth: 1,
                  dashPattern: const [8, 4],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      children: [
                        if (_imageFile != null)
                          Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            key: ValueKey(_imageFile!.path),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40.sp,
                                  color: AppColor.primeColor,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Select Image',
                                  style: TextAppStyle.subTittel.copyWith(
                                    color: AppColor.primeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_imageFile != null)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.change_circle, color: Colors.white),
                                onPressed: _showImageSourceDialog,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            ElevatedButton(
              onPressed: _imageFile != null && !isProcessing ? _scanDocument : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primeColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: isProcessing
                  ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _imageFile != null ? 'Scan Image' : 'Select an image first',
                style: TextAppStyle.subTittel.copyWith(
                  color: Colors.white,
                ),
              ),
            ),

            if (_scannedImage != null) ...[
              SizedBox(height: 24.h),
              Text(
                'Scanned Result:',
                style: TextAppStyle.subTittel.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColor.primeColor,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    _scannedImage!,
                    fit: BoxFit.contain,
                    key: ValueKey(_currentScannedPath),
                    cacheWidth: null,
                    cacheHeight: null,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       Navigator.pop(context, _scannedImage);
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppColor.primeColor,
                  //       padding: EdgeInsets.symmetric(vertical: 12.h),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8.r),
                  //       ),
                  //     ),
                  //     child: Text(
                  //       'Confirm',
                  //       style: TextAppStyle.subTittel.copyWith(
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primeColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Save to Gallery',
                        style: TextAppStyle.subTittel.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}