const config = window.ShortLinkConfig || {};

const encodeInput = document.getElementById("encode-input");
const encodeButton = document.getElementById("encode-button");
const encodeResult = document.getElementById("encode-result");
const encodeError = document.getElementById("encode-error");
const shortLink = document.getElementById("short-link");
const copyButton = document.getElementById("copy-button");

const decodeInput = document.getElementById("decode-input");
const decodeButton = document.getElementById("decode-button");
const decodeResult = document.getElementById("decode-result");
const decodeError = document.getElementById("decode-error");
const originalLink = document.getElementById("original-link");

const setHidden = (el, hidden) => {
  if (!el) return;
  el.hidden = hidden;
};

const setText = (el, text) => {
  if (!el) return;
  el.textContent = text;
};

const setLink = (el, url) => {
  if (!el) return;
  el.href = url;
  el.textContent = url;
};

const getRecaptchaToken = async () => {
  if (!config.recaptchaSiteKey || !window.grecaptcha) {
    return null;
  }

  return window.grecaptcha.execute(config.recaptchaSiteKey, { action: "encode" });
};

const postJson = async (path, payload) => {
  const response = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = data.error || "Something went wrong";
    throw new Error(message);
  }

  return data;
};

const handleEncode = async () => {
  setHidden(encodeError, true);
  setHidden(encodeResult, true);

  const url = encodeInput.value.trim();
  if (!url) {
    setText(encodeError, "Please enter a valid URL.");
    setHidden(encodeError, false);
    return;
  }

  encodeButton.disabled = true;
  encodeButton.textContent = "Working...";

  try {
    const token = await getRecaptchaToken();
    const payload = { url };
    if (token) {
      payload.recaptcha_token = token;
    }

    const data = await postJson("/encode", payload);
    setLink(shortLink, data.short_url);
    setHidden(encodeResult, false);
  } catch (error) {
    setText(encodeError, error.message || "Unable to encode URL");
    setHidden(encodeError, false);
  } finally {
    encodeButton.disabled = false;
    encodeButton.textContent = "Generate short link";
  }
};

const handleDecode = async () => {
  setHidden(decodeError, true);
  setHidden(decodeResult, true);

  const shortUrl = decodeInput.value.trim();
  if (!shortUrl) {
    setText(decodeError, "Please enter a short URL.");
    setHidden(decodeError, false);
    return;
  }

  decodeButton.disabled = true;
  decodeButton.textContent = "Working...";

  try {
    const data = await postJson("/decode", { short_url: shortUrl });
    setLink(originalLink, data.url);
    setHidden(decodeResult, false);
  } catch (error) {
    setText(decodeError, error.message || "Unable to decode URL");
    setHidden(decodeError, false);
  } finally {
    decodeButton.disabled = false;
    decodeButton.textContent = "Decode link";
  }
};

if (encodeButton) {
  encodeButton.addEventListener("click", handleEncode);
}

if (decodeButton) {
  decodeButton.addEventListener("click", handleDecode);
}

if (encodeInput) {
  encodeInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      handleEncode();
    }
  });
}

if (decodeInput) {
  decodeInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      handleDecode();
    }
  });
}

if (copyButton) {
  copyButton.addEventListener("click", async () => {
    const text = shortLink.textContent;
    if (!text) return;
    try {
      await navigator.clipboard.writeText(text);
      copyButton.textContent = "Copied";
      setTimeout(() => {
        copyButton.textContent = "Copy";
      }, 1200);
    } catch (_) {
      copyButton.textContent = "Copy failed";
      setTimeout(() => {
        copyButton.textContent = "Copy";
      }, 1200);
    }
  });
}
