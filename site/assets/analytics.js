(() => {
  // Optional, privacy-respecting GA4 loader for EvenDisplay.
  // Stays 100% inert (zero external script requests, zero cookies) unless a valid
  // G-XXXXXXXXXX measurement ID is explicitly supplied via <meta name="evendisplay-ga4-id">
  // and neither Do Not Track nor explicit consent denial is set.
  const meta = document.querySelector('meta[name="evendisplay-ga4-id"]');
  const id = (meta && meta.content ? meta.content.trim() : "") || "";
  const validId = /^G-[A-Z0-9]{6,16}$/.test(id);
  const dnt = navigator.doNotTrack === "1" || window.doNotTrack === "1";
  const denied = window.EVENDISPLAY_CONSENT_DENIED === true;

  function emit(name, params) {
    if (!validId || dnt || denied || typeof window.gtag !== "function") return;
    window.gtag("event", name, params || {});
  }

  if (validId && !dnt && !denied) {
    window.dataLayer = window.dataLayer || [];
    window.gtag = function gtag() { window.dataLayer.push(arguments); };
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
