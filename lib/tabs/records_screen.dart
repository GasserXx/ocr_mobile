import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/theme/color.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../models/receipt_process.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.primeColor,
        title: Text(
          'Records',
          style: TextAppStyle.subTittel.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ReceiptProcess>>(
        future: _dbHelper.getAllReceiptProcesses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading records',
                    style: TextAppStyle.subTittel.copyWith(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh the screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primeColor,
                    ),
                    child: Text(
                      'Retry',
                      style: TextAppStyle.subTittel.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final processes = snapshot.data ?? [];

          if (processes.isEmpty) {
            return Center(
              child: Text(
                'No records found',
                style: TextAppStyle.subTittel.copyWith(fontSize: 16.sp),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: ListView.separated(
              itemCount: processes.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final process = processes[index];
                return _buildRecordCard(process);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(ReceiptProcess process) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to detail view
          _showRecordDetails(process);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: process.imagePaths.isNotEmpty
                    ? Image.file(
                  File(process.imagePaths.first),
                  width: 60.w,
                  height: 60.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                )
                    : Container(
                  width: 60.w,
                  height: 60.w,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Type: ${process.receiptTypeId}',
                      style: TextAppStyle.subMainTittel.copyWith(
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Date: ${_formatDate(process.dateCreated)}',
                      style: TextAppStyle.subTittel.copyWith(
                        fontSize: 12.sp,
                        color: AppColor.subText,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${process.imagePaths.length} image(s)',
                      style: TextAppStyle.subTittel.copyWith(
                        fontSize: 12.sp,
                        color: AppColor.subText,
                      ),
                    ),
                  ],
                ),
              ),
              // Sync status
              Icon(
                process.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                color: process.isSynced ? Colors.green : Colors.grey,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _showRecordDetails(ReceiptProcess process) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Receipt Details',
                style: TextAppStyle.subMainTittel.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 16.h),
              // Images
              SizedBox(
                height: 120.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: process.imagePaths.length,
                  separatorBuilder: (context, index) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        File(process.imagePaths[index]),
                        width: 120.w,
                        height: 120.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120.w,
                            height: 120.h,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              // Details
              ListTile(
                title: Text(
                  'Receipt Type',
                  style: TextAppStyle.subTittel,
                ),
                subtitle: Text(
                  process.receiptTypeId,
                  style: TextAppStyle.subMainTittel,
                ),
              ),
              ListTile(
                title: Text(
                  'Date',
                  style: TextAppStyle.subTittel,
                ),
                subtitle: Text(
                  _formatDate(process.dateCreated),
                  style: TextAppStyle.subMainTittel,
                ),
              ),
              ListTile(
                title: Text(
                  'Status',
                  style: TextAppStyle.subTittel,
                ),
                subtitle: Text(
                  process.isSynced ? 'Synced' : 'Not Synced',
                  style: TextAppStyle.subMainTittel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}