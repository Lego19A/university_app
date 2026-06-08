import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
// -- Import the STUDENT navigation screen (existing, unchanged) --
// This is the screen shown after successful login + MFA for students
import 'features/navigation/main_navigation_screen.dart';
// -- Import the LECTURER navigation screen (new) --
// This is the screen shown after successful login + MFA for lecturers
import 'features/lecturer/lecturer_navigation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // -- Text controllers for email and password input fields --
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // -- Firebase Auth instance for email/password sign-in --
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -- Local Auth instance for biometric MFA (fingerprint/face) --
  final LocalAuthentication _localAuth = LocalAuthentication();

  // -- Loading flag: shows spinner instead of button while authenticating --
  bool _isLoading = false;

  // ============================================================
  // _login - Full authentication flow:
  //   1. Firebase email/password sign-in
  //   2. Biometric MFA verification
  //   3. Firestore role lookup
  //   4. Role-based navigation routing
  // ============================================================
  Future<void> _login() async {
    // -- Show loading indicator --
    setState(() => _isLoading = true);
   try {
    // -- Step 1: Firebase email/password authentication --
    UserCredential user = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    print("Firebase login success");

    if (user.user != null) {
  // -- Step 2: Biometric MFA verification --
  bool authenticated = false;

  try {
    if (kIsWeb) {
      // -- Bypass biometric on web, simply set authenticated to true --
      print("Bypassing biometrics for web environment.");
      authenticated = true;
    } else {
      // -- Check if the device supports biometric authentication --
      bool canCheck = await _localAuth.canCheckBiometrics;
      bool supported = await _localAuth.isDeviceSupported();

      print("canCheckBiometrics: $canCheck");
      print("isDeviceSupported: $supported");

    // -- Abort if biometrics are not supported on this device --
    if (!canCheck || !supported) {
      _showErrorDialog('Biometrics Not Supported', 'Biometric authentication is not supported on this device.');
      return;
    }

    // -- Check if at least one fingerprint/face is enrolled --
    final biometrics = await _localAuth.getAvailableBiometrics();
    print("Available biometrics: $biometrics");

    if (biometrics.isEmpty) {
      _showErrorDialog('No Fingerprint', 'No fingerprint is enrolled on this device.');
      return;
    }

    print("Triggering fingerprint...");

    // -- Prompt the user for biometric verification --
    authenticated = await _localAuth.authenticate(
    localizedReason: 'Scan fingerprint to continue',
    );

    print("Fingerprint result: $authenticated");
    } // End of !kIsWeb block

    if (authenticated) {
      // -- Step 3: Fetch user role from Firestore --
      // The 'users' collection must contain a document with the
      // user's UID, and that document must have a 'role' field
      // set to either 'student' or 'lecturer'.
      final uid = user.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // -- Determine the role from Firestore document --
      // Default to 'student' if the role field is missing or
      // the document doesn't exist, to preserve backward compatibility.
      String role = 'student'; // Safe default
      if (userDoc.exists && userDoc.data() != null) {
        role = (userDoc.data()!['role'] as String?) ?? 'student';
      }

      print("User role: $role");

      // -- Step 4: Enforce platform restrictions based on role --
      if (kIsWeb && role != 'lecturer') {
        await _auth.signOut();
        _showErrorDialog('Access Denied', 'Students must use the mobile app to log in.');
        setState(() => _isLoading = false);
        return;
      }

      if (!kIsWeb && role == 'lecturer') {
        await _auth.signOut();
        _showErrorDialog('Access Denied', 'Lecturers must use the web dashboard to log in.');
        setState(() => _isLoading = false);
        return;
      }

      // -- Step 5: Route to the correct navigation shell based on role --
      // pushReplacement removes the login page from the stack
      // so the user can't press back to return to login.
      if (role == 'lecturer') {
        // ---- LECTURER ROUTE ----
        // Navigate to the isolated lecturer interface
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LecturerNavigationScreen(),
          ),
        );
      } else {
        // ---- STUDENT ROUTE (default) ----
        // Navigate to the existing student interface
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ),
        );
      }
    } else {
      _showErrorDialog('Authentication Failed', 'Fingerprint authentication failed.');
    }

  } catch (e) {
    print("Fingerprint error: $e");
    _showErrorDialog('Biometric Error', 'An error occurred during biometric authentication.');
  }
} 
}on FirebaseAuthException catch (e) {
    print("Firebase error: ${e.code}");

    if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
      _showErrorDialog('Login Failed', 'Invalid email or password.');
    } else {
      _showErrorDialog('Login Error', 'An error occurred during login. Please try again.');
    }
  } catch (e) {
    print("General error: $e");
    _showErrorDialog('Error', 'Something went wrong.');
  }

  // -- Hide loading indicator --
  setState(() => _isLoading = false);
  
  }

  // ============================================================
  // _showTopSnackBar - Displays a SnackBar message at the top.
  // ============================================================
  void _showTopSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  // ============================================================
  // _showErrorDialog - Displays a dialog prompt box for errors.
  // ============================================================
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // -- Email input field --
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 10),
            // -- Password input field --
            TextField(
              controller: _passwordController,
              obscureText: true, // Hide password characters
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 20),
            // -- Login button (or spinner when loading) --
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text("Login"),
                  )
          ],
            ),
          ),
        ),
      ),
    );
  }
}
