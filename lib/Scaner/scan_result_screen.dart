import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/Scaner/corner_editor.dart';
import 'package:untitled17/API/api_service.dart';
import 'package:untitled17/API/token_service.dart';
import 'package:untitled17/database/database_helper.dart';
import 'package:untitled17/models/receipt_process.dart';

class ScanResultScreen extends StatefulWidget {
  final String scanType;

  const ScanResultScreen({
    Key? key,
    required this.scanType,
  }) : super(key: key)
  ;
  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  static const platform = MethodChannel('docscanner_channel');
  File? _imageFile;
  File? _croppedImage;
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _currentCroppedPath;
  List<File> _croppedImages = [];

  @override
  void initState() {
    super.initState();
    print('ScanResultScreen initialized with scanType: ${widget.scanType}');
  }

  @override
  void dispose() {
    _cleanupFiles();
    super.dispose();
  }

  void _cleanupFiles() {
    if (_croppedImage?.existsSync() == true) {
      try {
        _croppedImage!.deleteSync();
      } catch (e) {
        print('Error disposing cropped image: $e');
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_croppedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> base64Images = [];
      for (File image in _croppedImages) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        base64Images.add(base64String);

        print('File details:');
        print('Path: ${image.path}');
        print('Size: ${bytes.length} bytes');
        print('Base64 length: ${base64String.length}');
      }

      print('Uploading with receipt type ID: ${widget.scanType}');
      print('Number of images: ${base64Images.length}');

      final success = await ApiService.uploadReceiptImages(
        widget.scanType,
        base64Images,
      );

      if (success) {
        final process = ReceiptProcess(
          receiptTypeId: widget.scanType,
          imagePaths: _croppedImages.map((file) => file.path).toList(),
          dateCreated: DateTime.now(),
          isSynced: true,
        );

        final dbHelper = DatabaseHelper();
        await dbHelper.insertReceiptProcess(process);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
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
          _croppedImage = null;
          _currentCroppedPath = null;
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

  Future<void> _detectAndCropDocument() async {
    if (_imageFile == null) return;

    setState(() {
      isProcessing = true;
      _errorMessage = null;
      _croppedImage = null;
      _currentCroppedPath = null;
    });

    try {
      final List<int> imageBytes = await _imageFile!.readAsBytes();
      final ByteData imageData = ByteData(imageBytes.length);
      for (var i = 0; i < imageBytes.length; i++) {
        imageData.setUint8(i, imageBytes[i]);
      }

      print('Processing image of size: ${imageData.lengthInBytes} bytes');

      final String initialResult = await platform.invokeMethod('detectDocument', {
        'imageBytes': imageData.buffer.asUint8List(),
      });

      print('Initial detection completed');

      final Map<String, dynamic> detectResult = json.decode(initialResult);

      if (detectResult.containsKey('error')) {
        throw Exception(detectResult['error']);
      }

      final adjustedCorners = await showDialog<List<List<double>>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CornerAdjustmentDialog(
          imageBase64: detectResult['image'],
          corners: List<List<double>>.from(detectResult['corners'].map(
                (corner) => List<double>.from(corner),
          )),
          ratio: detectResult['ratio'].toDouble(),
          previewSize: detectResult['preview_size'],
        ),
      );

      if (adjustedCorners != null) {
        print('Processing with adjusted corners');

        final String finalResult = await platform.invokeMethod('cropDocument', {
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
            _currentCroppedPath = newPath;
            _croppedImage = newFile;
            _errorMessage = null;
          });

          await processedFile.delete();

          print('Crop completed successfully: ${_croppedImage!.path}');
        } else {
          throw Exception('Processed file not found');
        }
      }
    } catch (e) {
      print('Error during detection and cropping: $e');
      setState(() {
        _errorMessage = e.toString();
        _croppedImage = null;
        _currentCroppedPath = null;
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
          '${widget.scanType} Detector',
          style: TextAppStyle.subTittel.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_croppedImages.isNotEmpty)
            TextButton(
              onPressed: _isUploading ? null : _uploadImages,
              child: _isUploading
                  ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Upload',
                style: TextAppStyle.subTittel.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker section
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

            // Detect and crop button
            ElevatedButton(
              onPressed: _imageFile != null && !isProcessing ? _detectAndCropDocument : null,
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
                _imageFile != null ? 'Detect and Crop' : 'Select an image first',
                style: TextAppStyle.subTittel.copyWith(
                  color: Colors.white,
                ),
              ),
            ),

            // List of cropped images
            if (_croppedImages.isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                'Scanned Images (${_croppedImages.length}):',
                style: TextAppStyle.subTittel.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 120.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _croppedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Stack(
                        children: [
                          Container(
                            width: 120.w,
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
                                _croppedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _croppedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Current cropped image
            if (_croppedImage != null) ...[
              SizedBox(height: 24.h),
              Text(
                'Current Scan:',
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
                    _croppedImage!,
                    fit: BoxFit.contain,
                    key: ValueKey(_currentCroppedPath),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _croppedImages.add(_croppedImage!);
                    _imageFile = null;
                    _croppedImage = null;
                    _currentCroppedPath = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primeColor,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Add Image',
                  style: TextAppStyle.subTittel.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}