import 'package:deped_reading_app_laravel/pages/auth%20pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'student_dashboard_page.dart';
import 'my class pages/my_class_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import '../../widgets/navigation/page_transition.dart';
import 'student_profile_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  int _currentIndex = 0; // Tracks selected tab index
  final PageController _pageController =
      PageController(); // Controls page transitions

  // List of main pages for navigation
  final List<Widget> _pages = [StudentDashboardPage(), MyClassPage()];

  // Handles tab selection and animates to the selected page
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300), // Animation duration
      curve: Curves.easeInOut, // Animation curve
    );
  }

  // Logout logic using API and SharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await ApiService.logout(token);

    if (response.statusCode == 200) {
// Only remove token and user-related data, not all preferences
      await prefs.remove('token');
      await prefs.remove('student_name');
      await prefs.remove('student_email');
      await prefs.remove('student_id');
      await prefs.remove('students_data');
      // ...add/remove other student-specific keys as needed...
      // Show loading dialog before navigating
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  "Logging out...",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: LandingPage()),
          (route) => false,
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout Failed'),
          content: const Text('Unable to logout. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Shows logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _LogoutDialog(
        onStay: () => Navigator.pop(context), // Close dialog
        onLogout: logout, // Use the logout function above
      ),
    );
  }

  // Builds the AppBar with dynamic title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      // Title changes based on selected tab
      title: Text(
        _currentIndex == 0 ? "Student Dashboard" : "Tasks/Activities",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        // Profile popup menu with logout option
        _ProfilePopupMenu(onLogout: _showLogoutDialog),
        // Placeholder for additional actions
        IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        // Updates current index when page is changed via swipe
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      // Bottom navigation bar for switching between pages
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Handle tab selection
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "My Class"),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

// Popup menu for profile and logout actions
class _ProfilePopupMenu extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfilePopupMenu({required this.onLogout});

  Future<String> _getStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_name') ?? "Student";
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      // Profile avatar as menu icon
      icon: FutureBuilder<String>(
        future: _getStudentName(),
        builder: (context, snapshot) {
          final studentName = snapshot.data ?? "Student";
          final firstLetter = studentName.isNotEmpty ? studentName[0].toUpperCase() : "S";
          return CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromARGB(255, 191, 8, 8),
            child: Text(
              firstLetter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          );
        },
      ),
      tooltip: "Student Profile",
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        } else if (value == 'profile') {
          // Show the StudentProfilePage as a modal bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.85,
              child: StudentProfilePage(),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        // Profile info section in popup
        PopupMenuItem(
          value: 'profile',
          child: SizedBox(
            height: 160, // Adjusted height for better spacing
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<String>(
                  future: _getStudentName(),
                  builder: (context, snapshot) {
                    final studentName = snapshot.data ?? "Student";
                    final firstLetter = studentName.isNotEmpty ? studentName[0].toUpperCase() : "S";
                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color.fromARGB(255, 191, 8, 8),
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _getStudentName(),
                  builder: (context, snapshot) {
                    final studentName = snapshot.data ?? "Student";
                    return Text(
                      studentName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    );
                  },
                ),
                SizedBox(height: 4),
                Text(
                  'Student',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey, fontSize: 14),
                ),
                Divider(
                  height: 20,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
        // Logout option in popup
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Dialog for logout confirmation
class _LogoutDialog extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onLogout;
  const _LogoutDialog({required this.onStay, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          // Logout icon at top of dialog
          Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.primary,
            size: 50,
          ),
          SizedBox(height: 8),
          // Dialog title
          Text(
            "Are you leaving?",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      // Dialog message
      content: Text(
        "We hope to see you again soon! Are you sure you want to log out?",
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.black87),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Stay button closes dialog
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onStay,
          child: Text("Stay", style: TextStyle(color: Colors.white)),
        ),
        // Logout button triggers logout callback
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onLogout,
          child: Text("Log Out", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
