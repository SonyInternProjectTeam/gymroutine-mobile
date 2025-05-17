const { addDoc, getDocs, query, where, Timestamp } = require('firebase/firestore');
const { templatesCollection } = require('../config/firebase');
const templatesData = require('../data/templates');

/**
 * 템플릿 데이터를 Firebase에 업로드하는 함수
 */
async function uploadTemplates() {
  try {
    console.log('Firebase에 템플릿 데이터 업로드 시작...');
    
    // 기존 데이터를 변환하여 업로드
    for (const template of templatesData) {
      console.log(`템플릿 처리 중: ${template.templateId} - ${template.name}`);
      
      // 템플릿 ID로 기존 문서 확인
      const q = query(templatesCollection, where('templateId', '==', template.templateId));
      const querySnapshot = await getDocs(q);
      
      // 중복 체크
      if (!querySnapshot.empty) {
        console.log(`템플릿 ID ${template.templateId}은(는) 이미 존재합니다. 건너뜁니다.`);
        continue;
      }
      
      // createdAt을 Firebase Timestamp로 변환
      const firestoreTemplate = {
        ...template,
        createdAt: Timestamp.fromDate(new Date())
      };
      
      // 문서 추가
      const docRef = await addDoc(templatesCollection, firestoreTemplate);
      console.log(`템플릿 추가 완료: ${template.name} (ID: ${docRef.id})`);
    }
    
    console.log('모든 템플릿 데이터 업로드 완료!');
  } catch (error) {
    console.error('템플릿 업로드 중 오류 발생:', error);
  }
}

// 스크립트 실행
uploadTemplates()
  .then(() => {
    console.log('스크립트 실행 완료.');
    process.exit(0);
  })
  .catch(error => {
    console.error('스크립트 실행 중 오류 발생:', error);
    process.exit(1);
  }); 