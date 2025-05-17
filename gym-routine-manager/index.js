const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// ミドルウェア設定
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// 基本ルート
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

// APIルート
app.use('/api/templates', require('./routes/templates'));
app.use('/api/firebase', require('./routes/firebase'));
app.use('/api/exercises', require('./routes/exercises'));

// ヘルスチェックエンドポイント
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'gym-routine-manager', time: new Date().toISOString() });
});

// サーバー起動
app.listen(PORT, () => {
  console.log(`サーバーが http://localhost:${PORT} で実行中です。`);
  console.log(`Firebaseに接続されたテンプレートマネージャーが準備完了しました。`);
}); 