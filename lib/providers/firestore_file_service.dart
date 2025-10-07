import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../supabase_config.dart';

class FirestoreFileService {
  // Supabase storage bucket name
  static const String bucketName = 'documents';

  /// Upload file to Supabase storage
  static Future<Map<String, dynamic>?> uploadFile({
    required String ngoId,
    required String documentType,
    required PlatformFile file,
  }) async {
    try {
      if (!validateFile(file)) {
        throw Exception('Invalid file. Must be PDF, JPG, or PNG under 50MB');
      }

      if (file.bytes == null) {
        throw Exception('File bytes not available');
      }

      // Generate unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = file.extension ?? 'pdf';
      final fileName = '${ngoId}_${documentType}_${timestamp}.$fileExtension';
      final filePath = 'ngo_documents/$ngoId/$fileName';

      // Upload to Supabase storage
      await SupabaseConfig.client.storage.from(bucketName).uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl =
          SupabaseConfig.client.storage.from(bucketName).getPublicUrl(filePath);

      // Save file metadata to Firebase for tracking
      await _saveFileMetadataToFirebase(
        ngoId: ngoId,
        documentType: documentType,
        fileName: fileName,
        filePath: filePath,
        downloadUrl: publicUrl,
        fileSize: file.size,
        originalName: file.name,
      );

      return {
        'success': true,
        'filename': fileName,
        'file_path': filePath,
        'download_url': publicUrl,
        'file_size': file.size,
        'original_name': file.name,
        'uploaded_at': DateTime.now().toIso8601String(),
        'ngo_id': ngoId,
        'document_type': documentType,
      };
    } catch (e) {
      print('Error uploading file to Supabase: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Download file from Supabase storage
  static Future<Uint8List?> downloadFile({
    required String ngoId,
    required String filename,
  }) async {
    try {
      final filePath = 'ngo_documents/$ngoId/$filename';

      final response = await SupabaseConfig.client.storage
          .from(bucketName)
          .download(filePath);

      return response;
    } catch (e) {
      print('Error downloading file from Supabase: $e');
      return null;
    }
  }

  /// List files for an NGO from Supabase storage
  static Future<List<Map<String, dynamic>>> listFiles({
    required String ngoId,
  }) async {
    try {
      final response =
          await SupabaseConfig.client.storage.from(bucketName).list(
                path: 'ngo_documents/$ngoId',
              );

      return response
          .map((file) => {
                'name': file.name,
                'id': file.id,
                'updated_at': file.updatedAt,
                'created_at': file.createdAt,
                'last_accessed_at': file.lastAccessedAt,
                'metadata': file.metadata,
              })
          .toList();
    } catch (e) {
      print('Error listing files from Supabase: $e');
      return [];
    }
  }

  /// Delete file from Supabase storage
  static Future<bool> deleteFile({
    required String ngoId,
    required String filename,
  }) async {
    try {
      final filePath = 'ngo_documents/$ngoId/$filename';

      // Delete from Supabase storage
      await SupabaseConfig.client.storage.from(bucketName).remove([filePath]);

      // Delete metadata from Firebase
      await deleteFileMetadata(ngoId: ngoId, fileName: filename);

      return true;
    } catch (e) {
      print('Error deleting file from Supabase: $e');
      return false;
    }
  }

  /// Submit yearly documents to Supabase storage
  static Future<Map<String, dynamic>?> submitYearlyDocuments({
    required String ngoId,
    required String financialYear,
    required Map<String, PlatformFile> documents,
  }) async {
    try {
      final results = <String, Map<String, dynamic>>{};

      for (final entry in documents.entries) {
        final documentType = entry.key;
        final file = entry.value;

        if (file.bytes == null) continue;

        // Generate unique file path for yearly documents
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileExtension = file.extension ?? 'pdf';
        final fileName =
            '${ngoId}_${financialYear}_${documentType}_${timestamp}.$fileExtension';
        final filePath = 'yearly_documents/$ngoId/$financialYear/$fileName';

        // Upload to Supabase storage
        await SupabaseConfig.client.storage.from(bucketName).uploadBinary(
              filePath,
              file.bytes!,
              fileOptions: const FileOptions(
                contentType: 'application/octet-stream',
                upsert: false,
              ),
            );

        // Get public URL
        final publicUrl = SupabaseConfig.client.storage
            .from(bucketName)
            .getPublicUrl(filePath);

        results[documentType] = {
          'filename': fileName,
          'file_path': filePath,
          'download_url': publicUrl,
          'file_size': file.size,
          'original_name': file.name,
          'uploaded_at': DateTime.now().toIso8601String(),
        };

        // Save file metadata to Firebase for tracking
        await _saveFileMetadataToFirebase(
          ngoId: ngoId,
          documentType: 'yearly_$documentType',
          fileName: fileName,
          filePath: filePath,
          downloadUrl: publicUrl,
          fileSize: file.size,
          originalName: file.name,
        );
      }

      return {
        'success': true,
        'ngo_id': ngoId,
        'financial_year': financialYear,
        'documents': results,
        'submitted_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error submitting yearly documents to Supabase: $e');
      throw Exception('Failed to submit yearly documents: $e');
    }
  }

  /// Submit proposal to Supabase storage
  static Future<Map<String, dynamic>?> submitProposal({
    required String ngoId,
    required String title,
    required String description,
    required double requestedAmount,
    required PlatformFile proposalDocument,
  }) async {
    try {
      if (proposalDocument.bytes == null) {
        throw Exception('Proposal document bytes not available');
      }

      // Generate unique file path for proposal
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = proposalDocument.extension ?? 'pdf';
      final fileName = '${ngoId}_proposal_${timestamp}.$fileExtension';
      final filePath = 'proposals/$ngoId/$fileName';

      // Upload to Supabase storage
      await SupabaseConfig.client.storage.from(bucketName).uploadBinary(
            filePath,
            proposalDocument.bytes!,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl =
          SupabaseConfig.client.storage.from(bucketName).getPublicUrl(filePath);

      // Save file metadata to Firebase for tracking
      await _saveFileMetadataToFirebase(
        ngoId: ngoId,
        documentType: 'proposal',
        fileName: fileName,
        filePath: filePath,
        downloadUrl: publicUrl,
        fileSize: proposalDocument.size,
        originalName: proposalDocument.name,
      );

      return {
        'success': true,
        'ngo_id': ngoId,
        'title': title,
        'description': description,
        'requested_amount': requestedAmount,
        'proposal_filename': fileName,
        'proposal_file_path': filePath,
        'proposal_download_url': publicUrl,
        'proposal_file_size': proposalDocument.size,
        'proposal_original_name': proposalDocument.name,
        'submitted_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error submitting proposal to Supabase: $e');
      throw Exception('Failed to submit proposal: $e');
    }
  }

  /// Validate file before upload
  static bool validateFile(PlatformFile file) {
    // Check file extension
    final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
    final extension = file.extension?.toLowerCase();

    if (extension == null || !allowedExtensions.contains(extension)) {
      return false;
    }

    // Check file size (50MB limit)
    const maxSize = 50 * 1024 * 1024; // 50MB in bytes
    if (file.size > maxSize) {
      return false;
    }

    return true;
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Test Supabase storage connection
  static Future<bool> testConnection() async {
    try {
      // Try to list files in the documents bucket
      await SupabaseConfig.client.storage.from(bucketName).list();

      print('✅ Supabase storage connection successful');
      return true;
    } catch (e) {
      print('❌ Supabase storage connection failed: $e');
      return false;
    }
  }

  /// Save file metadata to Firebase for tracking
  static Future<void> _saveFileMetadataToFirebase({
    required String ngoId,
    required String documentType,
    required String fileName,
    required String filePath,
    required String downloadUrl,
    required int fileSize,
    required String originalName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final timestamp = DateTime.now();

      // Save to NGO's documents collection
      await firestore
          .collection('ngo_proposals')
          .doc(ngoId)
          .collection('uploaded_documents')
          .doc(fileName)
          .set({
        'documentType': documentType,
        'fileName': fileName,
        'filePath': filePath,
        'downloadUrl': downloadUrl,
        'fileSize': fileSize,
        'originalName': originalName,
        'uploadedAt': timestamp,
        'storageType': 'supabase',
        'bucketName': bucketName,
        'ngoId': ngoId,
      });

      // Also update the main NGO document with document metadata
      await firestore.collection('ngo_proposals').doc(ngoId).update({
        'lastDocumentUpload': timestamp,
        'totalDocumentsUploaded': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // File metadata saved to Firebase for tracking
    } catch (e) {
      // Error saving file metadata to Firebase - continue silently
    }
  }

  /// Get uploaded documents for an NGO from Firebase
  static Future<List<Map<String, dynamic>>> getUploadedDocuments({
    required String ngoId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('ngo_proposals')
          .doc(ngoId)
          .collection('uploaded_documents')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting uploaded documents from Firebase: $e');
      return [];
    }
  }

  /// Delete file metadata from Firebase
  static Future<bool> deleteFileMetadata({
    required String ngoId,
    required String fileName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete from uploaded_documents collection
      await firestore
          .collection('ngo_proposals')
          .doc(ngoId)
          .collection('uploaded_documents')
          .doc(fileName)
          .delete();

      // Update total count
      await firestore.collection('ngo_proposals').doc(ngoId).update({
        'totalDocumentsUploaded': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error deleting file metadata from Firebase: $e');
      return false;
    }
  }
}
