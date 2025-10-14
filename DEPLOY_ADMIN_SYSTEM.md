# Quick Deploy Guide - Admin System

## 🚀 Deployment Steps

### 1. Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

**Expected Output:**
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

### 2. Run the Application

```bash
flutter run -d chrome
```

Or for production build:
```bash
flutter build web
```

### 3. Create First Admin Account

1. Open the app in browser
2. Navigate to `/admin-login`
3. Click "Create Admin" toggle
4. Enter admin details:
   ```
   Name: Your Admin Name
   Email: admin@cpfindia.org
   Password: YourSecurePassword123!
   ```
5. Click "Create Admin Account"

### 4. Login & Test

1. Toggle back to "Login" mode
2. Enter the credentials you just created
3. Click "Login as Admin"
4. You should be redirected to Admin Dashboard
5. **Test Persistence**: Refresh the page (F5)
   - You should remain logged in
   - You should stay on the dashboard

### 5. Verify Everything Works

- ✅ Can create admin account
- ✅ Can login with admin credentials
- ✅ Session persists after refresh
- ✅ Can access admin dashboard
- ✅ Can logout successfully

## 🔑 Important Commands

### Deploy only Firestore rules
```bash
firebase deploy --only firestore:rules
```

### Deploy entire Firebase configuration
```bash
firebase deploy
```

### Check Firebase project
```bash
firebase projects:list
firebase use --add
```

### View Firestore data
```bash
# Go to Firebase Console
https://console.firebase.google.com/
# Navigate to: Firestore Database > Data > admins collection
```

## ⚠️ First Time Setup

If this is your first time deploying:

1. **Initialize Firebase** (if not done):
   ```bash
   firebase login
   firebase init firestore
   ```

2. **Select your project**:
   ```bash
   firebase use <your-project-id>
   ```

3. **Deploy rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

## 🔒 Security Checklist

Before going to production:

- [ ] Firestore rules are deployed
- [ ] Admin account is created
- [ ] Test admin login works
- [ ] Test session persistence works
- [ ] Test logout works
- [ ] Remove any test/debug code
- [ ] Secure admin passwords
- [ ] Document admin credentials safely

## 🐛 Troubleshooting

### "Permission denied" when creating admin

**Fix**: Deploy Firestore rules first
```bash
firebase deploy --only firestore:rules
```

### "User not found" when logging in

**Fix**: Create admin account first using "Create Admin" mode

### Session not persisting

**Fix**: Check browser cookies are enabled and Firebase Auth is initialized

### Cannot access admin dashboard

**Fix**: Verify admin role exists in `/admins/{uid}` collection

## 📝 Quick Reference

### Admin Email Format
```
admin@cpfindia.org
support@cpfindia.org
your-name@cpfindia.org
```

### Admin Document Structure (Firestore)
```
/admins/{uid}
  - uid: string
  - email: string
  - name: string
  - role: "admin"
  - createdAt: timestamp
  - lastLogin: timestamp
  - isActive: boolean
```

### Test Credentials (After Creation)
```
Email: admin@cpfindia.org
Password: [Your secure password]
```

## 🎯 Next Steps

After deployment:

1. Create additional admin accounts if needed
2. Set up admin account backup
3. Document admin credentials securely
4. Enable 2FA in Firebase Console (optional)
5. Monitor admin access logs
6. Regular security audits

---

**Need Help?** Check `ADMIN_SETUP_GUIDE.md` for detailed documentation.

