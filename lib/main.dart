import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';

import 'models/user.dart';
import 'services/auth_service.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/forgot_password_view.dart';
import 'views/auth/email_verify_view.dart';
import 'views/admin/admin_dashboard_view.dart';
import 'views/user/user_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBSfxTmZrAvBWuxFGBijO9ix8SNPkhYu6A",
          authDomain: "foodchannelmnl.firebaseapp.com",
          databaseURL: "https://foodchannelmnl-default-rtdb.firebaseio.com",
          projectId: "foodchannelmnl",
          storageBucket: "foodchannelmnl.firebasestorage.app",
          messagingSenderId: "583742814986",
          appId: "1:583742814986:web:5fad9a7834afe0f423d8f3",
        ),
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodChannel MNL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Outfit',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8A00),
          secondary: Color(0xFFDA1B60),
          surface: Color(0xFF150A2E),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginView(),
        '/register': (context) => const RegisterView(),
        '/forgot': (context) => const ForgotPasswordView(),
        '/verify': (context) => const EmailVerifyView(),
        '/admin': (context) => const AdminDashboardView(),
        '/user': (context) => const UserHomeView(),
      },
    );
  }
}

// ----------------------------------------------------
// AUTH WRAPPER (DEFAULT LANDING CONTROLLER)
// ----------------------------------------------------
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _splashFinished = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF070412),
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)))),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // If logged out, display cinematic entrance animations before login screen
          if (!_splashFinished) {
            return ConnectionCheckScreen(
              onFinished: () {
                setState(() {
                  _splashFinished = true;
                });
              },
            );
          }
          return const LoginView();
        }

        // If logged in, dynamically check verification status and retrieve role
        if (!user.emailVerified) {
          return const EmailVerifyView();
        }

        return FutureBuilder<UserModel?>(
          future: AuthService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF070412),
                body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)))),
              );
            }

            final profile = profileSnapshot.data;
            if (user.email?.toLowerCase() == 'bharathvemavarapu11@gmail.com') {
              return const AdminDashboardView();
            }
            if (profile == null) {
              // Fallback to normal UserHomeView if user data doesn't exist in RTDB yet
              return const UserHomeView();
            }

            if (profile.role == 'admin') {
              return const AdminDashboardView();
            } else {
              return const UserHomeView();
            }
          },
        );
      },
    );
  }
}

// ----------------------------------------------------
// 1. CONNECTION & ENVIRONMENT INITIAL CHECK SCREEN
// ----------------------------------------------------
enum ConnectionStatus { idle, checking, success, failed }

class ConnectionCheckScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const ConnectionCheckScreen({super.key, required this.onFinished});

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  ConnectionStatus _firebaseStatus = ConnectionStatus.idle;
  ConnectionStatus _cloudinaryStatus = ConnectionStatus.idle;
  ConnectionStatus _mapboxStatus = ConnectionStatus.idle;
  
  String? _firebaseError;
  String? _cloudinaryError;
  String? _mapboxError;

  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _startIntegrationsCheck();
  }

  Future<void> _startIntegrationsCheck() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _checkFirebase();
    await _checkCloudinary();
    await _checkMapbox();

    if (_firebaseStatus == ConnectionStatus.success &&
        _cloudinaryStatus == ConnectionStatus.success &&
        _mapboxStatus == ConnectionStatus.success) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _isTransitioning = true;
        });
      }
    }
  }

  Future<void> _checkFirebase() async {
    if (!mounted) return;
    setState(() {
      _firebaseStatus = ConnectionStatus.checking;
    });

    try {
      // Check RTDB connection by fetching categories root
      final response = await http.get(Uri.parse('https://foodchannelmnl-default-rtdb.firebaseio.com/store/categories.json'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _firebaseStatus = ConnectionStatus.success;
          });
        }
      } else {
        throw Exception("Invalid HTTP status code: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firebaseStatus = ConnectionStatus.failed;
          _firebaseError = e.toString();
        });
      }
    }
  }

  Future<void> _checkCloudinary() async {
    if (!mounted) return;
    setState(() {
      _cloudinaryStatus = ConnectionStatus.checking;
    });

    try {
      final response = await http.post(Uri.parse('https://api.cloudinary.com/v1_1/dus8mvmah/image/upload'));
      if (response.statusCode == 400 || response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cloudinaryStatus = ConnectionStatus.success;
          });
        }
      } else {
        throw Exception("Cloudinary server returned code: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cloudinaryStatus = ConnectionStatus.failed;
          _cloudinaryError = e.toString();
        });
      }
    }
  }

  Future<void> _checkMapbox() async {
    if (!mounted) return;
    setState(() {
      _mapboxStatus = ConnectionStatus.checking;
    });

    try {
      final token = 'YOUR_MAPBOX_TOKEN';
      final response = await http.get(Uri.parse('https://api.mapbox.com/geocoding/v5/mapbox.places/India.json?access_token=$token&limit=1'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _mapboxStatus = ConnectionStatus.success;
          });
        }
      } else {
        throw Exception("Mapbox server returned code: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mapboxStatus = ConnectionStatus.failed;
          _mapboxError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTransitioning) {
      return SplashScreen(onFinished: widget.onFinished);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 72, color: Color(0xFFFF8A00)),
              const SizedBox(height: 24),
              const Text(
                "FoodChannel MNL Systems Link",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                "Establishing secure connection to APIs",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
              ),
              const SizedBox(height: 48),
              Container(
                width: 480,
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildConnectionTile("Firebase Realtime Database", _firebaseStatus, _firebaseError),
                    const Divider(color: Colors.white10, height: 28),
                    _buildConnectionTile("Cloudinary CDN Engine", _cloudinaryStatus, _cloudinaryError),
                    const Divider(color: Colors.white10, height: 28),
                    _buildConnectionTile("Mapbox Interactive Maps", _mapboxStatus, _mapboxError),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isTransitioning = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFFF8A00),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFFF8A00), width: 1.0),
                ),
                child: const Text(
                  "BYPASS CHECKS & PROCEED",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionTile(String serviceName, ConnectionStatus status, String? error) {
    Widget trailing;
    switch (status) {
      case ConnectionStatus.idle:
        trailing = const Icon(Icons.radio_button_off_rounded, color: Colors.white30);
        break;
      case ConnectionStatus.checking:
        trailing = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
        );
        break;
      case ConnectionStatus.success:
        trailing = const Icon(Icons.check_circle_rounded, color: Colors.greenAccent);
        break;
      case ConnectionStatus.failed:
        trailing = const Icon(Icons.error_outline_rounded, color: Colors.redAccent);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 14)),
            trailing,
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'monospace')),
        ],
      ],
    );
  }
}

// ----------------------------------------------------
// 2. CINEMATIC SPLASH ANIMATION & LOTTIE TRANSITION
// ----------------------------------------------------
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isVideoInitialized = false;
  bool _isVideoEnded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    if (kIsWeb) {
      _isVideoInitialized = false;
      _isVideoEnded = true;
      _fadeController.forward();
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onFinished();
        }
      });
    } else {
      _videoController = VideoPlayerController.asset('assets/Cinematic_brand_splash_animation_202606271855.mp4');
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.play();
          _videoController!.addListener(_videoListener);
        }
      }).catchError((error) {
        debugPrint("Error initializing video player: $error");
        _onVideoEnded();
      });
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    if (_isVideoInitialized && !_videoController!.value.isPlaying && position >= duration) {
      _videoController!.removeListener(_videoListener);
      _onVideoEnded();
    }
  }

  void _onVideoEnded() {
    if (_isVideoEnded) return;
    setState(() {
      _isVideoEnded = true;
    });
    
    _videoController?.dispose();
    _fadeController.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    if (!_isVideoEnded && _videoController != null) {
      _videoController!.removeListener(_videoListener);
      _videoController!.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_isVideoEnded)
            Center(
              child: _isVideoInitialized && _videoController != null
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A00)),
                    ),
            ),
          if (_isVideoEnded)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF070412), Color(0xFF140A28)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/loading.json',
                        width: 280,
                        height: 280,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF8A00), Color(0xFFDA1B60)],
                        ).createShader(bounds),
                        child: const Text(
                          "FOODCHANNEL",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Connecting Culinary Minds",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w300,
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
}
