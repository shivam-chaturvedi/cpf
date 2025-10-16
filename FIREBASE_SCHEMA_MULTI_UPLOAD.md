# Firebase Schema Documentation - Multi-File Upload Support

## Overview
This document describes the Firebase/Firestore schema for NGO document uploads with support for multiple files per document type.

## Updated Features (Latest)

### 1. **Financial Year Labels**
- Changed from specific years (e.g., "2021-22", "2022-23") to generic labels
- Now uses: **"F.Y. 1"**, **"F.Y. 2"**, **"F.Y. 3"**

### 2. **Multiple File Uploads**
- Each document type now supports unlimited file uploads
- Structure changed from single file (Map) to multiple files (List of Maps)

---

## Firestore Collection Structure

### `ngo_proposals/{ngoId}`
Main NGO profile document.

```json
{
  "ngoName": "string",
  "email": "string",
  "phone": "string",
  "status": "pending | under_review | approved | rejected | verified",
  "logo": {
    "filename": "string",
    "download_url": "string",
    "file_path": "string",
    "file_size": number,
    "original_name": "string",
    "uploaded_at": "ISO8601 string"
  },
  "profileComplete": boolean,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
  // ... other NGO fields
}
```

---

## `ngo_proposals/{ngoId}/yearly_data/{financialYear}`
Yearly financial data submissions with multiple file support.

### Document Structure

```json
{
  "financialYear": "F.Y. 1 | F.Y. 2 | F.Y. 3",
  "documents": {
    "audit_report": [
      {
        "filename": "audit_2023_xyz123.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/audit_report/...",
        "file_size": 2048576,
        "original_name": "Audit_Statement_2023.pdf",
        "uploaded_at": "2024-01-15T10:30:00Z"
      },
      {
        "filename": "audit_2022_abc456.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/audit_report/...",
        "file_size": 1945600,
        "original_name": "Audit_Statement_2022.pdf",
        "uploaded_at": "2024-01-15T10:32:00Z"
      },
      {
        "filename": "audit_2021_def789.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/audit_report/...",
        "file_size": 1856000,
        "original_name": "Audit_Statement_2021.pdf",
        "uploaded_at": "2024-01-15T10:35:00Z"
      }
    ],
    "activity_report": [
      {
        "filename": "activity_report_xyz.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/activity_report/...",
        "file_size": 3145728,
        "original_name": "Annual_Activity_Report.pdf",
        "uploaded_at": "2024-01-15T11:00:00Z"
      }
    ],
    "itr_acknowledgment": [
      {
        "filename": "itr_ack_2023.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/itr_acknowledgment/...",
        "file_size": 512000,
        "original_name": "ITR_Acknowledgment_2023.pdf",
        "uploaded_at": "2024-01-15T11:15:00Z"
      }
    ],
    "utilization_certificate": [
      {
        "filename": "uc_certificate.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/utilization_certificate/...",
        "file_size": 1024000,
        "original_name": "Utilization_Certificate.pdf",
        "uploaded_at": "2024-01-15T11:30:00Z"
      }
    ],
    "annual_return": [
      {
        "filename": "annual_return_2023.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/annual_return/...",
        "file_size": 768000,
        "original_name": "Annual_Return_2023.pdf",
        "uploaded_at": "2024-01-15T12:00:00Z"
      },
      {
        "filename": "annual_return_2022.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/annual_return/...",
        "file_size": 745000,
        "original_name": "Annual_Return_2022.pdf",
        "uploaded_at": "2024-01-15T12:05:00Z"
      }
    ],
    "tan_form_24q": [
      {
        "filename": "form_24q_q1.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/tan_form_24q/...",
        "file_size": 256000,
        "original_name": "Form_24Q_Q1_2023.pdf",
        "uploaded_at": "2024-01-15T12:30:00Z"
      },
      {
        "filename": "form_24q_q2.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/tan_form_24q/...",
        "file_size": 258000,
        "original_name": "Form_24Q_Q2_2023.pdf",
        "uploaded_at": "2024-01-15T12:32:00Z"
      }
    ],
    "tan_form_26q": [
      {
        "filename": "form_26q_q1.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/tan_form_26q/...",
        "file_size": 312000,
        "original_name": "Form_26Q_Q1_2023.pdf",
        "uploaded_at": "2024-01-15T13:00:00Z"
      }
    ],
    "tan_tds_related": [
      {
        "filename": "tds_challan_1.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/tan_tds_related/...",
        "file_size": 128000,
        "original_name": "TDS_Challan_Jan_2023.pdf",
        "uploaded_at": "2024-01-15T13:30:00Z"
      },
      {
        "filename": "tds_challan_2.pdf",
        "download_url": "https://supabase.co/storage/...",
        "file_path": "ngo_documents/{ngoId}/tan_tds_related/...",
        "file_size": 132000,
        "original_name": "TDS_Challan_Feb_2023.pdf",
        "uploaded_at": "2024-01-15T13:32:00Z"
      }
    ]
  },
  "documentCategoryCount": 8,
  "totalFileCount": 15,
  "submittedAt": Timestamp,
  "submittedBy": "ngo@example.com",
  "status": "submitted",
  "storageType": "supabase"
}
```

---

## Document Types Supported

### Existing Document Types
1. **audit_report** - Audit Statements (supports 3 years of statements)
2. **activity_report** - Activity Reports
3. **itr_acknowledgment** - ITR Acknowledgments
4. **utilization_certificate** - Utilization Certificates

### New Document Types (Added)
5. **annual_return** - Proof of Filing Annual Return (multiple uploads)
6. **tan_form_24q** - TAN Form 24Q receipts (multiple uploads)
7. **tan_form_26q** - TAN Form 26Q receipts (multiple uploads)
8. **tan_tds_related** - TDS-Related Documents (multiple uploads)

---

## File Metadata Structure

Each file in the array contains:

```typescript
{
  filename: string,        // Unique filename generated by system
  download_url: string,    // Public URL for downloading/viewing
  file_path: string,       // Storage path in Supabase
  file_size: number,       // File size in bytes
  original_name: string,   // Original filename uploaded by user
  uploaded_at: string      // ISO8601 timestamp
}
```

---

## `ngo_proposals/{ngoId}/proposals/{proposalId}`
NGO funding proposals (single file per proposal).

```json
{
  "title": "string",
  "description": "string",
  "requestedAmount": number,
  "status": "submitted | approved | rejected",
  "document": {
    "filename": "string",
    "download_url": "string",
    "file_path": "string",
    "file_size": number,
    "original_name": "string",
    "uploaded_at": "ISO8601 string"
  },
  "hasDocument": true,
  "storageType": "supabase",
  "submittedAt": Timestamp,
  "submittedBy": "string",
  "ngoName": "string",
  "ngoId": "string"
}
```

---

## Migration Notes

### Old Structure (Single File)
```json
{
  "documents": {
    "audit_report": {
      "filename": "...",
      "download_url": "..."
    }
  }
}
```

### New Structure (Multiple Files)
```json
{
  "documents": {
    "audit_report": [
      {
        "filename": "...",
        "download_url": "..."
      },
      {
        "filename": "...",
        "download_url": "..."
      }
    ]
  }
}
```

### Backward Compatibility
The admin dashboard is designed to handle both structures:
- If `value` is a `Map`: treats as single file (old structure)
- If `value` is a `List`: treats as multiple files (new structure)

---

## Storage Rules (Supabase)

Files are stored in Supabase Storage under:
```
ngo_documents/{ngoId}/{documentType}/{uniqueFilename}
```

Example:
```
ngo_documents/abc123xyz/audit_report/audit_2023_uuid.pdf
ngo_documents/abc123xyz/tan_form_24q/form24q_q1_uuid.pdf
```

---

## Validation Rules

### File Types Allowed
- PDF (`.pdf`)
- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)

### File Size Limits
- Regular documents: 50 MB
- Audit reports: 50 MB (configurable in `AppConstants`)
- Logo files: 5 MB

---

## Query Examples

### Get all yearly data for an NGO
```dart
FirebaseFirestore.instance
  .collection('ngo_proposals')
  .doc(ngoId)
  .collection('yearly_data')
  .orderBy('submittedAt', descending: true)
  .snapshots()
```

### Get specific financial year data
```dart
FirebaseFirestore.instance
  .collection('ngo_proposals')
  .doc(ngoId)
  .collection('yearly_data')
  .doc('F.Y. 1')
  .get()
```

### Access multiple audit reports
```dart
final yearlyDataDoc = await FirebaseFirestore.instance
  .collection('ngo_proposals')
  .doc(ngoId)
  .collection('yearly_data')
  .doc('F.Y. 1')
  .get();

final data = yearlyDataDoc.data();
final documents = data?['documents'] as Map<String, dynamic>;
final auditReports = documents['audit_report'] as List<dynamic>;

for (var report in auditReports) {
  final reportData = report as Map<String, dynamic>;
  print('File: ${reportData['original_name']}');
  print('URL: ${reportData['download_url']}');
}
```

---

## Admin Dashboard Changes

The admin dashboard has been updated to:
1. Display all files when viewing NGO documents
2. Handle both old (single file) and new (multiple files) structures
3. Show correct file counts: `totalFileCount` instead of just `documentCount`
4. Support downloading individual files from multi-file categories
5. Properly display new document types (Annual Return, TAN Forms)

---

## Summary of Changes

✅ Financial years changed to F.Y. 1, F.Y. 2, F.Y. 3  
✅ All document types support multiple file uploads  
✅ New fields added: `documentCategoryCount`, `totalFileCount`  
✅ New document types: `annual_return`, `tan_form_24q`, `tan_form_26q`, `tan_tds_related`  
✅ Admin dashboard backward compatible with old structure  
✅ UI shows file lists with individual delete/download options  

---

**Last Updated:** January 2025  
**Schema Version:** 2.0 (Multi-File Support)

