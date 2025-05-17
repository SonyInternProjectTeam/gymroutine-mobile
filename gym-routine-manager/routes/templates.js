const express = require('express');
const router = express.Router();
const templateService = require('../services/template-service');

// Firebase 연결 상태 확인 (check=true 쿼리 파라미터가 있을 때)
router.get('/', async (req, res) => {
  try {
    // 연결 확인 요청인 경우
    if (req.query.check === 'true') {
      const isConnected = await templateService.checkConnection();
      if (isConnected) {
        return res.json({ connected: true });
      } else {
        return res.status(500).json({ connected: false, error: 'Firebase 연결 실패' });
      }
    }

    // 일반 조회 요청
    const templates = await templateService.getAllTemplates();
    res.json(templates);
  } catch (error) {
    console.error('템플릿 목록 조회 중 오류:', error);
    res.status(500).json({ error: '템플릿 목록을 불러오는 중 오류가 발생했습니다.' });
  }
});

// ID로 템플릿 조회
router.get('/:id', async (req, res) => {
  try {
    const template = await templateService.getTemplateById(req.params.id);
    
    if (!template) {
      return res.status(404).json({ message: '템플릿을 찾을 수 없습니다.' });
    }
    
    res.json(template);
  } catch (error) {
    console.error(`템플릿 조회 중 오류 (ID: ${req.params.id}):`, error);
    res.status(500).json({ error: '템플릿을 불러오는 중 오류가 발생했습니다.' });
  }
});

// 새 템플릿 생성
router.post('/', async (req, res) => {
  try {
    const newTemplate = await templateService.createTemplate(req.body);
    res.status(201).json(newTemplate);
  } catch (error) {
    if (error.message === '이미 사용 중인 템플릿 ID입니다.') {
      return res.status(400).json({ message: error.message });
    }
    
    console.error('템플릿 생성 중 오류:', error);
    res.status(500).json({ error: '템플릿 생성 중 오류가 발생했습니다.' });
  }
});

// 템플릿 수정
router.put('/:id', async (req, res) => {
  try {
    const updatedTemplate = await templateService.updateTemplate(req.params.id, req.body);
    res.json(updatedTemplate);
  } catch (error) {
    if (error.message === '템플릿을 찾을 수 없습니다.') {
      return res.status(404).json({ message: error.message });
    }
    
    console.error(`템플릿 수정 중 오류 (ID: ${req.params.id}):`, error);
    res.status(500).json({ error: '템플릿 수정 중 오류가 발생했습니다.' });
  }
});

// 템플릿 삭제
router.delete('/:id', async (req, res) => {
  try {
    const deletedTemplate = await templateService.deleteTemplate(req.params.id);
    res.json(deletedTemplate);
  } catch (error) {
    if (error.message === '템플릿을 찾을 수 없습니다.') {
      return res.status(404).json({ message: error.message });
    }
    
    console.error(`템플릿 삭제 중 오류 (ID: ${req.params.id}):`, error);
    res.status(500).json({ error: '템플릿 삭제 중 오류가 발생했습니다.' });
  }
});

module.exports = router; 