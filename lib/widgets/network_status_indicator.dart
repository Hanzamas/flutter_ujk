import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';

class NetworkStatusIndicator extends StatelessWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        return Positioned(
          // ✅ Top right corner - minimal space
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: connectivity.isOffline ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: connectivity.statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                connectivity.statusIcon,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}