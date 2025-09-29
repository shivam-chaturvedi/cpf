import 'constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    final emailRegex = RegExp(ValidationRules.emailPattern);
    if (!emailRegex.hasMatch(value.trim())) {
      return AppConstants.invalidEmailMessage;
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value.length < ValidationRules.minPasswordLength) {
      return AppConstants.passwordTooShortMessage;
    }
    
    if (value.length > ValidationRules.maxPasswordLength) {
      return 'Password must be less than ${ValidationRules.maxPasswordLength} characters';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value != password) {
      return AppConstants.passwordMismatchMessage;
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? '$fieldName is required'
          : AppConstants.requiredFieldMessage;
    }
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    // Remove all non-digit characters
    final phoneDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Indian phone number (10 digits)
    if (phoneDigits.length != 10) {
      return 'Phone number must be 10 digits';
    }
    
    // Check if it starts with valid digits (6-9)
    if (!RegExp(r'^[6-9]').hasMatch(phoneDigits)) {
      return 'Phone number must start with 6, 7, 8, or 9';
    }
    
    return null;
  }

  // NGO name validation
  static String? validateNGOName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NGO name is required';
    }
    
    if (value.trim().length < ValidationRules.minNgoNameLength) {
      return 'NGO name must be at least ${ValidationRules.minNgoNameLength} characters';
    }
    
    if (value.trim().length > ValidationRules.maxNgoNameLength) {
      return 'NGO name must be less than ${ValidationRules.maxNgoNameLength} characters';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    
    final phoneRegex = RegExp(ValidationRules.phonePattern);
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    
    if (value.trim().length > ValidationRules.maxContactNumberLength) {
      return 'Phone number is too long';
    }
    
    return null;
  }

  // URL validation (optional field)
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final urlRegex = RegExp(ValidationRules.urlPattern);
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    
    if (value.trim().length < ValidationRules.minDescriptionLength) {
      return 'Description must be at least ${ValidationRules.minDescriptionLength} characters';
    }
    
    if (value.trim().length > ValidationRules.maxDescriptionLength) {
      return 'Description must be less than ${ValidationRules.maxDescriptionLength} characters';
    }
    
    return null;
  }

  // Registration ID validation
  static String? validateRegistrationId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration ID is required';
    }
    
    // Basic alphanumeric validation
    if (!RegExp(r'^[a-zA-Z0-9\/\-\_]+$').hasMatch(value.trim())) {
      return 'Registration ID contains invalid characters';
    }
    
    if (value.trim().length < 3) {
      return 'Registration ID is too short';
    }
    
    if (value.trim().length > 50) {
      return 'Registration ID is too long';
    }
    
    return null;
  }

  // File validation
  static String? validateFileSelection(List<dynamic> files) {
    if (files.isEmpty) {
      return 'Please upload at least one document';
    }
    
    return null;
  }

  // Generic length validation
  static String? validateLength(
    String? value, 
    int minLength, 
    int maxLength, 
    String fieldName
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    if (value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  // Alphanumeric validation
  static String? validateAlphanumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value.trim())) {
      return '$fieldName can only contain letters, numbers, and spaces';
    }
    
    return null;
  }

  // PAN Card validation (10-character format: 5 letters + 4 digits + 1 letter)
  static String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN Card number is mandatory';
    }
    
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    final cleanValue = value.trim().toUpperCase();
    
    if (cleanValue.length != 10) {
      return 'PAN must be exactly 10 characters';
    }
    
    if (!panRegex.hasMatch(cleanValue)) {
      return 'PAN must be in format: AAAAA9999A (5 letters + 4 digits + 1 letter)';
    }
    
    return null;
  }

  // TAN validation (10-character format: 4 letters + 5 digits + 1 letter)
  static String? validateTAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'TAN number is required';
    }
    
    final tanRegex = RegExp(r'^[A-Z]{4}[0-9]{5}[A-Z]{1}$');
    final cleanValue = value.trim().toUpperCase();
    
    if (cleanValue.length != 10) {
      return 'TAN must be exactly 10 characters';
    }
    
    if (!tanRegex.hasMatch(cleanValue)) {
      return 'TAN must be in format: AAAA99999A (4 letters + 5 digits + 1 letter)';
    }
    
    return null;
  }

  // File size validation for 25MB limit
  static String? validateFileSize(int bytes, {int maxSizeMB = 25}) {
    final maxBytes = maxSizeMB * 1024 * 1024;
    if (bytes > maxBytes) {
      return 'File size must be less than ${maxSizeMB}MB';
    }
    return null;
  }

  // Multiple file validation
  static String? validateMultipleFiles(List<dynamic> files, {int maxFiles = 10, int maxSizeMB = 25}) {
    if (files.isEmpty) {
      return 'Please upload at least one file';
    }
    
    if (files.length > maxFiles) {
      return 'Maximum $maxFiles files allowed';
    }
    
    for (var file in files) {
      if (file.size > maxSizeMB * 1024 * 1024) {
        return 'File "${file.name}" exceeds ${maxSizeMB}MB limit';
      }
    }
    
    return null;
  }
}