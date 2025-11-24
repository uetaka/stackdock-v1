# WSLへのAndroid SDKインストール手順

WSL環境でAndroidアプリをビルドするためのSDKセットアップ手順です。

## 1. 必要なパッケージのインストール
```bash
sudo apt-get update
sudo apt-get install -y unzip zip openjdk-17-jdk
```

## 2. Android SDKのインストール
ホームディレクトリにSDKをインストールします。

```bash
# ディレクトリ作成
mkdir -p ~/android-sdk/cmdline-tools

# コマンドラインツールのダウンロード
cd ~/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip

# 解凍と配置（この階層構造が重要です）
unzip tools.zip
mv cmdline-tools latest
rm tools.zip
```

## 3. 環境変数の設定
`~/.bashrc` (または `~/.zshrc`) に以下を追記します。

```bash
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
```

または、プロジェクトルートにある `setup_env.sh` を利用することもできます。
```bash
source setup_env.sh
```

設定を反映させます。
```bash
source ~/.bashrc
```

## 4. SDKコンポーネントのインストール
ライセンスに同意して必要なツールをインストールします。

```bash
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

## 5. Flutterの設定
FlutterにSDKの場所を教えます。

```bash
flutter config --android-sdk ~/android-sdk
```

## 6. 確認
```bash
flutter doctor
```
全てのチェックが緑色になれば完了です。

## トラブルシューティング (WSL)

もし `flutter doctor` で `adb` 関連のエラーが出る場合や、Windows側のエミュレーターが見つからない場合は、以下のコマンドでWSLの `adb` をWindowsの `adb.exe` に置き換えてください（推奨）。

```bash
# 既存のadbをバックアップ
mv ~/android-sdk/platform-tools/adb ~/android-sdk/platform-tools/adb.linux

# Windowsのadb.exeへのシンボリックリンクを作成
# ※ パスは環境に合わせて変更してください
ln -s /mnt/c/Users/uetaka/AppData/Local/Android/Sdk/platform-tools/adb.exe ~/android-sdk/platform-tools/adb
```
これにより、ネットワーク設定なしでWindows側のエミュレーターに接続できます。
