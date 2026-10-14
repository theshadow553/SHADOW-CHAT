# Firebase owner setup

## Configure the web app

The GitHub Pages build requires the Firebase Web app configuration. In Firebase
Console, open **Project settings** and register a Web app if the project does
not already have one. Add these values from its SDK configuration to the
repository's **Settings > Secrets and variables > Actions > Variables**:

- `FIREBASE_WEB_API_KEY`
- `FIREBASE_WEB_APP_ID`

Repository Actions secrets with the same names are also supported.

The app ID must be the Web app ID (`1:...:web:...`), not the Android app ID.
Restrict the API key to the Firebase APIs used by the app and the
`https://youi552.github.io/*` HTTP referrer.

Also enable **Anonymous** under Firebase Authentication sign-in providers and
publish `firestore.rules` to the same Firebase project. The app uses anonymous
authentication and Firestore for groups, privacy settings, and contacts.

The app uses anonymous Firebase Authentication for the current prototype. To make only the owner able to add room or group members:

1. Run the app on Android or Chrome.
2. Open the contacts screen and copy the displayed Firebase UID.
3. In Firestore, create this document:

`config/app`

with this field:

```text
ownerUid: YOUR_FIREBASE_UID
```

4. Publish `firestore.rules`.

The rules then allow member creation only when the signed-in UID matches `config/app.ownerUid`. They also allow sending in `secret_group` and `shadow_ops` only for the owner or a document in the matching `rooms/{roomId}/members/{uid}` path.

Anonymous UIDs are installation-specific. For a permanent owner account, enable Email/Password or another permanent provider and use that account for the owner instead of relying on an anonymous UID.

## Enable Gemini on the free plan

Shadow Chat uses Firebase AI Logic with the Gemini Developer API directly from
the Flutter app. This does not use a Cloud Function or require a Gemini API key
in the app.

1. In the Firebase console, open **AI Logic** and set up the **Gemini Developer
   API** for this Firebase project.
2. Make sure the app is connected to the same Firebase project and is using the
   current Firebase configuration.
3. Run the app and try Shadow Chat. Gemini Developer API has a free usage tier;
   check the current quotas and model availability in the Firebase console.

The Flutter app uses Firebase AI Logic by default. Passing `GEMINI_API_KEY` at
build time switches requests to the Gemini Developer API directly, including
in a release APK. Flutter does not load `.env` files automatically. The key is
embedded in the APK and can be extracted, so use this only for a private test
build and never distribute it. Without the define, the app uses Firebase AI
Logic. The direct API path still requires Firebase initialization and a signed-in
user.

From the `ShadowChat-project` directory, pass the key from the existing local
environment file for an Android run:

```sh
GEMINI_API_KEY="$(sed -n 's/^GEMINI_API_KEY=//p' './- .env.' \
   | head -n 1 | tr -d '\r')"
flutter run --dart-define="GEMINI_API_KEY=$GEMINI_API_KEY"
unset GEMINI_API_KEY
```

Build a release APK for private testing with the same key:

```sh
GEMINI_API_KEY="$(sed -n 's/^GEMINI_API_KEY=//p' './- .env.' \
   | head -n 1 | tr -d '\r')"
flutter build apk --release --dart-define="GEMINI_API_KEY=$GEMINI_API_KEY"
unset GEMINI_API_KEY
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

To build an APK on GitHub, push a change under `ShadowChat-project/` to `main`
or run **Build Android APK** from the repository Actions tab. Download the
`shadow-chat-apk-*` artifact from the completed run. To use the direct Gemini
API path in that APK, add a repository Actions secret named `GEMINI_API_KEY`;
the workflow does not read the local `.env.` file. Without that secret, the APK
uses Firebase AI Logic.

For Web, include the Firebase Web app values expected by `main.dart` as well:

```sh
GEMINI_API_KEY="$(sed -n 's/^GEMINI_API_KEY=//p' './- .env.' \
   | head -n 1 | tr -d '\r')"
flutter run -d chrome \
   --dart-define="GEMINI_API_KEY=$GEMINI_API_KEY" \
  --dart-define=FIREBASE_WEB_API_KEY=YOUR_FIREBASE_WEB_API_KEY \
  --dart-define=FIREBASE_WEB_APP_ID=1:YOUR_PROJECT_NUMBER:web:YOUR_WEB_APP_ID
unset GEMINI_API_KEY
```

The local environment file containing the key is currently tracked by Git.
If this repository has been shared or published, revoke and rotate the key;
adding the file to `.gitignore` alone will not remove it from Git history.

For production, configure Firebase App Check to help protect AI requests from
abuse. Firestore Rules control access to Firestore data; they do not authorize
Gemini requests.

The existing `notifyNewMessage` function is separate from Gemini and still
requires Cloud Functions deployment. Cloud Functions deployment requires the
Firebase project to use the Blaze plan.
