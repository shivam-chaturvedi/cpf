class AppConstants {
  // App Info
  static const String appName = 'CPF Portal';
  static const String appVersion = '1.0.0';
  
  // Admin Credentials
  static const String adminEmail = 'admin@cpf.org.in';
  static const String adminPassword = 'CPFAdmin2024!';
  
  // Firebase Collections
  static const String ngoProposalsCollection = 'ngo_proposals';
  static const String usersCollection = 'users';
  
  // Storage Paths
  static const String documentsStoragePath = 'documents';
  static const String ngoDocumentsPath = 'ngo_documents';
  
  // File Upload
  static const List<String> allowedFileExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxAuditFileSize = 25 * 1024 * 1024; // 25MB for audit reports
  static const int maxAuditFiles = 10; // Maximum audit files per year
  
  // Status Values
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  
  // Contact Info
  static const String supportPhone = '+91 9871216099';
  static const String supportEmail = 'support@cpf.org.in';
  static const String websiteUrl = 'https://cpfindia.org/';
  
  // Validation Messages
  static const String requiredFieldMessage = 'This field is required';
  static const String invalidEmailMessage = 'Please enter a valid email address';
  static const String passwordTooShortMessage = 'Password must be at least 6 characters';
  static const String passwordMismatchMessage = 'Passwords do not match';
  
  // Success Messages
  static const String registrationSuccessMessage = 'Registration successful! You can now login.';
  static const String loginSuccessMessage = 'Welcome back!';
  static const String updateSuccessMessage = 'Information updated successfully';
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String unknownErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String fileUploadErrorMessage = 'Failed to upload file. Please try again.';
  
  // Processing Time
  static const String processingTimeMessage = 'Applications are typically processed within 5-10 working days';
  
  // File Types
  static const Map<String, String> documentTypes = {
    'registration_certificate': 'Registration Certificate',
    'pan_card': 'PAN Card',
    'address_proof': 'Address Proof',
    'audit_report': 'Audit Report',
    '12a_certificate': '12A Certificate',
    '80g_certificate': '80G Certificate',
    'fcra_certificate': 'FCRA Certificate',
    'financial_statement': 'Financial Statement',
  };
}

class ValidationRules {
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNgoNameLength = 2;
  static const int maxNgoNameLength = 100;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1000;
  static const int maxContactNumberLength = 15;
  
  // Regex patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^[0-9+\-\s\(\)]{7,15}$';
  static const String urlPattern = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
}