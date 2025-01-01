// scan_types_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/API/api_service.dart';
import 'package:untitled17/API/receipt_type_model.dart';
import 'scan_result_screen.dart';

class ScanTypeScreen extends StatefulWidget {
  const ScanTypeScreen({Key? key}) : super(key: key);

  @override
  State<ScanTypeScreen> createState() => _ScanTypeScreenState();
}

class _ScanTypeScreenState extends State<ScanTypeScreen> {
  List<ReceiptType> _receiptTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReceiptTypes();
  }

  Future<void> _fetchReceiptTypes() async {
    try {
      final types = await ApiService.getReceiptTypes();
      setState(() {
        _receiptTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getIconForType(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'qr':
        return Icons.qr_code_scanner;
      case 'document':
        return Icons.document_scanner;
      default:
        return Icons.document_scanner;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.primeColor,
        title: Text(
          'Select Scan Type',
          style: TextAppStyle.subTittel.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColor.primeColor,
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading receipt types',
              style: TextAppStyle.subTittel.copyWith(
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: _fetchReceiptTypes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primeColor,
              ),
              child: Text(
                'Retry',
                style: TextAppStyle.subTittel.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: EdgeInsets.all(20.w),
        child: ListView.separated(
          itemCount: _receiptTypes.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final type = _receiptTypes[index];
            return _buildScanTypeCard(
              context,
              type.name,
              _getIconForType(type.name),
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanResultScreen(
                      scanType: type.name,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanTypeCard(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColor.primeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  size: 24.sp,
                  color: AppColor.primeColor,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextAppStyle.subMainTittel.copyWith(
                    fontSize: 16.sp,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppColor.subText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}