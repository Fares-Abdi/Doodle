import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doodle/localization/app_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false; // Declare loading state

  /// Function to generate and retrieve the device token for push notifications.
  Future<String?> generateDeviceToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission for notifications (only needed for iOS and macOS)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notification permissions denied');
        return null;
      }

      // Get the device token
      final String? token = await messaging.getToken();

      if (token != null) {
        debugPrint('Device token generated: $token');
        return token;
      } else {
        debugPrint('Failed to generate device token');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating device token: $e');
      return null;
    }
  }

  Future<void> saveDeviceTokenToFirestore(String userId) async {
    try {
      final String? token = await generateDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'deviceToken': token,
        });
        debugPrint('Device token saved to Firestore: $token');
      } else {
        debugPrint('Device token generation failed');
      }
    } catch (e) {
      debugPrint('Error saving device token to Firestore: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose(); // Dispose controllers to free resources
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false; // Loading state variable

  Widget _buildGoogleSignInButton() {
    final localizations = AppLocalizations.of(context)!;
    final buttonText = localizations.googleSignIn;

    return ElevatedButton(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 6,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
                Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        try {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          final User? user = userCredential.user;

          if (user != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            Map<String, dynamic> userData = {
              'uid': user.uid,
              'email': user.email ?? 'No Email',
              'lastSignIn': DateTime.now(),
              'isConnected': true,
            };

            if (!userDoc.exists || userDoc.data()?['name'] == null) {
              userData['name'] = user.displayName ?? 'No Name';
            }

            if (!userDoc.exists || userDoc.data()?['photoURL'] == null) {
              userData['photoURL'] = user.photoURL ?? '';
            }

            if (!userDoc.exists) {
              userData['createdAt'] = DateTime.now();
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set(userData, SetOptions(merge: true));

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            Navigator.of(context).pop();

            await saveDeviceTokenToFirestore(user.uid);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);

            // Always navigate to profile screen
            Navigator.of(context).pushReplacementNamed('/lobby');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign-In failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account exists with different credentials.'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication error: ${e.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In was canceled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during sign-in: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Updated Background Container
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black, // Added to prevent any transparent edges
            child: Image.asset(
              'assets/images/genback.png',
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // Add extra space at the top
                    Center(
                      child: GestureDetector(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(left: 40.0),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 8),
                                    blurRadius: 200,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/onboarding3_b.png',
                                height: 220,
                                width: 220,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.loginTitle, // Localized title
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30), // Adjust spacing
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildTextField(
                              localizations.email, false, _emailController),
                          _buildTextField(localizations.password, true,
                              _passwordController),
                          const SizedBox(
                              height: 25), // Adjust spacing before button
                          _buildLoginButton(
                              context, "Sign in"), // Changed button text
                          const SizedBox(height: 20),
                          _buildGoogleSignInButton(), // Add Google Sign-In Button
                          _buildSignupPrompt(
                              context,
                              localizations
                                  .createAccount), // Localized sign-up prompt
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, bool obscureText, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), // Add margin for spacing
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, String buttonText) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A5EDE).withOpacity(0.4),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => handleLogin(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A5EDE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> handleLogin(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Validate email format using a simple regex pattern
      final emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
      final emailRegex = RegExp(emailPattern);

      if (email.isNotEmpty && password.isNotEmpty) {
        if (!emailRegex.hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.invalidEmailFormat),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final User? user = userCredential.user;

        if (user != null) {
          try {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            // Hide loading indicator
            Navigator.of(context).pop();

            // Update user status in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'lastSignIn': DateTime.now(),
              'isConnected': true,
              'isEmailVerified': true,
            }, SetOptions(merge: true));

            await saveDeviceTokenToFirestore(user.uid);

            // Set logged in state
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);

            // Always navigate to profile screen
            Navigator.of(context).pushReplacementNamed('/lobby');
          } catch (e) {
            debugPrint('Error during data initialization: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error initializing app data. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.noUserFound),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.enterBothEmailAndPassword),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      handleFirebaseAuthError(context, error);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Updated error handler to include verification-related errors
  void handleFirebaseAuthError(BuildContext context, Object error) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    if (error is FirebaseAuthException) {
      String errorMessage;
      switch (error.code) {
        case 'user-not-found':
          errorMessage = localizations.noUserFoundForEmail;
          break;
        case 'wrong-password':
          errorMessage = localizations.incorrectPassword;
          break;
        case 'invalid-email':
          errorMessage = localizations.invalidEmailFormat;
          break;
        case 'user-disabled':
          errorMessage = localizations.accountDisabled;
          break;
        case 'too-many-requests':
          errorMessage = localizations.tooManyFailedAttempts;
          break;
        case 'network-request-failed':
          errorMessage = localizations.signupError;
          break;
        default:
          errorMessage = localizations.emailOrPasswordIncorrect;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.error}: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSignupPrompt(BuildContext context, String signupPromptText) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/signup');
      },
      child: Text(
        signupPromptText,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
    );
  }
}
