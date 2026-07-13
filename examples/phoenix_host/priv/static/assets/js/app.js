// For Phoenix.HTML support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * deps/phoenix_html/priv/static/phoenix_html.js

// For Phoenix.Channels support, copy the following scripts
// into your javascript bundle:
// * deps/phoenix/priv/static/phoenix.js

// For Phoenix.LiveView support, copy the following scripts
// into your javascript bundle:
// * deps/phoenix_live_view/priv/static/phoenix_live_view.js

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

if (csrfToken && window.Phoenix && window.LiveView) {
  const liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
    params: { _csrf_token: csrfToken },
  });

  liveSocket.connect();
  window.liveSocket = liveSocket;
}

// Handle flash close
// (you can safely remove this if you don't use the default flash component)
document.querySelectorAll("[role=alert][data-flash]").forEach((el) => {
  el.addEventListener("click", () => {
    el.setAttribute("hidden", "");
  });
});
