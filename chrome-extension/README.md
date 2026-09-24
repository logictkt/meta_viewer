# Meta Viewer Chrome Extension

SEO メタ情報を現在のタブ上で確認する Manifest V3 拡張機能です。ページ内に常設ボタンは追加しません。Chrome のツールバーにある Meta Viewer アイコンを押すと、拡張機能の popup に情報を表示します。ページへ UI を挿入しないため、サイト側の CSS の影響を受けません。

パネルには title、description、robots、canonical、hreflang、Open Graph、X (Twitter) Card、ソーシャル画像のプレビューと寸法、h1〜h6 の見出し構造を表示します。

## 開発版を読み込む

1. Chrome で `chrome://extensions` を開きます。
2. **デベロッパーモード**を有効にします。
3. **パッケージ化されていない拡張機能を読み込む**を選びます。
4. この `chrome-extension` ディレクトリを選択します。
5. 対象ページを開き、ツールバーの拡張機能ボタンから Meta Viewer を押します。

popup の外側をクリックすると閉じます。`chrome://` など Chrome がスクリプト注入を許可しないページでは利用できません。
