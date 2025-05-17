const { addDoc, getDocs, query, where, Timestamp } = require('firebase/firestore');
const { exercisesCollection } = require('../config/firebase');
const exercisesData = require('../data/exercises');

/**
 * 운동 데이터를 Firebase에 업로드하는 함수
 */
async function uploadExercises() {
  try {
    console.log('Firebase에 운동 데이터 업로드 시작...');
    
    // 기존 데이터를 변환하여 업로드
    for (const exercise of exercisesData) {
      console.log(`운동 처리 중: ${exercise.key} - ${exercise.name}`);
      
      // 운동 key로 기존 문서 확인
      const q = query(exercisesCollection, where('key', '==', exercise.key));
      const querySnapshot = await getDocs(q);
      
      // 중복 체크
      if (!querySnapshot.empty) {
        console.log(`운동 key ${exercise.key}은(는) 이미 존재합니다. 건너뜁니다.`);
        continue;
      }
      
      // createdAt을 Firebase Timestamp로 변환
      const firestoreExercise = {
        ...exercise,
        createdAt: Timestamp.fromDate(new Date())
      };
      
      // 문서 추가
      const docRef = await addDoc(exercisesCollection, firestoreExercise);
      console.log(`운동 추가 완료: ${exercise.name} (ID: ${docRef.id})`);
    }
    
    console.log('모든 운동 데이터 업로드 완료!');
  } catch (error) {
    console.error('운동 업로드 중 오류 발생:', error);
  }
}

// 스크립트 실행
uploadExercises()
  .then(() => {
    console.log('스크립트 실행 완료.');
    process.exit(0);
  })
  .catch(error => {
    console.error('스크립트 실행 중 오류 발생:', error);
    process.exit(1);
  }); 