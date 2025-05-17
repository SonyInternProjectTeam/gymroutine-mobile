const { 
  collection, 
  getDocs, 
  getDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  query, 
  where, 
  Timestamp,
  limit 
} = require('firebase/firestore');
const { db, templatesCollection } = require('../config/firebase');

/**
 * Firebase 연결 상태 확인
 */
async function checkConnection() {
  try {
    // 간단한 쿼리를 실행하여 연결 상태 확인
    const q = query(templatesCollection, limit(1));
    await getDocs(q);
    return true;
  } catch (error) {
    console.error('Firebase 연결 상태 확인 중 오류:', error);
    return false;
  }
}

/**
 * 모든 템플릿 목록 조회
 */
async function getAllTemplates() {
  try {
    const querySnapshot = await getDocs(templatesCollection);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('템플릿 목록 조회 중 오류 발생:', error);
    throw error;
  }
}

/**
 * ID로 템플릿 조회
 */
async function getTemplateById(templateId) {
  try {
    const q = query(templatesCollection, where('templateId', '==', templateId));
    const querySnapshot = await getDocs(q);
    
    if (querySnapshot.empty) {
      return null;
    }
    
    return {
      id: querySnapshot.docs[0].id,
      ...querySnapshot.docs[0].data()
    };
  } catch (error) {
    console.error(`템플릿 조회 중 오류 발생 (ID: ${templateId}):`, error);
    throw error;
  }
}

/**
 * 새 템플릿 생성
 */
async function createTemplate(templateData) {
  try {
    // templateId 중복 확인
    const existingTemplate = await getTemplateById(templateData.templateId);
    if (existingTemplate) {
      throw new Error('이미 사용 중인 템플릿 ID입니다.');
    }
    
    // createdAt 설정
    const newTemplate = {
      ...templateData,
      createdAt: Timestamp.fromDate(new Date())
    };
    
    const docRef = await addDoc(templatesCollection, newTemplate);
    return {
      id: docRef.id,
      ...newTemplate
    };
  } catch (error) {
    console.error('템플릿 생성 중 오류 발생:', error);
    throw error;
  }
}

/**
 * 템플릿 수정
 */
async function updateTemplate(templateId, templateData) {
  try {
    // 템플릿 찾기
    const template = await getTemplateById(templateId);
    if (!template) {
      throw new Error('템플릿을 찾을 수 없습니다.');
    }
    
    // 수정할 데이터 준비 (createdAt과 templateId는 유지)
    const updatedTemplate = {
      ...templateData,
      templateId: template.templateId,
      createdAt: template.createdAt
    };
    
    // 문서 ID로 참조 생성
    const docRef = doc(db, 'Templates', template.id);
    
    // 문서 업데이트
    await updateDoc(docRef, updatedTemplate);
    
    return {
      id: template.id,
      ...updatedTemplate
    };
  } catch (error) {
    console.error(`템플릿 수정 중 오류 발생 (ID: ${templateId}):`, error);
    throw error;
  }
}

/**
 * 템플릿 삭제
 */
async function deleteTemplate(templateId) {
  try {
    // 템플릿 찾기
    const template = await getTemplateById(templateId);
    if (!template) {
      throw new Error('템플릿을 찾을 수 없습니다.');
    }
    
    // 문서 ID로 참조 생성
    const docRef = doc(db, 'Templates', template.id);
    
    // 문서 삭제
    await deleteDoc(docRef);
    
    return template;
  } catch (error) {
    console.error(`템플릿 삭제 중 오류 발생 (ID: ${templateId}):`, error);
    throw error;
  }
}

module.exports = {
  checkConnection,
  getAllTemplates,
  getTemplateById,
  createTemplate,
  updateTemplate,
  deleteTemplate
}; 