import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../widgets/loading_widget.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  Map<String, dynamic> _deviceInfo = {};
  PackageInfo? _packageInfo;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      // Get device info
      final deviceInfoPlugin = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'Device Name': androidInfo.model,
          'Brand': androidInfo.brand,
          'Manufacturer': androidInfo.manufacturer,
          'Android Version': androidInfo.version.release,
          'SDK Version': androidInfo.version.sdkInt.toString(),
          'Board': androidInfo.board,
          'Hardware': androidInfo.hardware,
          'Is Physical Device': androidInfo.isPhysicalDevice ? 'Yes' : 'No',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'Device Name': iosInfo.name,
          'Model': iosInfo.model,
          'System Name': iosInfo.systemName,
          'System Version': iosInfo.systemVersion,
          'Is Physical Device': iosInfo.isPhysicalDevice ? 'Yes' : 'No',
        };
      }

      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();

      // Get connectivity status
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      setState(() {
        _deviceInfo = deviceData;
        _packageInfo = packageInfo;
        _connectionStatus = connectivityResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Device Information',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? // ✅ FIX: Center the loading widget properly
          const Center(
              child: LoadingWidget(message: 'Loading device info...'),
            )
          : RefreshIndicator(
              onRefresh: _loadDeviceInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // App Information
                    _buildInfoSection(
                      'App Information',
                      Icons.smartphone,
                      _packageInfo != null
                          ? {
                              'App Name': _packageInfo!.appName,
                              'Package Name': _packageInfo!.packageName,
                              'Version': _packageInfo!.version,
                              'Build Number': _packageInfo!.buildNumber,
                            }
                          : {},
                      AppColors.primary,
                    ),

                    const SizedBox(height: 16),

                    // Device Information
                    _buildInfoSection(
                      'Device Information',
                      Icons.phone_android,
                      _deviceInfo,
                      AppColors.success,
                    ),

                    const SizedBox(height: 16),

                    // Network Information
                    _buildInfoSection(
                      'Network Status',
                      Icons.wifi,
                      {
                        'Connection Type': _getConnectionTypeName(_connectionStatus),
                        'Status': _hasConnection(_connectionStatus) ? 'Connected' : 'Disconnected',
                        'Active Connections': _connectionStatus.length.toString(),
                      },
                      _hasConnection(_connectionStatus) 
                          ? AppColors.success 
                          : AppColors.error,
                    ),

                    const SizedBox(height: 24),

                    // Refresh Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadDeviceInfo,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Information'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Map<String, dynamic> data,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No information available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final key = data.keys.elementAt(index);
                final value = data[key];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          value?.toString() ?? 'N/A',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getConnectionTypeName(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'No Connection';
    }
    
    final primaryConnection = results.firstWhere(
      (result) => result != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
    
    switch (primaryConnection) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.isNotEmpty && 
           !results.every((result) => result == ConnectivityResult.none);
  }
}