import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class NGOProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, dynamic>? _ngoData;
  final List<Map<String, dynamic>> _allNGOs = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get ngoData => _ngoData;
  List<Map<String, dynamic>> get allNGOs => _allNGOs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch current NGO data
  Future<void> fetchNGOData() async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return;
      }

      final doc =
          await _firestore.collection('ngo_proposals').doc(user.uid).get();

      if (doc.exists) {
        _ngoData = doc.data();
      } else {
        _setError('NGO data not found');
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch NGO data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Fetch all NGOs (for admin)
  Stream<List<Map<String, dynamic>>> getAllNGOsStream() {
    return _firestore
        .collection('ngo_proposals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Update NGO status (admin only)
  Future<bool> updateNGOStatus({
    required String ngoId,
    required String status,
    String? adminComments,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('ngo_proposals').doc(ngoId).update({
        'status': status,
        'adminComments': adminComments,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update NGO status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Upload file to Firebase Storage
  Future<String?> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _setError('Failed to upload file: ${e.toString()}');
      return null;
    }
  }

  // Update NGO data
  Future<bool> updateNGOData(Map<String, dynamic> updatedData) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      await _firestore.collection('ngo_proposals').doc(user.uid).update({
        ...updatedData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh local data
      await fetchNGOData();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update NGO data: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get NGO statistics (for admin dashboard)
  Future<Map<String, int>> getNGOStatistics() async {
    try {
      final snapshot = await _firestore.collection('ngo_proposals').get();

      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        switch (status.toLowerCase()) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return {
        'total': snapshot.docs.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    } catch (e) {
      _setError('Failed to fetch statistics: ${e.toString()}');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };
    }
  }

  // Delete NGO proposal (admin only)
  Future<bool> deleteNGO(String ngoId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('ngo_proposals').doc(ngoId).delete();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete NGO: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get NGOs with advanced filtering
  Future<List<Map<String, dynamic>>> getFilteredNGOs({
    String? status,
    String? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      print('========================================');
      print('FILTERING NGOs:');
      print('Status: $status');
      print('Category: $category');
      print('Location: $location');
      print('Search Query: $searchQuery');
      print('========================================');

      // Fetch all NGOs first to avoid composite index requirements
      final snapshot = await _firestore
          .collection('ngo_proposals')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> ngos = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print('Total NGOs fetched: ${ngos.length}');

      // Apply status filter
      if (status != null && status.isNotEmpty) {
        ngos = ngos.where((ngo) {
          final ngoStatus = (ngo['status'] ?? '').toString().toLowerCase();
          return ngoStatus == status.toLowerCase();
        }).toList();
        print('After status filter: ${ngos.length}');
      }

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        ngos = ngos.where((ngo) {
          final ngoCategory = (ngo['category'] ?? '').toString().toLowerCase();
          return ngoCategory == category.toLowerCase();
        }).toList();
        print('After category filter: ${ngos.length}');
      }

      // Apply location filter
      if (location != null && location.isNotEmpty) {
        ngos = ngos.where((ngo) {
          final ngoLocation = (ngo['location'] ?? '').toString().toLowerCase();
          final ngoState = (ngo['state'] ?? '').toString().toLowerCase();
          final ngoCity = (ngo['city'] ?? '').toString().toLowerCase();
          final searchLoc = location.toLowerCase();
          return ngoLocation.contains(searchLoc) ||
              ngoState.contains(searchLoc) ||
              ngoCity.contains(searchLoc);
        }).toList();
        print('After location filter: ${ngos.length}');
      }

      // Apply date range filter
      if (startDate != null || endDate != null) {
        ngos = ngos.where((ngo) {
          final createdAt = ngo['createdAt'];
          if (createdAt == null) return false;

          DateTime? date;
          if (createdAt is Timestamp) {
            date = createdAt.toDate();
          } else if (createdAt is DateTime) {
            date = createdAt;
          }

          if (date == null) return false;

          if (startDate != null && date.isBefore(startDate)) return false;
          if (endDate != null && date.isAfter(endDate)) return false;

          return true;
        }).toList();
        print('After date filter: ${ngos.length}');
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        ngos = ngos.where((ngo) {
          final ngoName = (ngo['ngoName'] ?? '').toString().toLowerCase();
          final orgName =
              (ngo['organizationName'] ?? '').toString().toLowerCase();
          final email = (ngo['email'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();
          return ngoName.contains(query) ||
              orgName.contains(query) ||
              email.contains(query);
        }).toList();
        print('After search filter: ${ngos.length}');
      }

      _setLoading(false);
      print('Final filtered NGOs: ${ngos.length}');
      print('========================================');
      return ngos;
    } catch (e) {
      print('Error fetching filtered NGOs: $e');
      _setError('Failed to fetch filtered NGOs: ${e.toString()}');
      _setLoading(false);
      return [];
    }
  }

  // Get NGOs approaching renewal (1 year from approval)
  Future<List<Map<String, dynamic>>> getNGOsApproachingRenewal() async {
    try {
      final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
      final threeMonthsFromNow = DateTime.now().add(Duration(days: 90));

      final snapshot = await _firestore
          .collection('ngo_proposals')
          .where('status', isEqualTo: 'approved')
          .where('approvedAt', isGreaterThanOrEqualTo: oneYearAgo)
          .where('approvedAt', isLessThanOrEqualTo: threeMonthsFromNow)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _setError('Failed to fetch NGOs approaching renewal: ${e.toString()}');
      return [];
    }
  }

  // Update NGO follow-up status
  Future<bool> updateFollowUpStatus({
    required String ngoId,
    required String followUpStatus,
    String? followUpNotes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('ngo_proposals').doc(ngoId).update({
        'followUpStatus': followUpStatus,
        'followUpNotes': followUpNotes,
        'followUpUpdatedAt': FieldValue.serverTimestamp(),
        'followUpUpdatedBy': _auth.currentUser?.email,
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update follow-up status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get validation statistics
  Future<Map<String, dynamic>> getValidationStatistics() async {
    try {
      final snapshot = await _firestore.collection('ngo_proposals').get();

      int pending = 0;
      int underReview = 0;
      int approved = 0;
      int rejected = 0;
      int needsFollowUp = 0;
      int total = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';
        final followUpStatus = data['followUpStatus'] as String? ?? '';

        switch (status.toLowerCase()) {
          case 'pending':
            pending++;
            break;
          case 'under_review':
            underReview++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }

        if (followUpStatus.toLowerCase() == 'needs_follow_up') {
          needsFollowUp++;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'underReview': underReview,
        'approved': approved,
        'rejected': rejected,
        'needsFollowUp': needsFollowUp,
        'approvalRate':
            total > 0 ? (approved / total * 100).toStringAsFixed(1) : '0.0',
      };
    } catch (e) {
      _setError('Failed to fetch validation statistics: ${e.toString()}');
      return {
        'total': 0,
        'pending': 0,
        'underReview': 0,
        'approved': 0,
        'rejected': 0,
        'needsFollowUp': 0,
        'approvalRate': '0.0',
      };
    }
  }
}
