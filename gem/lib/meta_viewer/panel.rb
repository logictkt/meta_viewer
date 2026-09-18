# frozen_string_literal: true

module MetaViewer
  module Panel
    module_function

    def html
      <<~HTML
        <aside id="meta-viewer" class="meta-viewer meta-viewer--#{MetaViewer.configuration.button_position.tr('_', '-')}" aria-label="SEO meta checker" data-meta-viewer>
          <button type="button" class="meta-viewer__trigger" aria-expanded="false" aria-controls="meta-viewer-panel">メタチェック</button>
          <section id="meta-viewer-panel" class="meta-viewer__panel" aria-hidden="true">
            <header class="meta-viewer__header"><h2>メタチェック</h2><button type="button" class="meta-viewer__close" aria-label="閉じる">×</button></header>
            <p class="meta-viewer__hint">このページの DOM から読み取った SEO 情報です。</p>
            <div class="meta-viewer__content" aria-live="polite"></div>
          </section>
        </aside>
        <style>#{css}</style>
        <script>#{javascript}</script>
      HTML
    end

    def css
      <<~CSS
        .meta-viewer{position:fixed;z-index:2147483647;font-family:ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#172033}.meta-viewer *{box-sizing:border-box}.meta-viewer--right-top{right:0;top:24px}.meta-viewer--right-bottom{right:0;bottom:24px}.meta-viewer--right-center{right:0;top:50%;margin-top:-22px}.meta-viewer--left-top{left:0;top:24px}.meta-viewer--left-bottom{bottom:24px;left:0}.meta-viewer--left-center{left:0;top:50%;margin-top:-22px}.meta-viewer__trigger{border:0;border-radius:8px 0 0 8px;background:#172033;color:#fff;cursor:pointer;font-weight:700;padding:12px 16px;box-shadow:0 4px 16px #0004}.meta-viewer--left-top .meta-viewer__trigger,.meta-viewer--left-bottom .meta-viewer__trigger,.meta-viewer--left-center .meta-viewer__trigger{border-radius:0 8px 8px 0}.meta-viewer__panel{position:fixed;right:0;top:0;width:min(430px,100vw);height:100vh;background:#fff;box-shadow:-8px 0 32px #0003;transform:translateX(105%);transition:transform .22s ease;overflow:auto;padding:0 18px 32px}.meta-viewer.is-open .meta-viewer__panel{transform:translateX(0)}.meta-viewer__header{position:sticky;top:0;display:flex;align-items:center;justify-content:space-between;background:#fff;border-bottom:1px solid #e5e7eb;padding:18px 0 12px;z-index:1}.meta-viewer__header h2{font-size:18px;margin:0}.meta-viewer__close{border:0;background:transparent;font-size:30px;line-height:1;cursor:pointer;color:#4b5563}.meta-viewer__hint{font-size:12px;color:#6b7280;margin:14px 0}.meta-viewer__notice{border:1px solid #bbf7d0;border-radius:7px;background:#f0fdf4;color:#166534;font-size:13px;line-height:1.45;margin:14px 0;padding:10px}.meta-viewer__notice--warning{border-color:#fecaca;background:#fef2f2;color:#b91c1c}.meta-viewer__notice strong{display:block;font-size:11px;margin-bottom:3px}.meta-viewer__section{margin:0 0 20px}.meta-viewer__section h3{font-size:14px;margin:0 0 8px;padding-bottom:6px;border-bottom:1px solid #e5e7eb}.meta-viewer__section h3::before{content:"■ ";color:#3730a3}.meta-viewer__row{padding:9px 0;border-bottom:1px solid #f0f1f3}.meta-viewer__key{font:600 11px ui-monospace,SFMono-Regular,monospace;color:#4b5563;word-break:break-word}.meta-viewer__value{font-size:13px;line-height:1.45;word-break:break-word;margin-top:3px}.meta-viewer__link{color:#2563eb;text-decoration:underline}.meta-viewer__count{color:#6b7280;font-size:11px;white-space:nowrap}.meta-viewer__empty{color:#6b7280;font-size:13px}.meta-viewer__image{margin:12px 0;padding:10px;border:1px solid #e5e7eb;border-radius:7px}.meta-viewer__image img{width:100%;max-height:190px;object-fit:contain;background:#f8fafc;border-radius:4px}.meta-viewer__image-info{font-size:12px;color:#4b5563;margin-top:6px;word-break:break-word}.meta-viewer__heading{border-left:3px solid #c7d2fe;font-size:13px;line-height:1.45;margin:6px 0;padding:5px 7px}.meta-viewer__heading--1{margin-left:0}.meta-viewer__heading--2{margin-left:12px}.meta-viewer__heading--3{margin-left:24px}.meta-viewer__heading--4{margin-left:36px}.meta-viewer__heading--5{margin-left:48px}.meta-viewer__heading--6{margin-left:60px}.meta-viewer__heading-tag{color:#4f46e5;font:600 11px ui-monospace,SFMono-Regular,monospace;margin-right:6px}.meta-viewer__badge{display:inline-block;background:#eef2ff;color:#3730a3;border-radius:999px;font-size:11px;padding:2px 7px;margin:3px 4px 0 0}
      CSS
    end

    def javascript
      <<~JS
        (() => {
          const root = document.querySelector('[data-meta-viewer]'); if (!root) return;
          const trigger = root.querySelector('.meta-viewer__trigger'), panel = root.querySelector('.meta-viewer__panel'), close = root.querySelector('.meta-viewer__close'), content = root.querySelector('.meta-viewer__content');
          const escape = value => String(value || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
          const relative = url => { try { return new URL(url, location.href).href; } catch (_) { return url; } };
          const url = value => /^(?:https?:)?\\/\\//i.test(String(value || '')) ? relative(value) : null;
          const link = value => `<a class="meta-viewer__link" href="${escape(value)}" target="_blank" rel="noopener noreferrer">${escape(value)}</a>`;
          const text = (key, value) => { const content = String(value || '—'); const countable = /(^|:)(title|description|site_name)$/i.test(String(key)); return `${escape(content)}${content === '—' || !countable ? '' : ` <span class="meta-viewer__count">(${Array.from(content).length}文字)</span>`}`; };
          const row = (key, value) => { const href = url(value); return `<div class="meta-viewer__row"><div class="meta-viewer__key">${escape(key)}</div><div class="meta-viewer__value">${href ? link(href) : text(key, value)}</div></div>`; };
          const section = (title, rows) => `<section class="meta-viewer__section"><h3>${escape(title)}</h3>${rows || '<p class="meta-viewer__empty">見つかりませんでした</p>'}</section>`;
          const meta = (selector) => Array.from(document.head.querySelectorAll(selector)).map(el => [el.getAttribute('name') || el.getAttribute('property') || el.getAttribute('http-equiv') || el.getAttribute('itemprop') || 'charset', el.content || el.getAttribute('charset')]);
          const imageMeta = () => Array.from(document.head.querySelectorAll('meta[property="og:image"],meta[name="twitter:image"],meta[name="twitter:image:src"],meta[itemprop="image"],meta[name="image"],meta[property="image"],link[itemprop="image"],link[rel="image_src"]')).map(el => [el.getAttribute('name') || el.getAttribute('property') || el.getAttribute('itemprop') || el.getAttribute('rel') || 'image', el.content || el.href]).filter(([_label, source]) => source);
          const image = (label, url) => { const source = relative(url); return `<article class="meta-viewer__image"><div class="meta-viewer__key">${escape(label)}</div><a href="${escape(source)}" target="_blank" rel="noopener noreferrer"><img src="${escape(source)}" alt="${escape(label)}" data-meta-viewer-image></a><div class="meta-viewer__image-info">${link(source)}<br><span class="meta-viewer__image-dimensions">読み込み中…</span><br><span class="meta-viewer__image-file">ファイル情報を取得中…</span></div></article>`; };
          const robotsNotice = () => {
            const directives = Array.from(document.head.querySelectorAll('meta[name="robots" i],meta[name="googlebot" i],meta[http-equiv="x-robots-tag" i]')).flatMap(el => (el.content || '').toLowerCase().split(/\\s*,\\s*/));
            const noindex = directives.includes('noindex') || directives.includes('none');
            const nofollow = directives.includes('nofollow') || directives.includes('none');
            const nosnippet = directives.includes('nosnippet');
            if (!noindex && !nofollow && !nosnippet) return '';
            const messages = [];
            if (noindex) messages.push('このページは index されません。');
            if (nofollow) messages.push('このページ内のリンクは追跡されません。');
            if (nosnippet) messages.push('検索結果のスニペットは表示されません。');
            return `<div class="meta-viewer__notice meta-viewer__notice--warning"><strong>robots ステータス</strong>${messages.map(escape).join('<br>')}</div>`;
          };
          const headings = () => Array.from(document.body.querySelectorAll('h1,h2,h3,h4,h5,h6')).filter(heading => !heading.closest('[data-meta-viewer]')).map(heading => { const level = heading.tagName.slice(1); const value = heading.textContent.trim() || '（テキストなし）'; return `<div class="meta-viewer__heading meta-viewer__heading--${level}"><span class="meta-viewer__heading-tag">h${level}</span>${escape(value)}</div>`; }).join('');
          const render = () => {
            const basics = [['title', document.title], ['charset', document.characterSet], ['URL', location.href]].map(([k,v]) => row(k,v)).join('');
            const standard = meta('meta[name="description"],meta[name="robots"],meta[name="viewport"],meta[http-equiv],meta[itemprop]').filter(([key]) => key.toLowerCase() !== 'image').map(x => row(...x)).join('');
            const social = meta('meta[property^="og:"],meta[name^="twitter:"],meta[property^="article:"]').filter(([key]) => !/^(og:image|twitter:image(?::src)?)$/i.test(key)).map(x => row(...x)).join('');
            const links = Array.from(document.head.querySelectorAll('link[rel]')).filter(el => /canonical|alternate/.test(el.rel)).map(el => row(`link[rel="${el.rel}"]${el.hreflang ? ` (${el.hreflang})` : ''}`, el.href)).join('');
            const images = imageMeta();
            content.innerHTML = robotsNotice() + section('基本情報', basics) + section('SEO メタタグ', standard) + section('Open Graph / X (Twitter)', social) + section('Canonical / hreflang', links) + section('ソーシャル画像', images.map(([label, source]) => image(label, source)).join('')) + section('見出し構造 (h1〜h6)', headings());
            content.querySelectorAll('[data-meta-viewer-image]').forEach(img => { const card = img.closest('.meta-viewer__image'); const dimensions = card.querySelector('.meta-viewer__image-dimensions'); const file = card.querySelector('.meta-viewer__image-file'); const show = () => { const width = img.naturalWidth, height = img.naturalHeight; dimensions.textContent = width && height ? `${width} × ${height}px · ${ratio(width, height)} (${(width / height).toFixed(2)}:1)` : '画像を読み込めませんでした'; }; fileInfo(img.src).then(info => { file.textContent = `ファイル種別: ${info.type} · ファイルサイズ: ${info.size}`; }); img.addEventListener('load', show); img.addEventListener('error', show); if (img.complete) show(); });
          };
          const ratio = (a,b) => { const gcd = (x,y) => y ? gcd(y,x % y) : x; const n = gcd(a,b); return `${a/n}:${b/n}`; };
          const fileInfo = async source => { const fallbackType = typeFromUrl(source); try { const response = await fetch(source, { method: 'HEAD' }); if (!response.ok) throw new Error('HTTP error'); const type = response.headers.get('content-type')?.split(';')[0] || fallbackType; const bytes = Number(response.headers.get('content-length')); return { type, size: Number.isFinite(bytes) && bytes >= 0 ? formatBytes(bytes) : '取得できません' }; } catch (_) { return { type: fallbackType, size: '取得できません（CORS または応答ヘッダー未対応）' }; } };
          const typeFromUrl = source => { const extension = source.split('?')[0].split('.').pop().toLowerCase(); return ({ avif: 'image/avif', gif: 'image/gif', jpeg: 'image/jpeg', jpg: 'image/jpeg', png: 'image/png', svg: 'image/svg+xml', webp: 'image/webp' })[extension] || '取得できません'; };
          const formatBytes = bytes => { if (bytes < 1024) return `${bytes} B`; const units = ['KB', 'MB', 'GB']; const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)) - 1, units.length - 1); return `${(bytes / (1024 ** (index + 1))).toFixed(index ? 2 : 1)} ${units[index]}`; };
          const open = () => { render(); root.classList.add('is-open'); trigger.setAttribute('aria-expanded','true'); panel.setAttribute('aria-hidden','false'); };
          const shut = () => { root.classList.remove('is-open'); trigger.setAttribute('aria-expanded','false'); panel.setAttribute('aria-hidden','true'); };
          trigger.addEventListener('click', open); close.addEventListener('click', shut); document.addEventListener('keydown', event => { if (event.key === 'Escape') shut(); });
        })();
      JS
    end
  end
end
