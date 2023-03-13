//PERFORMANCE - https://github.com/yokoffing/Betterfox/blob/master/Fastfox.js
user_pref("nglayout.initialpaint.delay", 0); // default=5; used to be 250
user_pref("nglayout.initialpaint.delay_in_oopif", 0); // default=5
user_pref("browser.sessionstore.interval", 30000); // (30s)
user_pref("gfx.webrender.all", true); // enables WR (GPU) + additional features
user_pref("gfx.webrender.precache-shaders", true);
user_pref("gfx.webrender.compositor", true);
user_pref("layers.gpu-process.enabled", true);
user_pref("media.hardware-video-decoding.enabled", true);
user_pref("gfx.canvas.accelerated", true); // DEFAULT on macOS and Linux v.110
user_pref("gfx.canvas.accelerated.cache-items", 32768);
user_pref("gfx.canvas.accelerated.cache-size", 4096);
user_pref("gfx.content.skia-font-cache-size", 80);
user_pref("image.cache.size", 10485760);
user_pref("image.mem.decode_bytes_at_a_time", 131072); // alt=65536; preferred=262144; chunk size for calls to the image decoders
user_pref("image.mem.shared.unmap.min_expiration_ms", 120000); // default=60000; minimum timeout to unmap shared surfaces since they have been last used
user_pref("media.cache_readahead_limit", 9000); // default=60; stop reading ahead when our buffered data is this many seconds ahead of the current playback
user_pref("media.cache_resume_threshold", 6000); // default=30; when a network connection is suspended, don't resume it until the amount of buffered data falls below this threshold (in seconds)
user_pref("browser.cache.memory.max_entry_size", 153600);
user_pref("network.buffer.cache.size", 262144); // preferred=327680; default=32768
user_pref("network.buffer.cache.count", 128); // preferred=240; default=24
user_pref("network.ssl_tokens_cache_capacity", 32768); // default=2048; more TLS token caching (fast reconnects)
user_pref("browser.startup.preXulSkeletonUI", false);

//SECURITY - https://github.com/yokoffing/Betterfox/blob/master/Securefox.js
user_pref("privacy.query_stripping.enabled", true); // enabled with "Strict"
user_pref("privacy.query_stripping.strip_list", "__hsfp __hssc __hstc __s _hsenc _openstat dclid fbclid gbraid gclid hsCtaTracking igshid mc_eid ml_subscriber ml_subscriber_hash msclkid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id rb_clickid s_cid twclid vero_conv vero_id wbraid wickedid yclid");
user_pref("browser.uitour.enabled", false);
user_pref("privacy.query_stripping.enabled.pbmode", true);
user_pref("security.OCSP.enabled", 0); // [DEFAULT: 1]
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode", 2);
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("browser.xul.error_pages.expert_bad_cert", true);
user_pref("security.tls.enable_0rtt_data", false); // disable 0 RTT to improve tls 1.3 security
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);
user_pref("privacy.history.custom", true);
user_pref("security.insecure_connection_text.enabled", true);
user_pref("security.insecure_connection_text.pbmode.enabled", true);
user_pref("network.IDN_show_punycode", true);
user_pref("layout.forms.reveal-password-context-menu.enabled", true); // right-click menu option
user_pref("editor.truncate_user_pastes", false);
user_pref("network.auth.subresource-http-auth-allow", 1);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("accessibility.force_disabled", 1);
user_pref("geo.provider.network.url", "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%");
user_pref("geo.provider.use_gpsd", false); // [LINUX]
user_pref("geo.provider.use_geoclue", false); // [FF102+] [LINUX]
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.dap_enabled", false); // DEFAULT [FF108]
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);

//SMOOTH - https://github.com/yokoffing/Betterfox/blob/master/Smoothfox.js
user_pref("general.smoothScroll", true);
user_pref("mousewheel.default.delta_multiplier_y", 275);
user_pref("gfx.webrender.quality.force-subpixel-aa-where-possible", true);
user_pref("gfx.font_rendering.cleartype_params.rendering_mode", 5);
user_pref("gfx.font_rendering.cleartype_params.force_gdi_classic_for_families", "");
user_pref("browser.newtabpage.activity-stream.topSitesRows", 4);

//ANNOYANCE - https://github.com/yokoffing/Betterfox/blob/master/Peskyfox.js
user_pref("layout.css.prefers-color-scheme.content-override", 2);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("app.update.suppressPrompts", true);
user_pref("browser.compactmode.show", true);
user_pref("browser.privatebrowsing.vpnpromourl", "");
user_pref("extensions.getAddons.showPane", false); // HIDDEN
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.tabs.tabmanager.enabled", false);
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
user_pref("full-screen-api.warning.delay", 0);
user_pref("full-screen-api.warning.timeout", 0);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("findbar.highlightAll", true);
user_pref("browser.urlbar.suggest.calculator", true);
user_pref("browser.urlbar.unitConversion.enabled", true);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false); // Recommended by Pocket
user_pref("extensions.pocket.enabled", false);
user_pref("browser.download.always_ask_before_handling_new_types", true);
user_pref("browser.download.open_pdf_attachments_inline", true);
user_pref("dom.disable_window_move_resize", true);
user_pref("layout.css.has-selector.enabled", true);