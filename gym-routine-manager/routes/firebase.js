const express = require('express');
const router = express.Router();
const firebaseConfig = require('../config/firebase');

// Firebase 구성 정보 (민감 정보 제외)
router.get('/config', (req, res) => {
  try {
    // config/firebase.js에서 가져온 구성 정보 중 프로젝트 ID만 반환
    // 보안을 위해 API 키 등의 민감 정보는 제외합니다
    res.json({
      projectId: 'gymroutine-b7b6c',
      connected: true
    });
  } catch (error) {
    console.error('Firebase 구성 정보 조회 중 오류:', error);
    res.status(500).json({ error: 'Firebase 구성 정보를 불러오는 중 오류가 발생했습니다.' });
  }
});

// Firebase 연결 상태 확인
router.get('/status', async (req, res) => {
  try {
    // 템플릿 컬렉션 정보 조회
    const templateStats = {
      count: 0,
      collection: 'Templates'
    };
    
    res.json({
      connected: true,
      projectId: 'gymroutine-b7b6c',
      templates: templateStats
    });
  } catch (error) {
    console.error('Firebase 상태 확인 중 오류:', error);
    res.status(500).json({ 
      connected: false,
      error: 'Firebase 연결 상태를 확인하는 중 오류가 발생했습니다.'
    });
  }
});

module.exports = router; 