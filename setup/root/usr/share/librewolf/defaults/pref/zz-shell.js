// Follow the desktop's GTK theme (dark + the soft-gray accent) instead of LibreWolf's own "Dark" theme.
pref("extensions.activeThemeID", "default-theme@mozilla.org");
pref("layout.css.prefers-color-scheme.content-override", 0);   // websites: dark

// --- Video: hardware decoding (Intel VA-API) where the GPU supports the codec ---
// (YouTube is watched in Brave; VP9/AV1 stay enabled here — the MSE prefs didn't force H.264 anyway.)
pref("media.ffmpeg.vaapi.enabled", true);
pref("media.hardware-video-decoding.force-enabled", true);
pref("media.mediasource.vp9.enabled", true);   // back to default
pref("media.av1.enabled", true);              // back to default

// --- Memory and layout ---
pref("browser.tabs.unloadOnLowMemory", true);
pref("browser.uidensity", 1);               // compact toolbars
pref("browser.compactmode.show", true);     // keep "Compact" selectable in Customize
