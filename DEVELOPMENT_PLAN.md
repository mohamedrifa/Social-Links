# Social Link Development Plan

## Architecture Overview

The app is organized as a small layered Flutter application:

- `lib/main.dart` initializes Material theming, creates service instances, restores saved accounts, and switches between login and the authenticated app shell.
- `lib/models/social_account.dart` defines provider-neutral account data used by screens and services.
- `lib/services/oauth_service.dart` owns secure token storage and account persistence through `flutter_secure_storage`.
- `lib/services/twitter_service.dart` owns X OAuth 2.0 PKCE, profile lookup, and tweet posting.
- `lib/services/facebook_service.dart` owns Facebook login, profile lookup, token persistence, and logout.
- `lib/screens/login_screen.dart` lets users connect X or Facebook.
- `lib/screens/compose_screen.dart` provides text composition, gallery image selection, image preview, and posting to X.
- `lib/screens/account_screen.dart` displays connected account state and sign-out controls.

`main.dart` coordinates the services and passes callbacks/data into the screens. Screens do not read secure storage directly; they only call service methods through the app shell.

## Implementation Sequence

1. Add OAuth, HTTP, secure storage, and image picker dependencies.
2. Add platform callback placeholders for Android and iOS.
3. Create the shared account model.
4. Create `OAuthService` for secure storage, token restore, and token deletion.
5. Create `TwitterService` for PKCE login, profile lookup, and `POST /2/tweets`.
6. Create `FacebookService` for login/profile restore/logout.
7. Build login, compose, and account screens.
8. Replace the starter `main.dart` with app restoration and navigation.
9. Update the widget smoke test.
10. Run package resolution, formatting, and static analysis.

## OAuth Integration Points

### X

- Uses `flutter_appauth` with the authorization endpoint `https://twitter.com/i/oauth2/authorize`.
- Exchanges the authorization code at `https://api.twitter.com/2/oauth2/token`.
- Uses PKCE through AppAuth's native implementation.
- Reads `TWITTER_CLIENT_ID` and `TWITTER_REDIRECT_URL` from Dart defines.
- Stores access and refresh tokens in secure storage.

### Facebook

- Uses `flutter_facebook_auth`.
- Requests profile permissions plus Page and Instagram publishing permissions.
- Reads Facebook app metadata from Android/iOS platform config placeholders.
- Stores the returned access token and profile summary in secure storage.
- Page posting requires `FACEBOOK_PAGE_ID`; the login flow attempts to resolve and store that Page access token.

### Instagram

- Uses the Meta/Instagram Graph API with the Facebook login token.
- Requires `INSTAGRAM_BUSINESS_ACCOUNT_ID`.
- Publishing requires a public HTTPS media URL. Local gallery files must be uploaded to app-owned storage before calling the Graph API.

## Challenges And Mitigations

- OAuth callback mismatch: keep redirect scheme placeholders explicit and aligned between Dart defines, Android manifest placeholders, iOS URL schemes, and provider dashboards.
- Secrets in mobile apps: do not include client secrets in Dart code. Use public OAuth clients on-device and move secret-bearing flows to a backend.
- Facebook publishing permissions: Facebook post publishing generally requires additional permissions, app review, and often page-specific flows. The service is structured to add that backend/page workflow cleanly.
- X media upload: text posting uses `/2/tweets`; image upload is a separate media workflow and should be added after selecting the exact X media endpoint/access tier.
- Token expiry: refresh tokens are stored when returned. A production backend can centralize refresh, rotation, and revocation for higher assurance.

## Timeline And Dependencies

- Dependency and native config: 0.5 day.
- Services and secure restore: 1 day.
- UI screens and state flow: 1 day.
- OAuth dashboard setup and device testing: 1-2 days.
- Publishing edge cases, token refresh, and media support: 1-3 days depending on provider approvals and access tier.

The UI depends on service contracts, and service verification depends on real provider app IDs, redirect URLs, and package resolution.
