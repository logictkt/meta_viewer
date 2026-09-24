(() => {
  if (globalThis.__metaViewerExtensionLoaded) return;
  globalThis.__metaViewerExtensionLoaded = true;

  const rootId = "meta-viewer-extension";
  const escape = (value) => String(value || "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[character]));
  const relative = (value) => {
    try { return new URL(value, location.href).href; } catch (_) { return value; }
  };
  const url = (value) => /^(?:https?:)?\/\//i.test(String(value || "")) ? relative(value) : null;
  const link = (value) => `<a class="meta-viewer-extension__link" href="${escape(value)}" target="_blank" rel="noopener noreferrer">${escape(value)}</a>`;
  const text = (key, value) => {
    const content = String(value || "—");
    const countable = /(^|:)(title|description|site_name)$/i.test(String(key));
    const count = content === "—" || !countable ? "" : ` <span class="meta-viewer-extension__count">(${Array.from(content).length}文字)</span>`;
    return `${escape(content)}${count}`;
  };
  const row = (key, value) => {
    const href = url(value);
    return `<div class="meta-viewer-extension__row"><div class="meta-viewer-extension__key">${escape(key)}</div><div class="meta-viewer-extension__value">${href ? link(href) : text(key, value)}</div></div>`;
  };
  const section = (title, rows) => `<section class="meta-viewer-extension__section"><h3>${escape(title)}</h3>${rows || '<p class="meta-viewer-extension__empty">見つかりませんでした</p>'}</section>`;
  const meta = (selector) => Array.from(document.head.querySelectorAll(selector)).map((element) => [
    element.getAttribute("name") || element.getAttribute("property") || element.getAttribute("http-equiv") || element.getAttribute("itemprop") || "charset",
    element.content || element.getAttribute("charset")
  ]);
  const imageMeta = () => Array.from(document.head.querySelectorAll('meta[property="og:image"],meta[name="twitter:image"],meta[name="twitter:image:src"],meta[itemprop="image"],meta[name="image"],meta[property="image"],link[itemprop="image"],link[rel="image_src"]')).map((element) => [
    element.getAttribute("name") || element.getAttribute("property") || element.getAttribute("itemprop") || element.getAttribute("rel") || "image",
    element.content || element.href
  ]).filter(([_label, source]) => source);
  const image = (label, value) => {
    const source = relative(value);
    return `<article class="meta-viewer-extension__image"><div class="meta-viewer-extension__key">${escape(label)}</div><a href="${escape(source)}" target="_blank" rel="noopener noreferrer"><img src="${escape(source)}" alt="${escape(label)}" data-meta-viewer-extension-image></a><div class="meta-viewer-extension__image-info">${link(source)}<br><span class="meta-viewer-extension__image-dimensions">読み込み中…</span><br><span class="meta-viewer-extension__image-file">ファイル情報を取得中…</span></div></article>`;
  };
  const robotsNotice = () => {
    const directives = Array.from(document.head.querySelectorAll('meta[name="robots" i],meta[name="googlebot" i],meta[http-equiv="x-robots-tag" i]')).flatMap((element) => (element.content || "").toLowerCase().split(/\s*,\s*/));
    const noindex = directives.includes("noindex") || directives.includes("none");
    const nofollow = directives.includes("nofollow") || directives.includes("none");
    const nosnippet = directives.includes("nosnippet");
    if (!noindex && !nofollow && !nosnippet) return "";
    const messages = [];
    if (noindex) messages.push("このページは index されません。");
    if (nofollow) messages.push("このページ内のリンクは追跡されません。");
    if (nosnippet) messages.push("検索結果のスニペットは表示されません。");
    return `<div class="meta-viewer-extension__notice meta-viewer-extension__notice--warning"><strong>robots ステータス</strong>${messages.map(escape).join("<br>")}</div>`;
  };
  const headings = () => Array.from(document.body.querySelectorAll("h1,h2,h3,h4,h5,h6"))
    .filter((heading) => !heading.closest("[data-meta-viewer-extension]"))
    .map((heading) => {
      const level = heading.tagName.slice(1);
      const value = heading.textContent.trim() || "（テキストなし）";
      return `<div class="meta-viewer-extension__heading meta-viewer-extension__heading--${level}"><span class="meta-viewer-extension__heading-tag">h${level}</span>${escape(value)}</div>`;
    }).join("");
  const ratio = (first, second) => {
    const gcd = (left, right) => right ? gcd(right, left % right) : left;
    const divisor = gcd(first, second);
    return `${first / divisor}:${second / divisor}`;
  };
  const typeFromUrl = (source) => {
    const extension = source.split("?")[0].split(".").pop().toLowerCase();
    return ({ avif: "image/avif", gif: "image/gif", jpeg: "image/jpeg", jpg: "image/jpeg", png: "image/png", svg: "image/svg+xml", webp: "image/webp" })[extension] || "取得できません";
  };
  const formatBytes = (bytes) => {
    if (bytes < 1024) return `${bytes} B`;
    const units = ["KB", "MB", "GB"];
    const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)) - 1, units.length - 1);
    return `${(bytes / (1024 ** (index + 1))).toFixed(index ? 2 : 1)} ${units[index]}`;
  };
  const fileInfo = async (source) => {
    const fallbackType = typeFromUrl(source);
    try {
      const response = await fetch(source, { method: "HEAD" });
      if (!response.ok) throw new Error("HTTP error");
      const type = response.headers.get("content-type")?.split(";")[0] || fallbackType;
      const bytes = Number(response.headers.get("content-length"));
      return { type, size: Number.isFinite(bytes) && bytes >= 0 ? formatBytes(bytes) : "取得できません" };
    } catch (_) {
      return { type: fallbackType, size: "取得できません（CORS または応答ヘッダー未対応）" };
    }
  };

  const createPanel = () => {
    const root = document.createElement("aside");
    root.id = rootId;
    root.className = "meta-viewer-extension";
    root.setAttribute("aria-label", "SEO meta checker");
    root.setAttribute("data-meta-viewer-extension", "");
    root.innerHTML = `
      <header class="meta-viewer-extension__header">
        <h2>メタチェック</h2>
        <button type="button" class="meta-viewer-extension__close" aria-label="閉じる">×</button>
      </header>
      <p class="meta-viewer-extension__hint">このページの DOM から読み取った SEO 情報です。</p>
      <div class="meta-viewer-extension__content" aria-live="polite"></div>`;
    (document.body || document.documentElement).append(root);
    root.querySelector(".meta-viewer-extension__close").addEventListener("click", () => root.classList.remove("is-open"));
    document.addEventListener("click", (event) => {
      if (root.classList.contains("is-open") && !root.contains(event.target)) root.classList.remove("is-open");
    }, true);
    return root;
  };

  const render = (root) => {
    const content = root.querySelector(".meta-viewer-extension__content");
    const basics = [["title", document.title], ["charset", document.characterSet], ["URL", location.href]].map(([key, value]) => row(key, value)).join("");
    const standard = meta('meta[name="description"],meta[name="robots"],meta[name="viewport"],meta[http-equiv],meta[itemprop]').filter(([key]) => key.toLowerCase() !== "image").map(([key, value]) => row(key, value)).join("");
    const social = meta('meta[property^="og:"],meta[name^="twitter:"],meta[property^="article:"]')
      .filter(([key]) => !/^(og:image|twitter:image(?::src)?)$/i.test(key))
      .map(([key, value]) => row(key, value)).join("");
    const links = Array.from(document.head.querySelectorAll("link[rel]"))
      .filter((element) => /canonical|alternate/.test(element.rel))
      .map((element) => row(`link[rel="${element.rel}"]${element.hreflang ? ` (${element.hreflang})` : ""}`, element.href)).join("");
    const images = imageMeta();
    content.innerHTML = robotsNotice() + section("基本情報", basics) + section("SEO メタタグ", standard) + section("Open Graph / X (Twitter)", social) + section("Canonical / hreflang", links) + section("ソーシャル画像", images.map(([label, source]) => image(label, source)).join("")) + section("見出し構造 (h1〜h6)", headings());
    content.querySelectorAll("[data-meta-viewer-extension-image]").forEach((element) => {
      const card = element.closest(".meta-viewer-extension__image");
      const dimensions = card.querySelector(".meta-viewer-extension__image-dimensions");
      const file = card.querySelector(".meta-viewer-extension__image-file");
      const show = () => {
        const { naturalWidth: width, naturalHeight: height } = element;
        dimensions.textContent = width && height ? `${width} × ${height}px · ${ratio(width, height)} (${(width / height).toFixed(2)}:1)` : "画像を読み込めませんでした";
      };
      fileInfo(element.src).then((info) => { file.textContent = `ファイル種別: ${info.type} · ファイルサイズ: ${info.size}`; });
      element.addEventListener("load", show);
      element.addEventListener("error", show);
      if (element.complete) show();
    });
  };

  const toggle = () => {
    const root = document.getElementById(rootId) || createPanel();
    const isOpening = !root.classList.contains("is-open");
    if (isOpening) render(root);
    root.classList.toggle("is-open", isOpening);
  };

  chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
    if (message.type !== "META_VIEWER_TOGGLE") return;

    toggle();
    sendResponse({ ok: true });
  });
})();
