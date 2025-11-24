# Stackdock

Google Spreadsheetをバックエンドに利用した、自分専用の「後で読む」サービスです。
モバイル（Android/iOS）はFlutterアプリから、PC等のWebブラウザからはGASのWebページから利用します。

## プロジェクト構成

```
.
├── backend/                # Google Apps Script (GAS) コード
│   ├── Code.js            # バックエンドロジック
│   ├── index.html         # Webブラウザ用ビューアー
│   └── README.md          # デプロイ手順
├── docs/                   # ドキュメント
│   └── requirements.md    # 要件定義書
├── stackdock/              # Flutter アプリケーション
│   ├── lib/               # ソースコード
│   ├── android/           # Android設定
│   ├── ios/               # iOS設定
│   └── web/               # Web設定
└── walkthrough.md          # 開発・セットアップガイド
```

## 開発環境セットアップ (WSL)

WSL環境でAndroidアプリをビルドするには、Android SDKのインストールが必要です。
詳細は [docs/android_sdk_setup.md](docs/android_sdk_setup.md) を参照してください。

### Windows上のAndroidエミュレーターを使用する場合

1.  **Windows側**: エミュレーターを起動し、ADBサーバーを許可します。
    ```powershell
    adb -a nodaemon server start
    ```

2.  **WSL側**: 環境変数を設定し、Windowsに接続します。
    ```bash
    export ADB_SERVER_SOCKET=tcp:$(cat /etc/resolv.conf | grep nameserver | cut -d' ' -f2):5037
    adb devices
    ```
    ※ `ADB_SERVER_SOCKET` を設定することで、WSL側の `flutter run` が自動的にWindows側のADBを利用します。

## セットアップ

詳細は [walkthrough.md](./walkthrough.md) を参照してください。

1. **バックエンド**: `backend/Code.js` をGoogle Apps Scriptにデプロイし、Web App URLを取得します。
2. **フロントエンド**: `stackdock` ディレクトリでFlutterアプリを実行し、設定画面でGASのURLを入力します。

## 機能

- **記事保存**: URLを手動入力、または他アプリからの共有で保存。
- **更新チェック**: GASの定期実行トリガーにより、保存したページの更新を検知。
- **RSS購読**: 指定したRSSフィードから記事を自動収集。
