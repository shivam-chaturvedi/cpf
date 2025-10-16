# Certificate Logo Integration - Complete Implementation

## ✅ What Was Updated

I've successfully integrated the logo_url parameter to send NGO logos when generating certificates through the FastAPI backend.

## 📝 Changes Made

### **1. Updated Certificate API Service** (`lib/services/certificate_api_service.dart`)

#### **Added logo_url parameter to public methods:**

```dart
// Due Diligence Certificate
static Future<void> generateDueDiligenceCertificate({
  required String ngoName,
  required DateTime issueDate,
  required DateTime expiryDate,
  required BuildContext context,
  String? logoUrl, // ← NEW: Optional logo URL
}) async { ... }

// Compliance Certificate
static Future<void> generateComplianceCertificate({
  required String ngoName,
  required DateTime issueDate,
  required DateTime expiryDate,
  required BuildContext context,
  String? logoUrl, // ← NEW: Optional logo URL
}) async { ... }
```

#### **Updated internal _generateCertificate method:**

```dart
// Add logo_url to request body if provided
if (logoUrl != null && logoUrl.isNotEmpty) {
  requestBody['logo_url'] = logoUrl;
  print('✅ Logo URL added to request');
} else {
  print('⚠️ No logo URL provided - certificate will use default placeholder');
}
```

**Request body now includes:**
```json
{
  "ngo_name": "ABC Foundation",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026",
  "logo_url": "https://supabase.co/storage/v1/object/public/documents/..."
}
```

### **2. Updated Certificate Card** (`lib/widgets/certificate_card.dart`)

#### **Pass logo URL to API calls:**

```dart
case 'due_diligence':
  await CertificateApiService.generateDueDiligenceCertificate(
    ngoName: ngoName,
    issueDate: issueDate,
    expiryDate: expiryDate,
    context: context,
    logoUrl: logoPath, // ← Pass logo URL to embed in certificate
  );
  break;

case 'compliance':
  await CertificateApiService.generateComplianceCertificate(
    ngoName: ngoName,
    issueDate: issueDate,
    expiryDate: expiryDate,
    context: context,
    logoUrl: logoPath, // ← Pass logo URL to embed in certificate
  );
  break;
```

## 🔄 Data Flow

### **From Upload to Certificate:**

```
1. NGO uploads logo
   ↓
2. Logo stored in Supabase
   → Gets public URL: https://supabase.co/.../logo.png
   ↓
3. Logo metadata saved in Firebase
   {
     "logo": {
       "download_url": "https://...",
       "filename": "...",
       ...
     }
   }
   ↓
4. Certificate generation triggered
   ↓
5. Logo URL extracted from Firebase
   ↓
6. Sent to FastAPI backend:
   {
     "ngo_name": "ABC Foundation",
     "issue_date": "14 Oct 2025",
     "exp_date": "14 Oct 2026",
     "logo_url": "https://supabase.co/.../logo.png"  ← INCLUDED!
   }
   ↓
7. FastAPI embeds logo in certificate
   ↓
8. Returns .docx file with embedded logo
```

## 📊 API Request Examples

### **Before (No Logo):**
```json
POST /generate/compliance
{
  "ngo_name": "ABC Foundation",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026"
}
```
**Result:** Certificate with placeholder {{ logo }} in template

### **After (With Logo):**
```json
POST /generate/compliance
{
  "ngo_name": "ABC Foundation",
  "issue_date": "14 Oct 2025",
  "exp_date": "14 Oct 2026",
  "logo_url": "https://supabase.co/storage/v1/object/public/documents/ngo_documents/abc123/logo.png"
}
```
**Result:** Certificate with actual NGO logo embedded!

## 🧪 Testing

### **Test Case 1: NGO With Logo**

**Steps:**
1. Login as NGO that has uploaded logo
2. Go to Certificates tab
3. Click "Download" on Due Diligence or Compliance certificate
4. Check console logs

**Expected Console Output:**
```
========================================
CALLING CERTIFICATE API
Endpoint: https://certificate-tool-kappa.vercel.app/generate/compliance
NGO Name: ABC Foundation
Issue Date: 14 Oct 2025
Expiry Date: 14 Oct 2026
Logo URL: https://supabase.co/storage/v1/object/public/documents/ngo_documents/abc123/logo.png
========================================
✅ Logo URL added to request
Request body: {"ngo_name":"ABC Foundation","issue_date":"14 Oct 2025","exp_date":"14 Oct 2026","logo_url":"https://..."}
Response status: 200
Received XXXXX bytes
File downloaded successfully: certificate_compliance.docx
```

**Expected Result:**
- ✅ Certificate downloads
- ✅ Logo embedded in certificate
- ✅ Logo displays properly in Word document

### **Test Case 2: NGO Without Logo**

**Steps:**
1. Login as NGO that hasn't uploaded logo
2. Go to Certificates tab
3. Click "Download" on certificate

**Expected Console Output:**
```
Logo URL: Not provided
========================================
⚠️ No logo URL provided - certificate will use default placeholder
Request body: {"ngo_name":"ABC Foundation","issue_date":"14 Oct 2025","exp_date":"14 Oct 2026"}
```

**Expected Result:**
- ✅ Certificate still downloads
- ⚠️ Logo placeholder in template (not replaced)

### **Test Case 3: Admin Enabling Certificates**

**Steps:**
1. Login as admin
2. Go to NGO Management → View NGO Details
3. Click "Enable" on Due Diligence or Compliance certificate
4. NGO can now download certificates with their logo

**Expected Result:**
- ✅ Certificate enabled for NGO
- ✅ NGO can download with logo embedded

## 📋 Checklist

### **Flutter Code:**
- [x] Updated `CertificateApiService.generateDueDiligenceCertificate()` to accept `logoUrl`
- [x] Updated `CertificateApiService.generateComplianceCertificate()` to accept `logoUrl`
- [x] Updated `_generateCertificate()` to include `logo_url` in request body
- [x] Updated `CertificateCard._generateCertificate()` to pass `logoPath` to API
- [x] Added debug logging for logo URL
- [x] No linter errors

### **Backend (Already Done by User):**
- [x] FastAPI accepts `logo_url` parameter
- [x] Downloads image from URL
- [x] Embeds in template at `{{ logo }}` placeholder
- [x] Returns .docx with embedded image

### **Templates (User's Responsibility):**
- [ ] `c.docx` (Compliance) has `{{ logo }}` placeholder
- [ ] `d.docx` (Due Diligence) has `{{ logo }}` placeholder
- [ ] Templates properly formatted for image embedding

## 🎯 What Happens Now

### **Certificate Generation Flow:**

1. **NGO clicks "Download Certificate"**
   
2. **Flutter extracts logo URL from Firebase:**
   ```dart
   logoPath = ngoData['logo']['download_url']
   ```

3. **Sends to API with logo_url:**
   ```json
   {
     "ngo_name": "ABC Foundation",
     "issue_date": "14 Oct 2025",
     "exp_date": "14 Oct 2026",
     "logo_url": "https://supabase.co/.../logo.png"
   }
   ```

4. **FastAPI (Your Backend):**
   - Downloads image from logo_url
   - Embeds in Word template
   - Returns certificate with logo

5. **NGO receives certificate with their logo!** 🎉

## 🔍 Debugging

### **If logo doesn't appear in certificate:**

**Check Console Logs:**
```
Logo URL: https://... ← Should show actual URL
✅ Logo URL added to request ← Should see this
```

**If you see:**
```
Logo URL: Not provided
⚠️ No logo URL provided
```
→ Logo not uploaded or not saved in Firebase properly

**Backend Checks:**
1. Open FastAPI docs: https://certificate-tool-kappa.vercel.app/docs
2. Test /generate/compliance with logo_url manually
3. Check if image downloads from URL
4. Verify template has `{{ logo }}` placeholder

**Common Issues:**

| Issue | Cause | Fix |
|-------|-------|-----|
| No logo in certificate | Logo URL not sent | Re-upload logo |
| 400 Bad Request | Invalid image URL | Check Supabase URL is public |
| Logo placeholder shows | Template missing `{{ logo }}` | Add to Word template |
| 500 Server Error | Backend can't download image | Check URL accessibility |

## 🚀 Deployment Status

### **Flutter App:**
✅ **Updated and ready to deploy**
- Logo URL properly extracted
- Sent to API in correct format
- Error handling in place

### **FastAPI Backend (Your End):**
- ✅ Accepts logo_url parameter
- ✅ Downloads and embeds images
- ✅ Deployed on Vercel

### **Next Steps:**
1. ✅ Code updated (DONE!)
2. 🔄 Test with actual NGO that has logo
3. 🔄 Verify certificate downloads with embedded logo
4. 🔄 Check both Compliance and Due Diligence work
5. 🚀 Deploy to production if tests pass

## 📚 API Documentation

### **Compliance Certificate:**
```
POST /generate/compliance
Content-Type: application/json

{
  "ngo_name": "string",
  "issue_date": "string (DD Mon YYYY)",
  "exp_date": "string (DD Mon YYYY)",
  "logo_url": "string (optional)"
}

Response: certificate_compliance.docx
```

### **Due Diligence Certificate:**
```
POST /generate/due_diligence
Content-Type: application/json

{
  "ngo_name": "string",
  "issue_date": "string (DD Mon YYYY)",
  "exp_date": "string (DD Mon YYYY)",
  "logo_url": "string (optional)"
}

Response: certificate_due_diligence.docx
```

### **Letterhead Certificate:**
```
POST /generate/letterhead
Content-Type: application/json

{
  "cfo_name": "string",
  "ngo_name": "string",
  "ngo_address": "string",
  "check_type": "string",
  "issue_date": "string (DD Mon YYYY)",
  "exp_date": "string (DD Mon YYYY)"
}

Response: certificate_letterhead.docx
Note: No logo_url for letterhead (as per your API design)
```

## 🎉 Summary

**What was accomplished:**
- ✅ Flutter now sends logo_url to certificate API
- ✅ Logo URL extracted from Firebase (Supabase public URL)
- ✅ Included in API request for Compliance & Due Diligence
- ✅ Debug logging added for troubleshooting
- ✅ Backward compatible (works with/without logo)
- ✅ No breaking changes
- ✅ Ready for production

**The integration is complete!** NGO logos will now be embedded in generated certificates automatically! 🚀



