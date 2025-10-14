# Certificate API Integration Documentation

## Overview

This document describes the integration of the Certificate Generation API hosted at `https://certificate-tool-kappa.vercel.app` into the NGO Dashboard for generating certificates and letterheads.

## Changes Made

### 1. New Service: `certificate_api_service.dart`

**Location:** `lib/services/certificate_api_service.dart`

This service handles all communication with the certificate generation API. It provides three main methods:

- `generateDueDiligenceCertificate()` - Generates Due Diligence certificates
- `generateComplianceCertificate()` - Generates Compliance certificates  
- `generateLetterheadCertificate()` - Generates Letterhead certificates

#### Key Features:

- **API Integration**: Makes HTTP POST requests to the certificate API
- **Date Formatting**: Formats dates as "DD Mon YYYY" (e.g., "14 Oct 2025") as required by the API
- **Error Handling**: Properly handles API errors and network failures
- **Web Download**: Uses browser download functionality for web platform
- **Logging**: Comprehensive logging for debugging

#### API Endpoints Used:

1. **Compliance Certificate**
   - Endpoint: `POST /generate/compliance`
   - Request Body:
     ```json
     {
       "ngo_name": "NGO Name",
       "issue_date": "14 Oct 2025",
       "exp_date": "14 Oct 2026"
     }
     ```
   - Response: `.docx` file download

2. **Due Diligence Certificate**
   - Endpoint: `POST /generate/due_diligence`
   - Request Body:
     ```json
     {
       "ngo_name": "NGO Name",
       "issue_date": "14 Oct 2025",
       "exp_date": "14 Oct 2026"
     }
     ```
   - Response: `.docx` file download

3. **Letterhead Certificate**
   - Endpoint: `POST /generate/letterhead`
   - Request Body:
     ```json
     {
       "cfo_name": "Chief Functionary Name",
       "ngo_name": "NGO Name",
       "ngo_address": "NGO Address",
       "check_type": "Compliance Check",
       "issue_date": "14 Oct 2025",
       "exp_date": "14 Oct 2026"
     }
     ```
   - Response: `.docx` file download

### 2. Updated Widget: `certificate_card.dart`

**Location:** `lib/widgets/certificate_card.dart`

Updated the `_generateCertificate()` method to use `CertificateApiService` instead of the local PDF generator.

**Changes:**
- Replaced `CertificateGenerator` calls with `CertificateApiService` calls
- Removed dependency on local PDF generation
- Simplified certificate generation logic
- Maintained all existing UI and error handling

### 3. Updated Dependencies: `pubspec.yaml`

Added the `http` package for making API requests:
```yaml
http: ^1.1.0
```

## How It Works

### Certificate Download Flow

1. **User Action**: User clicks "Download" button on a certificate card
2. **Loading Dialog**: Shows a loading dialog to the user
3. **API Request**: `CertificateApiService` makes a POST request to the appropriate API endpoint
4. **Response Processing**: 
   - On success (200): Receives `.docx` file bytes
   - On error: Parses error message from API
5. **File Download**: 
   - **Web**: Triggers browser download using HTML5 download attribute
   - **Mobile/Desktop**: Not yet implemented (throws UnimplementedError)
6. **User Feedback**: Shows success/error message via SnackBar
7. **Dialog Closure**: Closes the loading dialog

### Certificate Types

1. **Due Diligence Certificate**
   - Certifies NGO has completed due diligence process
   - Requires: NGO name, issue date, expiry date

2. **Compliance Certificate**
   - Verifies NGO compliance with regulations
   - Requires: NGO name, issue date, expiry date

3. **Letterhead Certificate**
   - Authorizes official letterhead use
   - Requires: CFO name, NGO name, NGO address, check type, issue date, expiry date

## Testing

### How to Test

1. **Setup**:
   - Ensure you're running the app in web mode (`flutter run -d chrome`)
   - Login as an NGO with approved status

2. **Navigate to Certificates**:
   - Go to NGO Dashboard
   - Click on "Certificates" tab

3. **Download Certificate**:
   - Click "Download" button on any enabled certificate
   - Verify loading dialog appears
   - Verify certificate downloads as `.docx` file
   - Open the downloaded file to verify content

### Expected Behavior

- ✅ Loading dialog appears during generation
- ✅ Certificate downloads automatically in browser
- ✅ Success message shows in green SnackBar
- ✅ Downloaded file is a valid `.docx` document
- ✅ Certificate contains correct NGO information

### Error Scenarios

1. **Network Error**:
   - Shows error message: "Failed to generate certificate"
   - Error is logged to console

2. **API Error**:
   - Shows specific error message from API
   - Example: "Field 'ngo_name' is required"

3. **Missing Fields**:
   - API returns 400 Bad Request
   - Error message displayed to user

## Platform Support

### ✅ Supported Platforms

- **Web**: Fully supported with browser download

### ⚠️ Partial Support

- **Mobile (iOS/Android)**: API integration works, but file download needs implementation
- **Desktop (Windows/macOS/Linux)**: API integration works, but file download needs implementation

### Future Enhancements

To support mobile and desktop platforms, implement file download using:
- `path_provider` for getting downloads directory
- `share_plus` for sharing the downloaded file
- `open_file` for opening the file automatically

## Troubleshooting

### Common Issues

1. **Certificate not downloading**:
   - Check browser console for errors
   - Verify API is accessible: `https://certificate-tool-kappa.vercel.app`
   - Check network connectivity

2. **API returns error**:
   - Verify all required fields are provided
   - Check date format is correct
   - Review API logs

3. **CORS errors**:
   - Ensure API has CORS enabled for your domain
   - Check browser console for CORS-related errors

## API Configuration

The API base URL is configured in `certificate_api_service.dart`:

```dart
static const String _baseUrl = 'https://certificate-tool-kappa.vercel.app';
```

To change the API URL, update this constant.

## Security Considerations

- API requests are made over HTTPS
- No sensitive data is stored locally
- Certificates are downloaded directly to user's device
- No authentication tokens are required for public API

## Maintenance

### Updating API Endpoints

If API endpoints change, update the endpoint paths in `CertificateApiService`:
- `_generateCertificate()` for compliance and due diligence
- `_generateLetterheadCertificate()` for letterhead

### Changing Date Format

The API expects dates in "DD Mon YYYY" format. To change this, update the `_formatDate()` method in `CertificateApiService`.

### Adding New Certificate Types

To add a new certificate type:
1. Add a new method in `CertificateApiService`
2. Update `certificate_card.dart` to handle the new type
3. Add a new case in the switch statement in `_generateCertificate()`

## Support

For API-related issues, contact the API maintainer or check the API documentation at:
`https://certificate-tool-kappa.vercel.app/docs` (if available)

---

**Last Updated**: October 14, 2025
**Version**: 1.0.0

