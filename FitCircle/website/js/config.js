/**
 * FitCircle Website Configuration
 *
 * This is the SINGLE SOURCE OF TRUTH for all configurable values.
 * When a new APK is released, only update this file.
 *
 * Steps to release a new version:
 * 1. Build: flutter build apk --release
 * 2. Upload APK to GitHub Releases (tag: vX.Y.Z)
 * 3. Update APP_VERSION and APK_DOWNLOAD_URL below
 * 4. Redeploy the website
 */

const FITCIRCLE_CONFIG = {
  APP_NAME: "FitCircle",
  APP_VERSION: "1.0.0",
  RELEASE_DATE: "September 2026",
  MIN_ANDROID_VERSION: "Android 8.0+",

  // GitHub Releases APK link — update when publishing a new release
  APK_DOWNLOAD_URL:
    "https://github.com/bhavycharaya/FitCircle/releases/download/v1.0.0/fitcircle-v1.0.0.apk",

  // GitHub repository
  GITHUB_REPOSITORY_URL: "https://github.com/bhavycharaya/FitCircle",

  // GitHub releases page
  GITHUB_RELEASES_URL:
    "https://github.com/bhavycharaya/FitCircle/releases",
};

// Make config globally accessible
window.FITCIRCLE_CONFIG = FITCIRCLE_CONFIG;
