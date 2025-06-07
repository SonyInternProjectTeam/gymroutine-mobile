const express = require('express');
const router = express.Router();
const exerciseService = require('../services/exercise-service');

// 모든 운동 목록 조회 (페이지네이션, 검색, 필터링 지원)
router.get('/', async (req, res) => {
  try {
    const options = {
      page: parseInt(req.query.page) || 1,
      pageSize: parseInt(req.query.pageSize) || 20,
      sortBy: req.query.sortBy || 'name',
      order: req.query.order || 'asc',
      search: req.query.search || '',
      part: req.query.part || ''
    };

    const result = await exerciseService.getExercises(options);
    res.json(result);
  } catch (error) {
    console.error('운동 목록 조회 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 운동 통계 조회
router.get('/stats', async (req, res) => {
  try {
    const stats = await exerciseService.getExerciseStats();
    res.json(stats);
  } catch (error) {
    console.error('운동 통계 조회 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 특정 운동 조회 (ID로)
router.get('/:id', async (req, res) => {
  try {
    const exercise = await exerciseService.getExerciseById(req.params.id);
    res.json(exercise);
  } catch (error) {
    if (error.message.includes('찾을 수 없습니다')) {
      return res.status(404).json({ error: error.message });
    }
    console.error('운동 조회 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 새 운동 추가
router.post('/', async (req, res) => {
  try {
    const exercise = await exerciseService.createExercise(req.body);
    res.status(201).json({
      ...exercise,
      message: '운동이 성공적으로 추가되었습니다.'
    });
  } catch (error) {
    if (error.message.includes('필수 필드') || error.message.includes('이미 존재')) {
      return res.status(400).json({ error: error.message });
    }
    console.error('운동 추가 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 운동 수정
router.put('/:id', async (req, res) => {
  try {
    const exercise = await exerciseService.updateExercise(req.params.id, req.body);
    res.json({
      ...exercise,
      message: '운동이 성공적으로 수정되었습니다.'
    });
  } catch (error) {
    if (error.message.includes('필수 필드') || error.message.includes('이미 존재')) {
      return res.status(400).json({ error: error.message });
    }
    if (error.message.includes('찾을 수 없습니다')) {
      return res.status(404).json({ error: error.message });
    }
    console.error('운동 수정 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 운동 삭제
router.delete('/:id', async (req, res) => {
  try {
    const result = await exerciseService.deleteExercise(req.params.id);
    res.json(result);
  } catch (error) {
    if (error.message.includes('찾을 수 없습니다')) {
      return res.status(404).json({ error: error.message });
    }
    console.error('운동 삭제 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 특정 부위별 운동 목록 조회
router.get('/byPart/:part', async (req, res) => {
  try {
    const exercises = await exerciseService.getExercisesByPart(req.params.part);
    res.json(exercises);
  } catch (error) {
    console.error('부위별 운동 조회 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 운동 검색 기능
router.get('/search/query', async (req, res) => {
  try {
    const { keyword, limit } = req.query;
    
    if (!keyword) {
      return res.status(400).json({ error: '검색어를 입력해주세요.' });
    }
    
    const exercises = await exerciseService.searchExercises(keyword, limit ? parseInt(limit) : 20);
    res.json(exercises);
  } catch (error) {
    console.error('운동 검색 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// 벌크 운동 데이터 추가 (스크립트용)
router.post('/bulk', async (req, res) => {
  try {
    const { exercises } = req.body;
    
    if (!exercises || !Array.isArray(exercises)) {
      return res.status(400).json({ error: '운동 배열이 필요합니다.' });
    }
    
    const result = await exerciseService.bulkCreateExercises(exercises);
    res.json(result);
  } catch (error) {
    console.error('벌크 운동 추가 중 오류:', error);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router; 