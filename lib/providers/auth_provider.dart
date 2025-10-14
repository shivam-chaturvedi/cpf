import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { ngo, admin, donor }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserRole? _userRole;
  bool _isLoading = false;
  String? _error;
  bool? _profileComplete;

  // Getters
  User? get user => _user;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool? get profileComplete => _profileComplete;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _determineUserRole();
      await _checkProfileCompletion();
    } else {
      _userRole = null;
      _profileComplete = null;
    }
    notifyListeners();
  }

  Future<void> _determineUserRole() async {
    if (_user == null) return;

    try {
      // First check if user is an admin
      final adminDoc =
          await _firestore.collection('admins').doc(_user!.uid).get();

      if (adminDoc.exists && adminDoc.data()?['role'] == 'admin') {
        _userRole = UserRole.admin;
        return;
      }

      // Check if user is a donor in either collection
      final donorProfilesDoc =
          await _firestore.collection('donor_profiles').doc(_user!.uid).get();

      final donorsDoc =
          await _firestore.collection('donors').doc(_user!.uid).get();

      if (donorProfilesDoc.exists || donorsDoc.exists) {
        _userRole = UserRole.donor;
      } else {
        // Check if user is an NGO
        final ngoDoc =
            await _firestore.collection('ngo_proposals').doc(_user!.uid).get();

        if (ngoDoc.exists) {
          _userRole = UserRole.ngo;
        } else {
          // Default to NGO if no specific role found
          _userRole = UserRole.ngo;
        }
      }
    } catch (e) {
      print('Error determining user role: $e');
      _userRole = null;
    }
  }

  Future<void> _checkProfileCompletion() async {
    if (_user == null || _userRole == UserRole.admin) {
      _profileComplete = true;
      return;
    }

    try {
      final doc =
          await _firestore.collection('ngo_proposals').doc(_user!.uid).get();

      if (doc.exists) {
        _profileComplete = doc.data()?['profileComplete'] ?? false;
      } else {
        _profileComplete = false;
      }
    } catch (e) {
      print('Error checking profile completion: $e');
      _profileComplete = false;
    }
  }

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

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    if (_user == null) return false;
    if (_userRole == UserRole.admin) return true;

    try {
      final doc =
          await _firestore.collection('ngo_proposals').doc(_user!.uid).get();

      if (doc.exists) {
        return doc.data()?['profileComplete'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // NGO Registration with Firebase Auth (REMOVED - not needed with new flow)
  // Now registration is handled directly in NGORegistrationPage

  // NGO Login
  Future<bool> loginNGO({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check profile completion after login
      await _checkProfileCompletion();

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Login failed. Please try again.');
      return false;
    }
  }

  // Admin Login
  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Try to sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user is an admin
      final adminDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        // Not an admin account
        await _auth.signOut();
        _setError('This account does not have admin privileges');
        _setLoading(false);
        return false;
      }

      // Update last login timestamp
      await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Admin login failed. Please try again.');
      return false;
    }
  }

  // Create initial admin account (should be called once)
  Future<bool> createAdminAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Create user with Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store admin role in Firestore
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create admin account: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _userRole = null;
    _error = null;
    _profileComplete = null;
    notifyListeners();
  }

  // Password Reset
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to send password reset email.');
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Donor management methods
  Future<List<Map<String, dynamic>>> getAllDonors() async {
    try {
      // Try both collections to ensure we get all donors
      final donorsSnapshot = await _firestore
          .collection('donors')
          .orderBy('createdAt', descending: true)
          .get();

      final donorProfilesSnapshot = await _firestore
          .collection('donor_profiles')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> allDonors = [];

      // Add donors from 'donors' collection
      for (final doc in donorsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'donors';
        allDonors.add(data);
      }

      // Add donors from 'donor_profiles' collection
      for (final doc in donorProfilesSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'donor_profiles';
        allDonors.add(data);
      }

      // Sort by creation date
      allDonors.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return allDonors;
    } catch (e) {
      print('Error fetching donors: $e');
      return [];
    }
  }

  Future<bool> updateDonorStatus({
    required String donorId,
    required String status,
    String? adminComments,
    String? collection,
  }) async {
    try {
      // Determine which collection to update
      String collectionName = collection ?? 'donors';

      await _firestore.collection(collectionName).doc(donorId).update({
        'status': status,
        'adminComments': adminComments,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating donor status: $e');
      return false;
    }
  }

  Future<Map<String, int>> getDonorStatistics() async {
    try {
      // Get statistics from both collections
      final donorsSnapshot = await _firestore.collection('donors').get();
      final donorProfilesSnapshot =
          await _firestore.collection('donor_profiles').get();

      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int total =
          donorsSnapshot.docs.length + donorProfilesSnapshot.docs.length;

      // Count from 'donors' collection
      for (final doc in donorsSnapshot.docs) {
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

      // Count from 'donor_profiles' collection
      for (final doc in donorProfilesSnapshot.docs) {
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
        'total': total,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    } catch (e) {
      print('Error fetching donor statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };
    }
  }
}
