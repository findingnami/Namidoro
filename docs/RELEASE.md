# Releasing Namidoro outside the App Store

This is a step-by-step for shipping a signed, notarized build of Namidoro via GitHub
Releases (or any other direct-download channel) instead of the Mac App Store.

Steps marked **(you only)** require an Apple ID, Apple Developer Program membership, or
credentials that can't be set up or run from this repo — nothing here has been run for you.

## 1. One-time account setup **(you only)**

- Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) if you
  haven't already (this is a paid, per-year membership tied to your Apple ID).
- In Xcode, go to **Settings > Accounts**, add your Apple ID, and let Xcode manage your
  signing certificates — or create a **Developer ID Application** certificate yourself at
  [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates/list).
  This is the certificate type for distributing outside the App Store; a plain "Apple
  Development" certificate (what Debug builds use) won't notarize.
- Create an app-specific password for your Apple ID at
  [appleid.apple.com](https://appleid.apple.com) (Sign-In and Security > App-Specific
  Passwords), or set up an App Store Connect API key — either works as credentials for
  `notarytool` in step 5. Store whichever you choose with:
  ```
  xcrun notarytool store-credentials "namidoro-notarytool" \
    --apple-id "<your-apple-id>" \
    --team-id "<your-team-id>" \
    --password "<app-specific-password>"
  ```
  This saves the credentials in your keychain under the profile name
  `namidoro-notarytool`, referenced in step 5.

## 2. Bump the version

Before each release, update both version fields on the **Namidoro** app target (Debug and
Release configurations) in Xcode: select the target, **Signing & Capabilities** or
**General** tab:

- `MARKETING_VERSION` — the user-facing version (e.g. `1.1`), shown in **About Namidoro**.
- `CURRENT_PROJECT_VERSION` — the build number; bump it for every release even if
  `MARKETING_VERSION` doesn't change.

Commit this change before archiving.

## 3. Archive in Xcode

1. Select the **Namidoro** scheme and **Any Mac (Apple Silicon, Intel)** (or **My Mac**) as
   the run destination.
2. **Product > Archive**. Xcode opens the Organizer when it finishes.

## 4. Export and sign with a Developer ID certificate **(you choose the identity)**

1. In the Organizer, select the new archive and click **Distribute App**.
2. Choose **Direct Distribution** (sometimes labeled **Developer ID** depending on Xcode
   version) — not **App Store Connect**.
3. Let Xcode automatically manage signing, selecting your **Developer ID Application**
   certificate from step 1, or choose it manually if you have more than one team/identity.
4. Xcode signs and (if you leave the option checked) notarizes and staples the app for you
   in one flow — if so, you can skip to step 7. If you'd rather drive notarization yourself
   (e.g. to script releases), choose **Export** instead of letting Xcode notarize, and
   continue with step 5 below using the exported `Namidoro.app`.

## 5. Notarize with notarytool **(you only — uses your stored credentials)**

Zip the exported app first (notarytool needs a zip, not a raw `.app`):

```
ditto -c -k --keepParent Namidoro.app Namidoro.zip
xcrun notarytool submit Namidoro.zip --keychain-profile "namidoro-notarytool" --wait
```

Wait for `status: Accepted`. If it comes back `Invalid`, run
`xcrun notarytool log <submission-id> --keychain-profile "namidoro-notarytool"` to see why
(commonly: hardened runtime not enabled, or an unsigned nested binary).

## 6. Staple the ticket

```
xcrun stapler staple Namidoro.app
```

This embeds the notarization ticket in the app so Gatekeeper can verify it offline (no
network call needed on the user's Mac the first time they open it).

## 7. Package for distribution

Either a zip or a `.dmg` works; a `.dmg` is the more familiar drag-to-Applications
experience for most Mac users.

**Zip:**
```
ditto -c -k --keepParent Namidoro.app Namidoro-1.1.zip
```

**DMG** (requires `create-dmg`, installable via `brew install create-dmg`):
```
create-dmg --volname "Namidoro" --app-drop-link 450 120 Namidoro-1.1.dmg Namidoro.app
```

Re-run `xcrun stapler staple` on the `.dmg` too if your packaging step touches the app
bundle after stapling (e.g. re-signing). Verify Gatekeeper is happy before publishing:

```
spctl -a -vv Namidoro.app
```

## 8. Publish on GitHub Releases **(you only — pushes to the repo)**

1. Tag the commit from step 2: `git tag v1.1 && git push origin v1.1`.
2. On GitHub, **Releases > Draft a new release**, pick the tag, write release notes, and
   attach the `.zip` or `.dmg` from step 7.
3. Publish.

## Notes

- Nothing in this document has been executed as part of preparing this branch — no
  archive, signing, notarization, or publish step was run. This is documentation only.
- If notarization ever starts failing for a build that used to pass, check that
  `ENABLE_HARDENED_RUNTIME` is still `YES` on the Release configuration (it already is as
  of this writing) — notarytool rejects unhardened binaries.
