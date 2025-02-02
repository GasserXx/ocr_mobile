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
        elevation: 0,
        title: Text(
          'Records',
          style: TextAppStyle.subTittel.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColor.primeColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: FutureBuilder<List<ReceiptProcess>>(
          future: _dbHelper.getAllReceiptProcesses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final processes = snapshot.data ?? [];

            if (processes.isEmpty) {
              return _buildEmptyState();
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: processes.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final process = processes[index];
                  return _buildRecordCard(process);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80.sp,
            color: AppColor.primeColor.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Records Found',
            style: TextAppStyle.subTittel.copyWith(
              fontSize: 18.sp,
              color: AppColor.primeColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start by adding some receipts',
            style: TextAppStyle.subTittel.copyWith(
              fontSize: 14.sp,
              color: AppColor.subText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60.sp,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Records',
            style: TextAppStyle.subTittel.copyWith(
              color: Colors.red,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primeColor,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(ReceiptProcess process) {
    return Card(
      elevation: 2,
      shadowColor: AppColor.primeColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(process),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColor.primeColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildThumbnail(process),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Receipt #${process.receiptTypeId}',
                            style: TextAppStyle.subMainTittel.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _buildSyncStatus(process.isSynced),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14.sp,
                          color: AppColor.subText,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            _formatDate(process.dateCreated),
                            style: TextAppStyle.subTittel.copyWith(
                              fontSize: 12.sp,
                              color: AppColor.subText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: 14.sp,
                          color: AppColor.subText,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '${process.imagePaths.length} image(s)',
                            style: TextAppStyle.subTittel.copyWith(
                              fontSize: 12.sp,
                              color: AppColor.subText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus(bool isSynced) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isSynced ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done : Icons.cloud_upload,
            color: isSynced ? Colors.green : Colors.grey,
            size: 12.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            isSynced ? 'Synced' : 'Pending',
            style: TextAppStyle.subTittel.copyWith(
              fontSize: 10.sp,
              color: isSynced ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

// For the details bottom sheet, update the _buildDetailItem method:
  Widget _buildDetailItem(String title, String value, IconData icon, [Color? iconColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: iconColor ?? AppColor.subText,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextAppStyle.subTittel.copyWith(
                    fontSize: 14.sp,
                    color: AppColor.subText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextAppStyle.subMainTittel.copyWith(
                    fontSize: 16.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(ReceiptProcess process) {
    return Container(
      width: 70.w,
      height: 70.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColor.primeColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: process.imagePaths.isNotEmpty
            ? Image.file(
          File(process.imagePaths.first),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(),
        )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.receipt,
        color: Colors.grey[400],
        size: 30.sp,
      ),
    );
  }


  void _showRecordDetails(ReceiptProcess process) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text(
                'Receipt Details',
                style: TextAppStyle.subMainTittel.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 24.h),
              // Images
              SizedBox(
                height: 150.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: process.imagePaths.length,
                  separatorBuilder: (context, index) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColor.primeColor.withOpacity(0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          File(process.imagePaths[index]),
                          width: 150.w,
                          height: 150.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
              // Details
              _buildDetailItem(
                'Receipt ID',
                process.receiptTypeId,
                Icons.receipt,
              ),
              _buildDetailItem(
                'Date',
                _formatDate(process.dateCreated),
                Icons.calendar_today,
              ),
              _buildDetailItem(
                'Status',
                process.isSynced ? 'Synced' : 'Not Synced',
                process.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                process.isSynced ? Colors.green : Colors.grey,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primeColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextAppStyle.subTittel.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}