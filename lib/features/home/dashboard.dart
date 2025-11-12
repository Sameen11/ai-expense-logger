import 'package:ai_expense_logger/common/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../expenses/expenses_view.dart';
import '../insights/insights_view.dart';
import '../settings/settings_view.dart';
import '../snap/snap_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SnapView(),
    ExpensesView(),
    InsightsView(),
    SettingsView(),
  ];

  final List<IconData> _iconList = [
    Icons.camera_alt_outlined,
    Icons.home_outlined,
    Icons.insights_outlined,
    Icons.settings_outlined,
  ];

  final List<String> _labelList = [
    'Snap',
    'Expenses',
    'Insights',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: GNav(
            gap: 8,
            activeColor: Colors.white,
            color: Colors.grey[600],
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: AppColors.primaryColor,
            backgroundColor: Colors.white,
            selectedIndex: _selectedIndex,
            onTabChange: (index) => setState(() => _selectedIndex = index),
            tabs: List.generate(_iconList.length, (index) {
              return GButton(
                icon: _iconList[index],
                text: _labelList[index],
              );
            }),
          ),
        ),
      ),
    );
  }
}
