const { 
    getDocs, 
    query, 
    where, 
    collection, 
    orderBy, 
    limit,
    doc,
    getDoc,
    addDoc,
    updateDoc,
    deleteDoc,
    startAfter
} = require('firebase/firestore');

const { db, exercisesCollection } = require('../config/firebase');

class ExerciseService {
    /**
     * 운동 목록 조회 (페이지네이션, 검색, 필터링, 정렬 지원)
     */
    async getExercises(options = {}) {
        const {
            page = 1,
            pageSize = 50,
            sortBy = 'name',
            order = 'asc',
            search = '',
            part = ''
        } = options;

        try {
            let q = query(exercisesCollection);

            // 부위 필터링
            if (part && part !== 'all') {
                q = query(q, where('part', '==', part));
            }

            // 검색 (이름으로)
            if (search) {
                // Firestore는 full-text search를 직접 지원하지 않으므로
                // 클라이언트 사이드에서 필터링하거나 별도 검색 솔루션 필요
                // 여기서는 간단한 시작 문자열 매칭 사용
                q = query(q, 
                    where('name', '>=', search),
                    where('name', '<=', search + '\uf8ff')
                );
            }

            // 정렬
            if (sortBy === 'name' || sortBy === 'part' || sortBy === 'createdAt') {
                q = query(q, orderBy(sortBy, order));
            }

            // 모든 문서 가져오기 (Firestore에서 offset 기반 페이지네이션은 비효율적)
            const snapshot = await getDocs(q);
            const allExercises = [];

            snapshot.forEach(doc => {
                allExercises.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            // 클라이언트 사이드 검색 (이름에 검색어 포함)
            let filteredExercises = allExercises;
            if (search && !search.match(/^[가-힣]/)) { // 한글이 아닌 경우만
                filteredExercises = allExercises.filter(exercise =>
                    exercise.name.toLowerCase().includes(search.toLowerCase()) ||
                    exercise.key.toLowerCase().includes(search.toLowerCase())
                );
            }

            // 페이지네이션 적용
            const startIndex = (page - 1) * pageSize;
            const endIndex = startIndex + pageSize;
            const paginatedExercises = filteredExercises.slice(startIndex, endIndex);

            return {
                exercises: paginatedExercises,
                currentPage: parseInt(page),
                pageSize: parseInt(pageSize),
                totalItems: filteredExercises.length,
                hasMore: endIndex < filteredExercises.length
            };
        } catch (error) {
            console.error('운동 목록 조회 중 오류:', error);
            throw error;
        }
    }

    /**
     * 특정 운동 조회
     */
    async getExerciseById(exerciseId) {
        try {
            const docRef = doc(exercisesCollection, exerciseId);
            const docSnap = await getDoc(docRef);

            if (!docSnap.exists()) {
                throw new Error('운동을 찾을 수 없습니다.');
            }

            return {
                id: docSnap.id,
                ...docSnap.data()
            };
        } catch (error) {
            console.error('운동 조회 중 오류:', error);
            throw error;
        }
    }

    /**
     * 운동 키로 검색
     */
    async getExerciseByKey(exerciseKey) {
        try {
            const q = query(exercisesCollection, where('key', '==', exerciseKey));
            const snapshot = await getDocs(q);

            if (snapshot.empty) {
                return null;
            }

            const doc = snapshot.docs[0];
            return {
                id: doc.id,
                ...doc.data()
            };
        } catch (error) {
            console.error('운동 키 검색 중 오류:', error);
            throw error;
        }
    }

    /**
     * 새 운동 추가
     */
    async createExercise(exerciseData) {
        try {
            const { key, name, description, detailedPart, part } = exerciseData;

            // 필수 필드 검증
            if (!key || !name || !part) {
                throw new Error('필수 필드가 누락되었습니다. (key, name, part는 필수입니다)');
            }

            // key 중복 확인
            const existingExercise = await this.getExerciseByKey(key);
            if (existingExercise) {
                throw new Error('이미 존재하는 운동 키입니다.');
            }

            // 새 운동 데이터 준비
            const newExercise = {
                key: key.trim(),
                name: name.trim(),
                description: description ? description.trim() : '',
                detailedPart: detailedPart ? detailedPart.trim() : '',
                part: part.trim(),
                createdAt: new Date(),
                updatedAt: new Date()
            };

            // Firestore에 추가
            const docRef = await addDoc(exercisesCollection, newExercise);

            return {
                id: docRef.id,
                ...newExercise
            };
        } catch (error) {
            console.error('운동 추가 중 오류:', error);
            throw error;
        }
    }

    /**
     * 운동 수정
     */
    async updateExercise(exerciseId, exerciseData) {
        try {
            const { key, name, description, detailedPart, part } = exerciseData;

            // 필수 필드 검증
            if (!key || !name || !part) {
                throw new Error('필수 필드가 누락되었습니다. (key, name, part는 필수입니다)');
            }

            // 문서 존재 확인
            const currentExercise = await this.getExerciseById(exerciseId);

            // key 중복 확인 (현재 문서 제외)
            if (currentExercise.key !== key) {
                const existingExercise = await this.getExerciseByKey(key);
                if (existingExercise && existingExercise.id !== exerciseId) {
                    throw new Error('이미 존재하는 운동 키입니다.');
                }
            }

            // 업데이트할 데이터 준비
            const updateData = {
                key: key.trim(),
                name: name.trim(),
                description: description ? description.trim() : '',
                detailedPart: detailedPart ? detailedPart.trim() : '',
                part: part.trim(),
                updatedAt: new Date()
            };

            // Firestore에서 업데이트
            const docRef = doc(exercisesCollection, exerciseId);
            await updateDoc(docRef, updateData);

            // 업데이트된 문서 반환
            return await this.getExerciseById(exerciseId);
        } catch (error) {
            console.error('운동 수정 중 오류:', error);
            throw error;
        }
    }

    /**
     * 운동 삭제
     */
    async deleteExercise(exerciseId) {
        try {
            // 문서 존재 확인
            await this.getExerciseById(exerciseId);

            // Firestore에서 삭제
            const docRef = doc(exercisesCollection, exerciseId);
            await deleteDoc(docRef);

            return { success: true, message: '운동이 성공적으로 삭제되었습니다.' };
        } catch (error) {
            console.error('운동 삭제 중 오류:', error);
            throw error;
        }
    }

    /**
     * 운동 통계 조회
     */
    async getExerciseStats() {
        try {
            const snapshot = await getDocs(exercisesCollection);
            const stats = {
                total: 0,
                chest: 0,
                back: 0,
                shoulders: 0,
                legs: 0,
                arms: 0,
                core: 0
            };

            snapshot.forEach(doc => {
                const data = doc.data();
                stats.total++;
                if (stats.hasOwnProperty(data.part)) {
                    stats[data.part]++;
                }
            });

            return stats;
        } catch (error) {
            console.error('운동 통계 조회 중 오류:', error);
            throw error;
        }
    }

    /**
     * 부위별 운동 조회
     */
    async getExercisesByPart(part) {
        try {
            const q = query(
                exercisesCollection,
                where('part', '==', part),
                orderBy('name', 'asc')
            );

            const snapshot = await getDocs(q);
            const exercises = [];

            snapshot.forEach(doc => {
                exercises.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            return exercises;
        } catch (error) {
            console.error('부위별 운동 조회 중 오류:', error);
            throw error;
        }
    }

    /**
     * 운동 검색 (이름 또는 키로)
     */
    async searchExercises(searchTerm, limit = 20) {
        try {
            // 모든 운동을 가져와서 클라이언트 사이드에서 검색
            // 실제 운영환경에서는 Algolia 등의 검색 서비스 사용 권장
            const snapshot = await getDocs(query(exercisesCollection, orderBy('name')));
            const allExercises = [];

            snapshot.forEach(doc => {
                allExercises.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            // 검색어로 필터링
            const filteredExercises = allExercises.filter(exercise =>
                exercise.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                exercise.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
                (exercise.description && exercise.description.toLowerCase().includes(searchTerm.toLowerCase()))
            );

            return filteredExercises.slice(0, limit);
        } catch (error) {
            console.error('운동 검색 중 오류:', error);
            throw error;
        }
    }

    /**
     * 벌크 운동 데이터 추가 (스크립트용)
     */
    async bulkCreateExercises(exercisesData) {
        try {
            const results = [];
            const errors = [];

            for (const exerciseData of exercisesData) {
                try {
                    const result = await this.createExercise(exerciseData);
                    results.push(result);
                } catch (error) {
                    errors.push({
                        exercise: exerciseData,
                        error: error.message
                    });
                }
            }

            return {
                success: results.length,
                errors: errors.length,
                results,
                errors
            };
        } catch (error) {
            console.error('벌크 운동 추가 중 오류:', error);
            throw error;
        }
    }
}

module.exports = new ExerciseService(); 