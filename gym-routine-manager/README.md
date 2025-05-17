# ジムルーティンマネージャー

トレーニングルーティンとテンプレートを管理するためのウェブアプリケーションです。

## 機能

-   トレーニングルーティンテンプレートの閲覧、作成、編集、削除
-   各テンプレートに複数のエクササイズを追加可能
-   各エクササイズに複数のセットを設定可能
-   テンプレートタイプ、難易度、期間の設定
-   テンプレート予約曜日の設定

## インストール方法

1. リポジトリのクローン

```
git clone <repository-url>
cd gym-routine-manager
```

2. 依存関係のインストール

```
npm install
```

3. 環境変数の設定

`.env.example`ファイルをコピーして`.env`ファイルを作成し、必要な Firebase 情報を入力します：

```
cp .env.example .env
```

そして、`.env`ファイルを開いて次の値を設定します：

```
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_APP_ID=your_app_id
```

4. サーバーの実行

```
npm start
```

開発モードで実行するには：

```
npm run dev
```

## 使用方法

1. ウェブブラウザで`http://localhost:3000`にアクセス
2. 左側のサイドバーでテンプレート一覧を確認
3. 「新しいテンプレートを作成」ボタンをクリックして新しいテンプレートを作成
4. 各テンプレートをクリックして詳細情報を確認および編集/削除

## 技術スタック

-   Node.js
-   Express.js
-   HTML, CSS, JavaScript
-   Bootstrap 5
-   Firebase Firestore

## データ構造

テンプレート例：

```
{
  "templateId": "template_002",
  "name": "Upper Body Strength",
  "isRoutine": true,
  "scheduledDays": ["Tuesday", "Thursday"],
  "exercises": [
    {
      "part": "chest",
      "name": "benchpress",
      "key": "benchpress",
      "restTime": "90",
      "Sets": [
        { "reps": 8, "weight": 60 },
        { "reps": 6, "weight": 65 },
        { "reps": 4, "weight": 70 }
      ]
    },
    // その他のエクササイズ...
  ],
  "Notes": "中級者向け上半身強化ルーティン",
  "isPremium": false,
  "level": "Intermediate",
  "duration": "6 weeks"
}
```
