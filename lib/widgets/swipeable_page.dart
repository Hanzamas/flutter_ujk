import 'package:flutter/material.dart';
import '../core/services/gesture_navigation_service.dart';
import '../core/constants/app_colors.dart';

class SwipeablePage extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final bool enableSwipeNavigation;

  const SwipeablePage({
    super.key,
    required this.child,
    required this.currentRoute,
    this.enableSwipeNavigation = true,
  });

  @override
  State<SwipeablePage> createState() => _SwipeablePageState();
}

class _SwipeablePageState extends State<SwipeablePage>
    with TickerProviderStateMixin {
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  
  bool _isSwipeInProgress = false;
  double _swipeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enableSwipeNavigation) return;
    
    setState(() {
      _isSwipeInProgress = true;
      _swipeProgress = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeNavigation || !_isSwipeInProgress) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = details.delta.dx / screenWidth;
    
    setState(() {
      _swipeProgress = (_swipeProgress + progress).clamp(-1.0, 1.0);
    });
    
    // Trigger animation based on swipe progress
    _slideAnimationController.value = _swipeProgress.abs() * 0.3;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableSwipeNavigation || !_isSwipeInProgress) return;
    
    setState(() {
      _isSwipeInProgress = false;
    });
    
    // Reset animation
    _slideAnimationController.reverse();
    
    // Handle navigation
    GestureNavigationService.handleSwipeNavigation(
      context,
      details,
      widget.currentRoute,
    );
    
    setState(() {
      _swipeProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Main content
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimation.value * MediaQuery.of(context).size.width,
                child: widget.child,
              );
            },
          ),
          
          // Swipe indicator overlay
          if (_isSwipeInProgress && _swipeProgress.abs() > 0.1)
            _buildSwipeIndicator(),
        ],
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final isSwipeRight = _swipeProgress > 0;
    final targetRoute = _getTargetRoute(isSwipeRight);
    
    if (targetRoute == null) return const SizedBox.shrink();
    
    return Positioned(
      left: isSwipeRight ? 0 : null,
      right: !isSwipeRight ? 0 : null,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isSwipeRight ? Alignment.centerLeft : Alignment.centerRight,
            end: isSwipeRight ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              AppColors.primary.withOpacity(0.2),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                GestureNavigationService.getTabIcon(targetRoute),
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                GestureNavigationService.getTabName(targetRoute),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSwipeRight ? 'Swipe right' : 'Swipe left',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getTargetRoute(bool isSwipeRight) {
    const tabOrder = [
      'home',
      'favorites',
      'profile',
    ];
    
    final currentIndex = tabOrder.indexOf(widget.currentRoute);
    if (currentIndex == -1) return null;
    
    if (isSwipeRight && currentIndex > 0) {
      return tabOrder[currentIndex - 1];
    } else if (!isSwipeRight && currentIndex < tabOrder.length - 1) {
      return tabOrder[currentIndex + 1];
    }
    
    return null;
  }
}