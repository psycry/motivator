# Google Client ID Setup for Web

## Current Error
```
ClientID not set. Either set it on a <meta name="google-signin-client_id" content="CLIENT_ID" /> tag, 
or pass clientId when initializing GoogleSignIn
```

## What This Means
Google Sign-In for web requires a Client ID to be configured. This is different from the API key and needs to be obtained from Google Cloud Console.

## How to Get Your Google Client ID

### Step 1: Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/
2. Select your project: **motivator-web** (project ID: `776483653268`)

### Step 2: Navigate to Credentials
1. In the left sidebar, click **"APIs & Services"**
2. Click **"Credentials"**

### Step 3: Find or Create OAuth 2.0 Client ID

#### If OAuth Client Already Exists:
1. Look for **"Web client (auto created by Google Service)"** or similar
2. Click on it to view details
3. Copy the **Client ID** (looks like: `XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`)

#### If No OAuth Client Exists:
1. Click **"+ CREATE CREDENTIALS"** at the top
2. Select **"OAuth client ID"**
3. If prompted to configure OAuth consent screen:
   - Click **"CONFIGURE CONSENT SCREEN"**
   - Select **"External"**
   - Fill in:
     - App name: `Motivator`
     - User support email: Your email
     - Developer contact: Your email
   - Click **"SAVE AND CONTINUE"** through all steps
4. Back on Create OAuth client ID:
   - Application type: **"Web application"**
   - Name: `Motivator Web Client`
   - Authorized JavaScript origins:
     - `http://localhost`
     - `http://localhost:8080`
   - Authorized redirect URIs:
     - `http://localhost`
     - `http://localhost:8080`
   - Click **"CREATE"**
5. Copy the **Client ID** from the popup

### Step 4: Add Client ID to Your App

You have two options:

#### Option A: Add to index.html (Recommended for Web)

Edit `web/index.html` and add this line in the `<head>` section:

```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID_HERE.apps.googleusercontent.com">
```

Full example:
```html
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">
  
  <!-- Google Sign-In Client ID -->
  <meta name="google-signin-client_id" content="YOUR_CLIENT_ID_HERE.apps.googleusercontent.com">
  
  <!-- Rest of head content -->
  ...
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

#### Option B: Pass Client ID in Code

Edit `lib/services/auth_service.dart`:

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: 'YOUR_CLIENT_ID_HERE.apps.googleusercontent.com',
  );
  // ... rest of code
}
```

## After Adding Client ID

1. **Save the file**
2. **Hot reload**: Press `r` in terminal (or full restart with `R`)
3. **Test Google Sign-In**: Click "Continue with Google"
4. **Google popup should appear** asking you to select an account

## Troubleshooting

### "Invalid client ID"
- Double-check you copied the entire Client ID
- Make sure it ends with `.apps.googleusercontent.com`
- Verify you're using the Web client ID, not Android or iOS

### "Popup blocked"
- Allow popups for localhost in your browser
- Try clicking the button again

### "redirect_uri_mismatch"
- Add `http://localhost` to Authorized redirect URIs in Google Cloud Console
- Add the port if needed: `http://localhost:8080`

### Still getting "ClientID not set"
- Make sure you saved the file
- Try full restart: Press `R` in terminal
- Clear browser cache and reload

## Quick Fix for Now

If you want to test the app without Google Sign-In:

1. Comment out the Google Sign-In button in `lib/pages/auth_page.dart`
2. Or just use email/password authentication
3. Set up Google Client ID later when you're ready

## Security Note

The Client ID is **not sensitive** and can be committed to your repository. It's meant to be public and is used to identify your application to Google's servers.

## Next Steps

1. Get your Client ID from Google Cloud Console
2. Add it to `web/index.html` or `auth_service.dart`
3. Hot reload the app
4. Test Google Sign-In!

The error should disappear once the Client ID is configured.
