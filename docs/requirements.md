# 要件定義書

## プロジェクト概要
「後で読む」サービス（Pocketクローン）を構築する。
データストアとしてGoogle Spreadsheetを利用し、サーバーレスかつ低コストで運用可能なシステムを目指す。

## 機能要件

### 1. 記事管理
- **URL登録**: 任意のWebページのURLを保存できること。
- **記事一覧表示**: 保存した記事を一覧で確認できること。
- **既読管理**: 読んだ記事を既読（アーカイブ）にできること。
- **削除**: 記事を削除できること。

### 2. 自動化・定期実行
- **更新チェック**: 登録されたURLの内容に変更がないか定期的にチェックする機能。
- **RSS自動登録**: 指定したRSSフィードから新着記事を自動的に取得・登録する機能。

### 3. プラットフォーム対応
- **Android / iOS**: 専用アプリとして動作し、他アプリからの「共有」機能でURLを登録できること。
- **Webブラウザ**: GASのWebアプリURLに直接アクセスし、記事一覧を閲覧・アーカイブできること（Flutter Webは使用しない）。

## 技術スタック

### バックエンド
- **Google Apps Script (GAS)**
    - データベース: Google Spreadsheet
    - API: `doGet` (JSON/HTML), `doPost` (JSON)
    - Web UI: `HtmlService` を利用した簡易ビューアー
    - 定期実行: GASのトリガー機能（Time-driven triggers）

### フロントエンド (Mobile)
- **Flutter**
    - 対応プラットフォーム: Android, iOS
    - 状態管理: 標準のStatefulWidget
    - 通信: `http` パッケージ

## データ構造 (Google Spreadsheet)

### Articles シート
| カラム | 説明 |
| --- | --- |
| ID | 一意なID (UUID) |
| URL | 記事のURL |
| Title | 記事タイトル |
| AddedDate | 追加日時 |
| LastChecked | 最終更新確認日時 |
| ContentHash | コンテンツのハッシュ値（更新検知用） |
| IsRead | 既読フラグ (TRUE/FALSE) |
| Tags | タグ（将来拡張用） |

### RSS シート
| カラム | 説明 |
| --- | --- |
| FeedURL | RSSフィードのURL |
| LastChecked | 最終取得日時 |
