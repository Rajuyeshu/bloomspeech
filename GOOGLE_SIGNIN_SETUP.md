# Google Sign-In — configuration checklist

The app code is done. Sign-in still cannot work until the three items below
are configured, because the OAuth exchange happens on Google's and Supabase's
servers, not in the app.

**Nothing here belongs in this repository.** The client secret in particular
must only ever be pasted into the Supabase dashboard. Anything compiled into
the APK can be extracted from it in minutes.

---

## 1. Google Cloud Console

<https://console.cloud.google.com/apis/credentials>

Select your project first — credentials are per-project, and creating them in
the wrong one is the most common reason "the client ID doesn't work".

### a. OAuth consent screen

<https://console.cloud.google.com/auth/overview>

| Field | Value |
|---|---|
| App name | BloomSpeech |
| User support email | your address |
| Audience | External |
| Developer contact | your address |

While the app is in **Testing**, only accounts listed under *Audience → Test
users* can sign in. Everyone else gets "app is blocked". Add every tester's
Gmail address there, or publish the app.

### b. OAuth client — Web application

Credentials → **+ Create credentials** → **OAuth client ID** → type **Web
application**.

Under **Authorised redirect URIs**, add exactly:

```
https://wleogtlhqqwsqoweqhxh.supabase.co/auth/v1/callback
```

This is the Supabase endpoint Google hands the user back to. It is *not* the
app's own `bloomspeech://` link — that second hop is Supabase's job.

> Use a **Web application** client, not Android. The app signs in through the
> browser via Supabase, so Google only ever talks to Supabase's server. An
> Android client would additionally need the SHA-1 of the signing key, and is
> only required if you later switch to native Google Sign-In.

Copy the **Client ID** and **Client secret** it produces.

---

## 2. Supabase — enable the provider

<https://supabase.com/dashboard/project/wleogtlhqqwsqoweqhxh/auth/providers>

Authentication → Providers → **Google** → enable, then paste the Client ID and
Client secret from step 1b. Save.

---

## 3. Supabase — allow the app's callback

<https://supabase.com/dashboard/project/wleogtlhqqwsqoweqhxh/auth/url-configuration>

Authentication → URL Configuration → **Redirect URLs** → add exactly:

```
bloomspeech://login-callback
```

Without this, Supabase refuses to redirect back into the app and the browser
stops on an error page. The value must match `AppConstants.oauthRedirectUrl`,
the Android manifest intent-filter, and the iOS `CFBundleURLSchemes` entry —
all four are checked against each other by `test/unit/oauth_redirect_test.dart`.

---

## The full round trip

```
App  ──► browser ──► Google sign-in
                        │
                        ▼
     https://<project>.supabase.co/auth/v1/callback     ← step 1b
                        │
                        ▼
             bloomspeech://login-callback               ← step 3
                        │
                        ▼
     Android delivers the deep link to MainActivity     ← in the manifest
                        │
                        ▼
        Supabase sets the session, router → home
```

Each arrow is a separate piece of configuration. A missing one breaks the
chain at that point and nowhere else, which is why the symptom is always the
same unhelpful "it just doesn't sign in".

---

## Verifying

1. Tap **Continue with Google**. A browser must open. If it does not, the
   failure is in the app and will now show an error on screen.
2. Sign in. If you see "Error 400: redirect_uri_mismatch", step 1b is wrong.
3. If you see a Supabase error page instead of returning to the app, step 3
   is wrong.
4. If you land back in the app but on the login screen, the session did not
   arrive — check **Settings › Data Diagnostics** for a recorded error.

## After it works

Rotate the client secret if it has been shared anywhere outside the Supabase
dashboard: Credentials → your client → **Reset secret**, then paste the new
one into step 2. The old secret stops working immediately.
