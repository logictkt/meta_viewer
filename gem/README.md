# MetaViewer

`meta_viewer` は、表示中の Rails ページにある SEO 用のメタ情報をブラウザ上で確認するための development-first の gem です。画面右中央の **メタチェック** を押すと、右側からパネルが開きます。

確認できるもの:

- title、文字コード、現在の URL
- description、robots、viewport などの標準 meta タグ
- Open Graph、X (Twitter) Card のタグ
- canonical URL、hreflang
- `og:image` / `twitter:image` のプレビュー、実画像サイズ、アスペクト比

## インストール

この gem は RubyGems には公開していません。Rails アプリケーションからローカルパスで参照します。`path` は Rails アプリケーションの `Gemfile` からこのリポジトリへの相対パスに置き換えてください。

```ruby
gem "meta_viewer", path: "../meta_viewer/gem", group: :development
```

次に Rails アプリケーション側で `bundle install` を実行してください。Rails Engine として自動的に有効になるため、レイアウトへの追記は不要です。

## 有効な環境

既定では development でだけ表示されます。staging などで使う場合は、初期化ファイルで明示的に許可してください。

```ruby
# config/initializers/meta_viewer.rb
MetaViewer.configure do |config|
  config.environments = %w[development staging]
end
```

## ボタン位置

既定の位置は右中央です。初期化ファイルで、次の 6 箇所から選べます: `:right_top`、`:right_bottom`、`:right_center`、`:left_top`、`:left_bottom`、`:left_center`。

```ruby
# config/initializers/meta_viewer.rb
MetaViewer.configure do |config|
  config.button_position = :left_bottom
end
```

ボタンの位置だけを変更します。情報パネルはどの設定でも従来どおり画面右側から開きます。

すべての環境で有効にする場合は以下です。ただし、公開環境ではページの SEO 情報や URL が訪問者に見えるため推奨しません。

```ruby
MetaViewer.configure do |config|
  config.enabled = true
end
```

環境ごとに独自条件を設けることもできます。

```ruby
MetaViewer.configure do |config|
  config.enabled = ->(environment) { environment.to_s == "staging" && ENV["META_VIEWER"] == "1" }
end
```

## 仕組み

HTML レスポンスの `</body>` の直前に、小さなパネルを注入します。パネルを開いた時点の DOM を検査するため、JavaScript により後から設定されたタグも確認できます。HTML 以外、圧縮済みレスポンス、無効な環境のレスポンスには何も追加しません。
