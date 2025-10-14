# Admin Setup Guide

## Overview

The admin authentication system has been migrated from hardcoded credentials to Firebase Authentication with proper session persistence. This guide explains how to set up and use the admin system.

## Key Features

✅ **Firebase Authentication** - Admin credentials stored securely in Firebase
✅ **Session Persistence** - Admin stays logged in after page refresh
✅ **Role-Based Access** - Proper role verification via Firestore
✅ **Security Rules** - Comprehensive Firestore security rules
✅ **Multiple Admins** - Support for multiple admin accounts

## Initial Setup

### Step 1: Deploy Firebase Security Rules

Before creating admin accounts, deploy the updated Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

This will deploy the rules from `firestore.rules` which includes:
- Admin collection security
- NGO proposals access control
- Donor profiles access control
- Role-based permissions

### Step 2: Create First Admin Account

1. Navigate to the Admin Login page in your app
2. Click on "Create Admin" button (toggle in the top-right)
3. Fill in the admin details:
   - **Admin Name**: Full name of the admin
   - **Admin Email**: Email address (must be unique)
   - **Admin Password**: Strong password (min 6 characters)
4. Click "Create Admin Account"
5. Once created, toggle back to "Login" mode
6. Login with the credentials you just created

### Step 3: Verify Admin Access

After logging in:
1. You should be redirected to `/admin-dashboard`
2. Session will persist even after page refresh
3. You can logout and login again to verify

## Firebase Structure

### Admins Collection

Path: `/admins/{adminId}`

Document Structure:
```json
{
  "uid": "firebase_auth_uid",
  "email": "admin@cpfindia.org",
  "name": "Admin Name",
  "role": "admin",
  "createdAt": "2025-01-15T10:30:00Z",
  "lastLogin": "2025-01-15T14:45:00Z",
  "isActive": true
}
```

## Session Persistence

Session persistence is automatically handled by Firebase Authentication:

1. **On Login**: Firebase Auth creates a persistent session
2. **On Refresh**: `authStateChanges()` listener detects the logged-in user
3. **Role Check**: System verifies admin role from Firestore
4. **Auto-Redirect**: If admin is logged in, they're kept on dashboard

### How It Works

```dart
// In AuthProvider constructor
AuthProvider() {
  _auth.authStateChanges().listen(_onAuthStateChanged);
}

// Automatically called when auth state changes
void _onAuthStateChanged(User? user) async {
  _user = user;
  if (user != null) {
    await _determineUserRole();  // Checks if user is admin
    await _checkProfileCompletion();
  }
  notifyListeners();  // Updates UI
}
```

## Creating Additional Admins

To create additional admin accounts:

1. Login as an existing admin
2. Navigate to Admin Login page (or create a dedicated admin management page)
3. Use the "Create Admin" toggle
4. Enter new admin details
5. Click "Create Admin Account"

**Note**: Only authenticated users can create admin accounts. You may want to restrict this further to existing admins only.

## Security Considerations

### Firestore Security Rules

The system uses the following security approach:

1. **Admin Verification**: Checks `/admins/{uid}` collection for role
2. **Owner Access**: Users can only access their own data
3. **Admin Override**: Admins can access all data
4. **Default Deny**: All other access is denied

### Best Practices

1. ✅ **Strong Passwords**: Enforce strong password policy
2. ✅ **Limited Admin Accounts**: Only create necessary admin accounts
3. ✅ **Regular Audits**: Review admin access logs
4. ✅ **Secure Email**: Use organization email addresses
5. ✅ **2FA**: Consider enabling two-factor authentication

## Troubleshooting

### Issue: "This account does not have admin privileges"

**Solution**: 
1. Check if user exists in `/admins` collection
2. Verify `role` field is set to `'admin'`
3. Check Firestore security rules are deployed

### Issue: Admin session not persisting

**Solution**:
1. Verify Firebase Auth is properly initialized
2. Check browser cookies/storage are enabled
3. Verify `authStateChanges()` listener is working
4. Check console for errors

### Issue: Cannot create first admin

**Solution**:
1. Verify Firebase Auth is configured
2. Check Firestore security rules allow admin creation
3. Ensure Firebase project has required permissions
4. Check Firebase console for auth errors

## API Reference

### AuthProvider Methods

#### `loginAdmin(email, password)`
Authenticates admin user via Firebase Auth and verifies admin role.

```dart
final success = await authProvider.loginAdmin(
  email: 'admin@cpfindia.org',
  password: 'SecurePassword123!',
);
```

#### `createAdminAccount(email, password, name)`
Creates new admin account in Firebase Auth and Firestore.

```dart
final success = await authProvider.createAdminAccount(
  email: 'newadmin@cpfindia.org',
  password: 'SecurePassword123!',
  name: 'New Admin Name',
);
```

#### `logout()`
Signs out current user and clears session.

```dart
await authProvider.logout();
```

### AuthProvider Properties

- `user` - Current Firebase User object
- `userRole` - Current user's role (admin, ngo, donor)
- `isLoggedIn` - Boolean indicating if user is authenticated
- `isLoading` - Boolean indicating if auth operation is in progress
- `error` - String containing last error message

## Migration Notes

### Changes from Previous Version

1. **Removed**: Hardcoded admin credentials
2. **Added**: Firebase-based admin authentication
3. **Added**: Admin collection in Firestore
4. **Added**: Comprehensive security rules
5. **Improved**: Session persistence
6. **Improved**: Role-based access control

### Breaking Changes

⚠️ **Important**: Old hardcoded credentials will no longer work. You must create admin accounts via the new system.

## Deployment Checklist

- [ ] Deploy Firestore security rules
- [ ] Create first admin account
- [ ] Test admin login
- [ ] Test session persistence (refresh page)
- [ ] Test admin dashboard access
- [ ] Verify security rules are working
- [ ] Document admin credentials securely

## Support

For issues or questions:
- Check Firebase Console for auth errors
- Review Firestore rules in Firebase Console
- Check browser console for JavaScript errors
- Contact development team

---

**Last Updated**: January 2025
**Version**: 2.0.0

