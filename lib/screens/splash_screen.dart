// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../services/model_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final ModelService modelService;

  const SplashScreen({
    super.key,
    required this.modelService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _loadingText = 'Initializing...';
  bool _hasError = false;
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _loadingText = 'Connecting to server...';
      _hasError = false;
      _errorMessage = null;
      _isRetrying = false;
    });

    // Actually call loadModel and wait for it to complete.
    await widget.modelService.loadModel();

    if (!mounted) return;

    if (widget.modelService.isLoaded) {
      setState(() => _loadingText = 'Ready!');
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      _navigateNext();
    } else {
      // Health check failed — show error on splash, don't proceed.
      setState(() {
        _hasError = true;
        _errorMessage = widget.modelService.errorMessage ??
            'Could not connect to the server.';
      });
    }
  }

  Future<void> _onRetry() async {
    setState(() => _isRetrying = true);
    await _initializeApp();
    if (mounted) setState(() => _isRetrying = false);
  }

  void _navigateNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield,
                  size: 60,
                  color: Colors.blueAccent,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Verilens',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'DistilBERT + Bi-LSTM',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueAccent,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 48),

              // ── Loading / error state ─────────────────────────────
              if (!_hasError) ...[
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _loadingText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ] else ...[
                // Error icon
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
                const SizedBox(height: 12),
                // Error message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Retry button
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _onRetry,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(
                      _isRetrying ? 'Retrying...' : 'Retry',
                      style: const TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          Colors.blueAccent.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}