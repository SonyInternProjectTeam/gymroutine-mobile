const express = require('express');
const router = express.Router();
const { 
  getDocs, 
  query, 
  where, 
  collection, 
  orderBy, 
  limit,
  startAfter,
  startAt,
  endAt
} = require('firebase/firestore');
const { db, exercisesCollection } = require('../config/firebase');

// 모든 운동 목록 조회
router.get('/', async (req, res) => {
  try {
    const snapshot = await getDocs(exercisesCollection);
    const exercises = [];
    
    snapshot.forEach(doc => {
      exercises.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json(exercises);
  } catch (error) {
    console.error('운동 목록 조회 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 특정 부위별 운동 목록 조회
router.get('/byPart/:part', async (req, res) => {
  try {
    const part = req.params.part;
    const q = query(exercisesCollection, where('part', '==', part));
    const snapshot = await getDocs(q);
    
    const exercises = [];
    snapshot.forEach(doc => {
      exercises.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json(exercises);
  } catch (error) {
    console.error('부위별 운동 조회 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 운동 검색 기능 (이름 또는 키워드로 검색)
router.get('/search', async (req, res) => {
  try {
    const { keyword } = req.query;
    
    if (!keyword) {
      return res.status(400).json({ error: '검색어를 입력해주세요.' });
    }
    
    // Firebase에서 직접적인 like 검색을 지원하지 않으므로,
    // 모든 운동을 가져와서 필터링 (참고: 대규모 DB에서는 비효율적)
    const snapshot = await getDocs(exercisesCollection);
    
    const exercises = [];
    const lowerKeyword = keyword.toLowerCase();
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const name = data.name.toLowerCase();
      const key = data.key.toLowerCase();
      const description = data.description ? data.description.toLowerCase() : '';
      
      if (name.includes(lowerKeyword) || key.includes(lowerKeyword) || description.includes(lowerKeyword)) {
        exercises.push({
          id: doc.id,
          ...data
        });
      }
    });
    
    res.json(exercises);
  } catch (error) {
    console.error('운동 검색 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router; 