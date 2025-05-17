const { initializeApp } = require('firebase/app');
const { getFirestore, collection } = require('firebase/firestore');
require('dotenv').config();

// Firebase 구성
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

// Firebase 초기화
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// 환경 변수 체크 및 경고
if (!process.env.FIREBASE_API_KEY || !process.env.FIREBASE_APP_ID) {
  console.warn('⚠️  경고: Firebase 환경 변수가 설정되어 있지 않습니다.');
  console.warn('🔍 .env 파일을 생성하고 Firebase 설정을 추가하세요. (.env.example 참조)');
}

// Collections 참조
const templatesCollection = collection(db, 'Templates');
const exercisesCollection = collection(db, 'Exercises');

module.exports = {
  db,
  templatesCollection,
  exercisesCollection
}; 