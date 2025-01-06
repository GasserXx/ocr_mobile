import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/API/api_service.dart';
import 'package:untitled17/models/receipt_type_model.dart';
import 'package:untitled17/Login/login_screen.dart';
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
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final types = await ApiService.getReceiptTypes();
      setState(() {
        _receiptTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildErrorWidget() {
    final bool isUnauthorized = _error?.contains('Session expired') == true ||
        _error?.contains('unauthorized') == true ||
        _error?.contains('401') == true;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isUnauthorized
                  ? 'Please login to access this feature'
                  : _error!,
              textAlign: TextAlign.center,
              style: TextAppStyle.subTittel.copyWith(
                color: Colors.red,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: isUnauthorized ? _navigateToLogin : _fetchReceiptTypes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primeColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                isUnauthorized ? 'Go to Login' : 'Retry',
                style: TextAppStyle.subTittel.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_receiptTypes.isEmpty) {
      return Center(
        child: Text(
          'No receipt types available',
          style: TextAppStyle.subTittel.copyWith(
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReceiptTypes,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: ListView.separated(
          itemCount: _receiptTypes.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final receiptType = _receiptTypes[index];
            return _buildScanTypeCard(
              context,
              receiptType.name,
              _getIconForIndex(index),
                  () {
                    print('Selected Receipt Type Debug:');
                    print('receiptTypeId: ${receiptType.receiptTypeId}');
                    print('name: ${receiptType.name}');

                    if (receiptType.receiptTypeId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid receipt type ID'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanResultScreen(
                      scanType: receiptType.receiptTypeId,
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

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.qr_code_scanner;
      case 1:
        return Icons.document_scanner;
      case 2:
        return Icons.barcode_reader;
      default:
        return Icons.document_scanner;
    }
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