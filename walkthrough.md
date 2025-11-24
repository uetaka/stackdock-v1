# 開発・セットアップガイド

このドキュメントでは、Stackdockの開発環境セットアップ、開発フロー、および検証手順について説明します。

## セットアップ

### 前提条件
- Flutter SDK
- Android SDK (Android開発の場合)
- Google アカウント (バックエンド用)

### 環境構築手順

1. **リポジトリのクローン**
   ```bash
   git clone <repository-url>
   cd stackdock-v1
   ```

2. **環境変数の設定**
   `setup_env.sh` を使用して、Android SDKへのパスなどの環境変数を設定できます。
   ```bash
   source setup_env.sh
   ```

3. **依存関係のインストール**
   ```bash
   cd stackdock
   flutter pub get
   ```

4. **バックエンドのデプロイ**
   `backend/README.md` の手順に従って、Google Apps Scriptをデプロイしてください。

## 開発フロー

### アプリの実行
```bash
cd stackdock
flutter run
```

### テストの実行
```bash
cd stackdock
flutter test
```

## 検証手順

### 動作確認
1. アプリを起動し、設定画面でGASのWeb App URLを入力します。
2. 記事のURLを保存し、スプレッドシートに反映されることを確認します。
3. RSSフィードを登録し、記事が取得できることを確認します。
