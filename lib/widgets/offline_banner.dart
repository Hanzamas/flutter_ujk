import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/connectivity_service.dart';
import '../core/constants/app_colors.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _autoHideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isVisible = false;
  bool _isPermanentlyHidden = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    
    // ✅ Main slide animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // ✅ Auto-hide animation (separate controller)
    _autoHideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _autoHideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoHideController.dispose();
    super.dispose();
  }

  void _showBanner() {
    if (!_isVisible && !_isPermanentlyHidden) {
      setState(() {
        _isVisible = true;
      });
      
      _animationController.forward();
      _autoHideController.reset();
      
      // ✅ Auto-hide setelah 4 detik (lebih lama untuk banner penting)
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _isVisible && !_isPermanentlyHidden) {
          _autoHideController.forward().then((_) {
            if (mounted) {
              setState(() {
                _isVisible = false;
              });
            }
          });
        }
      });
    }
  }

  void _hideBanner() {
    if (_isVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
            _isPermanentlyHidden = true; // ✅ Permanently hide saat manual close
          });
        }
      });
    }
  }

  void _resetVisibility() {
    // ✅ Reset visibility saat kembali online
    setState(() {
      _isPermanentlyHidden = false;
      _isVisible = false;
    });
    _animationController.reset();
    _autoHideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        final currentlyOffline = connectivity.isOffline;
        
        // ✅ Smart visibility logic
        if (currentlyOffline && !_wasOffline && !_isPermanentlyHidden) {
          // Baru saja offline - show banner
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showBanner();
          });
        } else if (!currentlyOffline && _wasOffline) {
          // Baru saja online - reset dan hide
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resetVisibility();
          });
        }
        
        _wasOffline = currentlyOffline;

        // Don't show if online or not visible
        if (connectivity.isOnline || !_isVisible) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                elevation: 4,
                color: Colors.amber[100],
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          color: Colors.amber[800],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'You\'re offline',
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Showing cached data from Firestore',
                                style: TextStyle(
                                  color: Colors.amber[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // ✅ Retry button
                        TextButton.icon(
                          onPressed: () async {
                            await connectivity.checkConnection();
                            
                            if (connectivity.isOnline && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.wifi, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Connected! Data synced.'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green[600],
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.amber[800],
                          ),
                          label: Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                        
                        // ✅ Close button
                        IconButton(
                          onPressed: _hideBanner,
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.amber[800],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Hide offline banner',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}