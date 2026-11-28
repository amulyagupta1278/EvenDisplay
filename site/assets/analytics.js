(() => {
  // Privacy-respecting analytics & GTM dataLayer event bridge for EvenDisplay.
  // - If GTM (window.dataLayer) is active, pushes semantic non-PII product events into dataLayer.
  // - If an explicit GA4 Measurement ID (G-...) is also configured via <meta name="evendisplay-ga4-id">
  //   without GTM handling GA4, initializes gtag.js cleanly.
  // - Honors navigator.doNotTrack === "1" and window.EVENDISPLAY_CONSENT_DENIED === true.
  const meta = document.querySelector('meta[name="evendisplay-ga4-id"]');
  const id = (meta && meta.content ? meta.content.trim() : "") || "";
  const validGa4 = /^G-[A-Z0-9]{6,16}$/.test(id);
  const dnt = navigator.doNotTrack === "1" || window.doNotTrack === "1";
  const denied = window.EVENDISPLAY_CONSENT_DENIED === true;

  function emit(name, params) {
    if (dnt || denied) return;
    if (Array.isArray(window.dataLayer)) {
      window.dataLayer.push(Object.assign({ event: name }, params || {}));
    }
    if (validGa4 && typeof window.gtag === "function") {
      window.gtag("event", name, params || {});
    }
  }

  if (validGa4 && !dnt && !denied) {
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function gtag() { window.dataLayer.push(arguments); };
    window.gtag("js", new Date());
    window.gtag("config", id, {
      anonymize_ip: true,
      allow_google_signals: false,
      allow_ad_personalization_signals: false
    });
    const s = document.createElement("script");
    s.async = true;
    s.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(id)}`;
    document.head.appendChild(s);
  }

  document.addEventListener("click", (e) => {
    const target = e.target && e.target.closest ? e.target.closest("[data-track]") : null;
    if (!target) return;
    const eventName = target.getAttribute("data-track");
    const label = target.getAttribute("data-track-label") || target.textContent.trim().slice(0, 60);
    if (eventName) {
      emit(eventName, { event_label: label, page_path: window.location.pathname });
    }
  });
})();
