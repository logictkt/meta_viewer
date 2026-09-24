const content = document.getElementById("meta-viewer-popup-content");

const escape = (value) => String(value || "").replace(/[&<>"']/g, (character) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
}[character]));
const url = (value) => /^(?:https?:)?\/\//i.test(String(value || "")) ? value : null;
const link = (value) => `<a class="meta-viewer-popup__link" href="${escape(value)}" target="_blank" rel="noopener noreferrer">${escape(value)}</a>`;
const text = (key, value) => {
  const string = String(value || "—");
  const countable = /(^|:)(title|description|site_name)$/i.test(String(key));
  return `${escape(string)}${string === "—" || !countable ? "" : ` <span class="meta-viewer-popup__count">(${Array.from(string).length}文字)</span>`}`;
};
const row = (key, value) => `<div class="meta-viewer-popup__row"><div class="meta-viewer-popup__key">${escape(key)}</div><div class="meta-viewer-popup__value">${url(value) ? link(value) : text(key, value)}</div></div>`;
const section = (title, rows) => `<section class="meta-viewer-popup__section"><h2>${escape(title)}</h2>${rows || '<p class="meta-viewer-popup__empty">見つかりませんでした</p>'}</section>`;
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
const image = (label, source) => `<article class="meta-viewer-popup__image"><div class="meta-viewer-popup__key">${escape(label)}</div><a href="${escape(source)}" target="_blank" rel="noopener noreferrer"><img src="${escape(source)}" alt="${escape(label)}" data-meta-viewer-popup-image></a><div class="meta-viewer-popup__image-info">${link(source)}<br><span class="meta-viewer-popup__image-dimensions">読み込み中…</span><br><span class="meta-viewer-popup__image-file">ファイル情報を取得中…</span></div></article>`;

const collectMetadata = () => {
  const absolute = (value) => { try { return new URL(value, location.href).href; } catch (_) { return value; } };
  const entries = (selector) => Array.from(document.head.querySelectorAll(selector)).map((element) => [
    element.getAttribute("name") || element.getAttribute("property") || element.getAttribute("http-equiv") || element.getAttribute("itemprop") || element.getAttribute("rel") || "charset",
    element.content || element.href || element.getAttribute("charset")
  ]);
  const images = entries('meta[property="og:image"],meta[name="twitter:image"],meta[name="twitter:image:src"],meta[itemprop="image"],meta[name="image"],meta[property="image"],meta[name="thumbnail"],link[itemprop="image"],link[rel="image_src"]')
    .filter(([_label, source]) => source).map(([label, source]) => [label, absolute(source)]);
  const standard = entries('meta[name="description"],meta[name="robots"],meta[name="viewport"],meta[http-equiv],meta[itemprop]')
    .filter(([key]) => key.toLowerCase() !== "image");
  const social = entries('meta[property^="og:"],meta[name^="twitter:"],meta[property^="article:"]')
    .filter(([key]) => !/^(og:image|twitter:image(?::src)?)$/i.test(key));
  const links = Array.from(document.head.querySelectorAll("link[rel]")).filter((element) => /canonical|alternate/.test(element.rel))
    .map((element) => [`link[rel="${element.rel}"]${element.hreflang ? ` (${element.hreflang})` : ""}`, element.href]);
  const directives = Array.from(document.head.querySelectorAll('meta[name="robots" i],meta[name="googlebot" i],meta[http-equiv="x-robots-tag" i]')).flatMap((element) => (element.content || "").toLowerCase().split(/\s*,\s*/));
  const headings = Array.from(document.body?.querySelectorAll("h1,h2,h3,h4,h5,h6") || []).map((heading) => ({ level: heading.tagName.slice(1), text: heading.textContent.trim() || "（テキストなし）" }));
  return { title: document.title, charset: document.characterSet, url: location.href, standard, social, links, images, directives, headings };
};

const render = (data) => {
  const noindex = data.directives.includes("noindex") || data.directives.includes("none");
  const nofollow = data.directives.includes("nofollow") || data.directives.includes("none");
  const nosnippet = data.directives.includes("nosnippet");
  const notices = [];
  if (noindex) notices.push("このページは index されません。");
  if (nofollow) notices.push("このページ内のリンクは追跡されません。");
  if (nosnippet) notices.push("検索結果のスニペットは表示されません。");
  const notice = notices.length ? `<div class="meta-viewer-popup__notice"><strong>robots ステータス</strong>${notices.map(escape).join("<br>")}</div>` : "";
  const basics = [["title", data.title], ["charset", data.charset], ["URL", data.url]].map(([key, value]) => row(key, value)).join("");
  const headings = data.headings.map(({ level, text: value }) => `<div class="meta-viewer-popup__heading meta-viewer-popup__heading--${level}"><span class="meta-viewer-popup__heading-tag">h${level}</span>${escape(value)}</div>`).join("");
  content.innerHTML = notice + section("基本情報", basics) + section("SEO メタタグ", data.standard.map(([key, value]) => row(key, value)).join("")) + section("Open Graph / X (Twitter)", data.social.map(([key, value]) => row(key, value)).join("")) + section("Canonical / hreflang", data.links.map(([key, value]) => row(key, value)).join("")) + section("ソーシャル画像", data.images.map(([label, source]) => image(label, source)).join("")) + section("見出し構造 (h1〜h6)", headings);
  content.querySelectorAll("[data-meta-viewer-popup-image]").forEach((element) => {
    const card = element.closest(".meta-viewer-popup__image");
    const dimensions = card.querySelector(".meta-viewer-popup__image-dimensions");
    const file = card.querySelector(".meta-viewer-popup__image-file");
    const show = () => { const { naturalWidth: width, naturalHeight: height } = element; dimensions.textContent = width && height ? `${width} × ${height}px · ${(width / height).toFixed(2)}:1` : "画像を読み込めませんでした"; };
    fileInfo(element.src).then((info) => { file.textContent = `ファイル種別: ${info.type} · ファイルサイズ: ${info.size}`; });
    element.addEventListener("load", show); element.addEventListener("error", show); if (element.complete) show();
  });
};

const load = async () => {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (!tab?.id) throw new Error("タブを取得できませんでした。");
    const [injection] = await chrome.scripting.executeScript({ target: { tabId: tab.id }, func: collectMetadata });
    render(injection.result);
  } catch (_) {
    content.innerHTML = '<p class="meta-viewer-popup__error">このページのメタ情報を取得できませんでした。Chrome の内部ページや、拡張機能のアクセスが禁止されたページでは利用できません。</p>';
  }
};

load();
