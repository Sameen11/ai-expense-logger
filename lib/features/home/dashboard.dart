import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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
  int _selectedIndex = 0; // Tracks the currently selected tab

  // List of the main "view" widgets
  final List<Widget> _screens = const [
    SnapView(),
    ExpensesView(),
    InsightsView(),
    SettingsView(),
  ];

  // List of icons to display in the navigation bar
  final List<IconData> _iconList = [
    Icons.camera_alt_outlined,
    Icons.home_outlined,
    Icons.insights_outlined,
    Icons.settings_outlined,
  ];

  // List of labels for the navigation bar
  final List<String> _labelList = [
    'Snap',
    'Expenses',
    'Insights',
    'Settings',
  ];

  // Callback for when a navigation item is selected
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // A slightly cleaner light grey
      // The body is the currently selected screen from our list
      body: _screens[_selectedIndex],
      // Use a standard BottomNavigationBar, wrapped in a
      // Container to add the top border line.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Add a border (line) to the top
          border: Border(
            top: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
        ),
        // --- FIX: Wrap with Theme to properly remove ripple effect ---
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            items: List.generate(_iconList.length, (index) {
              return BottomNavigationBarItem(
                // Use the 'icon' property for the unselected state
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0), // Add spacing
                  child: Icon(_iconList[index]),
                ),
                // Use the 'activeIcon' property for the selected state
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0), // Add spacing
                  child: Icon(
                    _iconList[index],
                    color: Colors.blue, // Explicitly set active color
                  ),
                ),
                label: _labelList[index],
              );
            }),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,

            // --- Styling to match your image ---
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed, // Shows all labels
            selectedItemColor: Colors.blue, // Active item color
            unselectedItemColor: Colors.grey[600], // Inactive item color

            // --- Remove ripple effect ---
            // splashColor: Colors.transparent, // <-- Removed from here
            // highlightColor: Colors.transparent, // <-- Removed from here

            // Control label styles explicitly
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500, // Make selected label slightly bolder
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),

            showSelectedLabels: true,
            showUnselectedLabels: true,

            elevation: 0, // Set elevation to 0
          ),
        ),
      ),
    );
  }
}
