import 'package:cpf_portal/util/constants.dart';
import 'package:cpf_portal/util/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';


class AppHelpers {
  // Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusApproved:
        return AppTheme.accentGold;
      case AppConstants.statusRejected:
        return AppTheme.errorRed;
      case AppConstants.statusPending:
      default:
        return AppTheme.warningOrange;
    }
  }

  // Get status icon
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusApproved:
        return Icons.check_circle;
      case AppConstants.statusRejected:
        return Icons.cancel;
      case AppConstants.statusPending:
      default:
        return Icons.pending;
    }
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.accentGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.primaryRed,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if file type is allowed
  static bool isFileTypeAllowed(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.allowedFileExtensions.contains(extension);
  }

  // Check if file size is valid
  static bool isFileSizeValid(int bytes) {
    return bytes <= AppConstants.maxFileSize;
  }

  // Get file extension
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  // Generate unique file name
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalName);
    return '${timestamp}_${originalName.split('.').first}.$extension';
  }

  // Capitalize first letter
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Format status text
  static String formatStatusText(String status) {
    return capitalizeFirst(status);
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return const EdgeInsets.symmetric(horizontal: 120, vertical: 24);
    } else if (screenWidth > 768) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 768) {
      return baseFontSize * 0.9;
    } else if (screenWidth < 1024) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return baseSpacing * 0.7; // Smaller spacing for very small screens
    } else if (screenWidth < 768) {
      return baseSpacing * 0.8; // Medium spacing for mobile
    } else {
      return baseSpacing; // Full spacing for larger screens
    }
  }

  // Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return const BoxConstraints(maxWidth: 350); // Very small screens
    } else if (screenWidth < 768) {
      return const BoxConstraints(maxWidth: 400); // Mobile screens
    } else if (screenWidth < 1024) {
      return const BoxConstraints(maxWidth: 500); // Tablet screens
    } else {
      return const BoxConstraints(maxWidth: 600); // Desktop screens
    }
  }

  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return baseSize * 0.8;
    } else if (screenWidth < 768) {
      return baseSize * 0.9;
    } else {
      return baseSize;
    }
  }

  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return 44; // Smaller button height for very small screens
    } else {
      return 48; // Standard button height
    }
  }

  // Debounce function
  static void debounce(Duration duration, VoidCallback callback) {
    Timer? timer;
    // ignore: dead_code
    timer?.cancel();
    timer = Timer(duration, callback);
  }

  // Format currency (INR)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Validate network connectivity
  static Future<bool> hasNetworkConnection() async {
    try {
      // Simple connectivity check - in production, use connectivity_plus package
      return true; // Placeholder implementation
    } catch (e) {
      return false;
    }
  }
}

// Timer import
