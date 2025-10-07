import 'package:flutter/material.dart';
import '../supabase_config.dart';
import '../providers/firestore_file_service.dart';

class SupabaseTestService {
  /// Test Supabase connection
  static Future<bool> testConnection() async {
    try {
      // Test basic connection
      final response = await SupabaseConfig.client
          .from('test_table')
          .select('*')
          .limit(1);
      
      print('✅ Supabase connection successful');
      return true;
    } catch (e) {
      print('❌ Supabase connection failed: $e');
      return false;
    }
  }
  
  /// Test Supabase authentication
  static Future<bool> testAuth() async {
    try {
      // Test if we can access auth
      final user = SupabaseConfig.currentUser;
      print('✅ Supabase auth accessible. Current user: ${user?.id ?? 'None'}');
      return true;
    } catch (e) {
      print('❌ Supabase auth test failed: $e');
      return false;
    }
  }
  
  /// Test Supabase storage
  static Future<bool> testStorage() async {
    try {
      // Test if we can access storage and list buckets
      final storage = SupabaseConfig.storage;
      final buckets = await storage.listBuckets();
      print('✅ Supabase storage accessible. Found ${buckets.length} buckets');
      
      // Test documents bucket specifically
      final documentsBucket = buckets.firstWhere(
        (bucket) => bucket.name == 'documents',
        orElse: () => throw Exception('Documents bucket not found'),
      );
      print('✅ Documents bucket found: ${documentsBucket.name}');
      
      return true;
    } catch (e) {
      print('❌ Supabase storage test failed: $e');
      return false;
    }
  }
  
  /// Test file service
  static Future<bool> testFileService() async {
    try {
      // Test file service connection
      final result = await FirestoreFileService.testConnection();
      print('✅ File service connection test: ${result ? 'PASS' : 'FAIL'}');
      return result;
    } catch (e) {
      print('❌ File service test failed: $e');
      return false;
    }
  }
  
  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    print('🧪 Running Supabase tests...');
    
    final results = <String, bool>{};
    
    results['connection'] = await testConnection();
    results['auth'] = await testAuth();
    results['storage'] = await testStorage();
    results['file_service'] = await testFileService();
    
    final allPassed = results.values.every((result) => result);
    print(allPassed ? '✅ All Supabase tests passed!' : '❌ Some Supabase tests failed');
    
    return results;
  }
  
  /// Show test results in a dialog
  static void showTestResults(BuildContext context, Map<String, bool> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supabase Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: results.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.error,
                    color: entry.value ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.key}: ${entry.value ? 'PASS' : 'FAIL'}'),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
