# Simutrans World Monitor

**このドキュメントはAIエージェントによって自動生成したものです。**

## 概要

Simutrans World Monitorは、交通シミュレーションゲーム「Simutrans」の様々な状態をDiscord経由で取得できるようにするためのDiscord botサーバーです。このbotを使用することで、ゲーム内のプレイヤー情報や路線情報などをDiscordから簡単に確認することができます。

## 仕組み

このシステムは以下の仕組みで動作します：

1. Simutransでは、特定のローカルファイル（JSONフォーマット）にコマンドを書き込むと、ゲームがそれを読み取り、結果を別のJSONファイルに出力します
2. Discord botは、ユーザーからコマンドを受け取ると、Simutransのコマンド入力用ファイルに必要なコマンドを書き込みます
3. botは出力ファイルの更新を監視し、更新が検出されるとその内容をDiscord上のユーザーに通知します

## プロジェクト構成

プロジェクトは主に2つの部分から構成されています：

1. **SimutransWorldMonitorServer**: Swift言語で実装されたDiscord botサーバー
2. **sqai_hm_monitor**: Simutrans側で動作するSquirrel言語のAIスクリプト

### SimutransWorldMonitorServer

Swift 6を使用して実装されたCLIツールで、以下の機能を提供します：

- Discord APIとの連携
- Simutransとのファイルベースの通信
- 多言語対応（英語・日本語）
- エラーハンドリング

### sqai_hm_monitor

Simutrans内で動作するAIスクリプトで、以下の機能を提供します：

- JSONフォーマットのコマンド処理
- ゲーム内プレイヤー情報の取得
- 各種交通路線情報の取得

## 設定方法

1. `SimutransWorldMonitorServer/config.json`ファイルを編集して、以下の設定を行います：
   - `inputFilePath`: Simutransへのコマンド入力ファイルのパス
   - `outputFilePath`: Simutransからの出力ファイルのパス
   - `timeout`: コマンドのタイムアウト時間（秒）
   - `discordToken`: Discord botのトークン
   - `defaultLanguage`: デフォルト言語（"en"または"ja"）
   - `supportedLanguages`: サポートする言語のリスト

設定例：
```json
{
    "inputFilePath": "/path/to/simutrans/file_io/cmd.json",
    "outputFilePath": "/path/to/simutrans/file_io/out.json",
    "timeout": 15.0,
    "discordToken": "YOUR_DISCORD_TOKEN",
    "defaultLanguage": "ja",
    "supportedLanguages": ["en", "ja"]
}
```

2. Simutrans側では、`sqai_hm_monitor`ディレクトリをSimutransのAIディレクトリにコピーします。

## 実行方法

1. SimutransWorldMonitorServerディレクトリで以下のコマンドを実行します：
```
swift run
```

2. Simutransを起動し、AIとして`sqai_hm_monitor`を選択します。

3. Discordで以下のコマンドが使用可能になります：
   - `/help` - ヘルプ情報を表示
   - `/language` - 優先言語を設定
   - `/players` - ゲーム内プレイヤーの一覧を取得
   - `/lines` - プレイヤーの路線一覧を取得

## 技術的詳細

### 要件

- Swift 6
- macOS, Windows, Linuxで動作（クロスプラットフォーム対応）
- SwiftTestingをテストフレームワークとして使用

### 通信プロトコル

#### プレイヤー一覧取得

入力JSONフォーマット：
```json
{
    "command": "get_player_list",
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
}
```

出力JSONフォーマット：
```json
{
    "command": "get_player_list",
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "result": [
        {"index": "0", "name": "MyAwesomeCompany"},
        {"index": "2", "name": "HisPunctualCompany"},
        {"index": "3", "name": "HerLazyCompany"}
    ]
}
```

#### 路線一覧取得

入力JSONフォーマット：
```json
{
    "command": "get_lines",
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "player_index": 0,
    "way_type": "road"
}
```

出力JSONフォーマット：
```json
{
    "command": "get_lines",
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "result": [
        {"id": 42, "name": "Elizabeth line"},
        {"id": 334, "name": "Piccadilly line"}
    ]
}
```

### エラーハンドリング

エラー発生時のJSONフォーマット：
```json
{
    "command": "error",
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "description": "エラーの説明"
}
```

### 注意事項

- 入力ファイルに書かれたコマンドがSimutransによって処理されると、入力ファイルの中身は空になります。入力ファイルに中身がある場合はまだSimutransがそれを処理できていないので、追加で書き込むのではなく空になるのを待つ必要があります。
- Simutransは任意のタイミングで出力ファイルに書き込みを行います。出力ファイルの中身を処理する前に入力ファイルに次のコマンドを書き込むと、出力ファイルが次のコマンドの結果で即時に上書きされることがあります。
- 出力ファイルへの結果出力には時間がかかることがあります。デフォルトでは15秒をタイムアウトとしています。
- 出力JSONには常に「id」プロパティが含まれており、このbotサーバーが発行したIDと一致する場合のみ、その出力を有効なレスポンスとして扱います。
