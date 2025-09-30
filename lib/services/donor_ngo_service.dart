import 'package:cloud_firestore/cloud_firestore.dart';

class DonorNGOService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Assign NGOs to a donor
  static Future<bool> assignNGOsToDonor({
    required String donorId,
    required List<String> ngoIds,
    required String adminId,
  }) async {
    try {
      await _firestore.collection('donor_ngo_assignments').doc(donorId).set({
        'donorId': donorId,
        'assignedNGOs': ngoIds,
        'assignedBy': adminId,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error assigning NGOs to donor: $e');
      return false;
    }
  }

  /// Get NGOs assigned to a donor
  static Future<List<String>> getAssignedNGOs(String donorId) async {
    try {
      final doc = await _firestore
          .collection('donor_ngo_assignments')
          .doc(donorId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['assignedNGOs'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting assigned NGOs: $e');
      return [];
    }
  }

  /// Get all donor-NGO assignments
  static Future<List<Map<String, dynamic>>> getAllAssignments() async {
    try {
      final snapshot = await _firestore
          .collection('donor_ngo_assignments')
          .orderBy('assignedAt', descending: true)
          .get();

      List<Map<String, dynamic>> assignments = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        assignments.add(data);
      }
      return assignments;
    } catch (e) {
      print('Error getting all assignments: $e');
      return [];
    }
  }

  /// Get donor details for assignment
  static Future<Map<String, dynamic>?> getDonorDetails(String donorId) async {
    try {
      // Try donors collection first
      var doc = await _firestore.collection('donors').doc(donorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['collection'] = 'donors';
        return data;
      }

      // Try donor_profiles collection
      doc = await _firestore.collection('donor_profiles').doc(donorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['collection'] = 'donor_profiles';
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting donor details: $e');
      return null;
    }
  }

  /// Get NGO details for assignment
  static Future<Map<String, dynamic>?> getNGODetails(String ngoId) async {
    try {
      final doc = await _firestore.collection('ngo_proposals').doc(ngoId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting NGO details: $e');
      return null;
    }
  }

  /// Update NGO assignment for a donor
  static Future<bool> updateNGOAssignment({
    required String donorId,
    required List<String> ngoIds,
    required String adminId,
  }) async {
    try {
      await _firestore.collection('donor_ngo_assignments').doc(donorId).update({
        'assignedNGOs': ngoIds,
        'updatedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating NGO assignment: $e');
      return false;
    }
  }

  /// Remove NGO assignment
  static Future<bool> removeNGOAssignment(String donorId) async {
    try {
      await _firestore.collection('donor_ngo_assignments').doc(donorId).delete();
      return true;
    } catch (e) {
      print('Error removing NGO assignment: $e');
      return false;
    }
  }

  /// Get assignment statistics
  static Future<Map<String, int>> getAssignmentStats() async {
    try {
      final assignmentsSnapshot = await _firestore
          .collection('donor_ngo_assignments')
          .get();
      
      final donorsSnapshot = await _firestore.collection('donors').get();
      final donorProfilesSnapshot = await _firestore.collection('donor_profiles').get();
      final ngosSnapshot = await _firestore.collection('ngo_proposals').get();

      int totalDonors = donorsSnapshot.docs.length + donorProfilesSnapshot.docs.length;
      int totalNGOs = ngosSnapshot.docs.length;
      int assignedDonors = assignmentsSnapshot.docs.length;
      int totalAssignments = 0;

      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        final assignedNGOs = List<String>.from(data['assignedNGOs'] ?? []);
        totalAssignments += assignedNGOs.length;
      }

      return {
        'totalDonors': totalDonors,
        'totalNGOs': totalNGOs,
        'assignedDonors': assignedDonors,
        'totalAssignments': totalAssignments,
      };
    } catch (e) {
      print('Error getting assignment stats: $e');
      return {
        'totalDonors': 0,
        'totalNGOs': 0,
        'assignedDonors': 0,
        'totalAssignments': 0,
      };
    }
  }
}
