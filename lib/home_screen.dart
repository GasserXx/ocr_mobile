import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/tabs/doc_screen.dart';
import 'package:untitled17/tabs/scan_screen.dart';
import 'package:untitled17/tabs/records_screen.dart';
import 'package:untitled17/Login/login_screen.dart';
import 'package:untitled17/API/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ScanScreen(),
    const DocScreen(),
    const RecordsScreen(),
  ];

  final List<String> _titles = ['Scan', 'Doc', 'Records'];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextAppStyle.subTittel.copyWith(
              fontSize: 18.sp,
              color: AppColor.tittelText,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextAppStyle.subTittel.copyWith(
              color: AppColor.subText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextAppStyle.subTittel.copyWith(
                  color: AppColor.subText,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ApiService.logout(); // This will just clear the token
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                          (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error during logout: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Logout',
                style: TextAppStyle.subTittel.copyWith(
                  color: AppColor.primeColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.primeColor,
        title: Text(
          _titles[_currentIndex],
          style: TextAppStyle.subTittel.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppColor.primeColor,
          unselectedItemColor: AppColor.subText,
          selectedLabelStyle: TextAppStyle.subTittel.copyWith(
            fontSize: 12.sp,
          ),
          unselectedLabelStyle: TextAppStyle.subTittel.copyWith(
            fontSize: 12.sp,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner, size: 24.sp),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner, size: 24.sp),
              label: 'Doc',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 24.sp),
              label: 'Records',
            ),
          ],
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}