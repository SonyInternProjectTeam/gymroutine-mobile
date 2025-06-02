/**
 * Exercise CRUD 관리 JavaScript
 */

class ExerciseManager {
    constructor() {
        this.currentPage = 1;
        this.pageSize = 20;
        this.currentFilter = 'all';
        this.currentSort = 'name:asc';
        this.searchQuery = '';
        this.exercises = [];
        this.exerciseToDelete = null;
        
        this.initializeEventListeners();
        this.checkFirebaseStatus();
        this.loadExercises();
    }

    initializeEventListeners() {
        // 검색 및 필터 이벤트
        document.getElementById('search-input').addEventListener('input', (e) => {
            this.searchQuery = e.target.value;
            this.debounceSearch();
        });

        document.getElementById('search-btn').addEventListener('click', () => {
            this.loadExercises();
        });

        document.getElementById('sort-select').addEventListener('change', (e) => {
            this.currentSort = e.target.value;
            this.loadExercises();
        });

        // 부위 필터 버튼들
        document.querySelectorAll('.part-filter').forEach(button => {
            button.addEventListener('click', (e) => {
                document.querySelectorAll('.part-filter').forEach(btn => 
                    btn.classList.remove('active'));
                e.target.classList.add('active');
                this.currentFilter = e.target.dataset.part;
                this.currentPage = 1;
                this.loadExercises();
            });
        });

        // 운동 추가 버튼
        document.getElementById('add-exercise-btn').addEventListener('click', () => {
            this.showExerciseModal();
        });

        // 모달 저장 버튼
        document.getElementById('save-exercise-btn').addEventListener('click', () => {
            this.saveExercise();
        });

        // 삭제 확인 버튼
        document.getElementById('confirm-delete-btn').addEventListener('click', () => {
            this.deleteExercise();
        });

        // Firebase 상태 확인
        document.getElementById('firebase-status').addEventListener('click', () => {
            this.showFirebaseStatus();
        });

        // Enter 키로 검색
        document.getElementById('search-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.loadExercises();
            }
        });
    }

    debounceSearch() {
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.currentPage = 1;
            this.loadExercises();
        }, 500);
    }

    async checkFirebaseStatus() {
        try {
            const response = await fetch('/api/firebase/status');
            const data = await response.json();
            
            const indicator = document.querySelector('.firebase-indicator');
            const statusText = document.querySelector('.firebase-status-text');
            
            if (data.connected) {
                document.body.classList.add('firebase-connected');
                document.body.classList.remove('firebase-error');
            } else {
                document.body.classList.add('firebase-error');
                document.body.classList.remove('firebase-connected');
            }
        } catch (error) {
            console.error('Firebase 상태 확인 중 오류:', error);
            document.body.classList.add('firebase-error');
            document.body.classList.remove('firebase-connected');
        }
    }

    async loadExercises() {
        this.showLoading(true);
        
        try {
            const params = new URLSearchParams({
                page: this.currentPage,
                pageSize: this.pageSize,
                sortBy: this.currentSort.split(':')[0],
                order: this.currentSort.split(':')[1]
            });

            if (this.searchQuery) {
                params.append('search', this.searchQuery);
            }

            if (this.currentFilter && this.currentFilter !== 'all') {
                params.append('part', this.currentFilter);
            }

            const response = await fetch(`/api/exercises?${params}`);
            const data = await response.json();

            if (response.ok) {
                this.exercises = data.exercises;
                this.renderExercises();
                this.renderPagination(data);
                this.updateStats();
                this.showError(false);
            } else {
                throw new Error(data.error || '운동 데이터를 불러올 수 없습니다.');
            }
        } catch (error) {
            console.error('운동 로딩 중 오류:', error);
            this.showError(true, error.message);
        } finally {
            this.showLoading(false);
        }
    }

    renderExercises() {
        const tbody = document.getElementById('exercises-table-body');
        const noExercises = document.getElementById('no-exercises');
        
        if (this.exercises.length === 0) {
            tbody.innerHTML = '';
            noExercises.style.display = 'block';
            return;
        }

        noExercises.style.display = 'none';
        
        tbody.innerHTML = this.exercises.map(exercise => `
            <tr>
                <td><code>${this.escapeHtml(exercise.key)}</code></td>
                <td>${this.escapeHtml(exercise.name)}</td>
                <td><span class="exercise-tag">${this.translatePart(exercise.part)}</span></td>
                <td>${this.escapeHtml(exercise.detailedPart || '-')}</td>
                <td>${this.escapeHtml(exercise.description || '-')}</td>
                <td>
                    <div class="exercise-actions">
                        <button class="btn btn-sm btn-outline-primary" onclick="exerciseManager.editExercise('${exercise.id}')">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="exerciseManager.confirmDeleteExercise('${exercise.id}', '${this.escapeHtml(exercise.name)}')">
                            <i class="bi bi-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    }

    renderPagination(data) {
        const paginationControls = document.getElementById('pagination-controls');
        const totalPages = Math.ceil(data.totalItems / this.pageSize);
        
        if (totalPages <= 1) {
            paginationControls.innerHTML = '';
            return;
        }

        let paginationHTML = '';
        
        // Previous button
        if (this.currentPage > 1) {
            paginationHTML += `
                <li class="page-item">
                    <a class="page-link" href="#" onclick="exerciseManager.goToPage(${this.currentPage - 1})">前へ</a>
                </li>
            `;
        }

        // Page numbers
        const startPage = Math.max(1, this.currentPage - 2);
        const endPage = Math.min(totalPages, this.currentPage + 2);

        for (let i = startPage; i <= endPage; i++) {
            paginationHTML += `
                <li class="page-item ${i === this.currentPage ? 'active' : ''}">
                    <a class="page-link" href="#" onclick="exerciseManager.goToPage(${i})">${i}</a>
                </li>
            `;
        }

        // Next button
        if (this.currentPage < totalPages) {
            paginationHTML += `
                <li class="page-item">
                    <a class="page-link" href="#" onclick="exerciseManager.goToPage(${this.currentPage + 1})">次へ</a>
                </li>
            `;
        }

        paginationControls.innerHTML = paginationHTML;
    }

    async updateStats() {
        try {
            const response = await fetch('/api/exercises/stats');
            const stats = await response.json();
            
            document.getElementById('total-exercises').textContent = stats.total || 0;
            document.getElementById('chest-exercises').textContent = stats.chest || 0;
            document.getElementById('back-exercises').textContent = stats.back || 0;
            document.getElementById('legs-exercises').textContent = stats.legs || 0;
        } catch (error) {
            console.error('통계 업데이트 중 오류:', error);
        }
    }

    goToPage(page) {
        this.currentPage = page;
        this.loadExercises();
    }

    showExerciseModal(exercise = null) {
        const modal = new bootstrap.Modal(document.getElementById('exerciseModal'));
        const title = document.getElementById('exerciseModalTitle');
        const form = document.getElementById('exercise-form');
        
        if (exercise) {
            title.textContent = '運動編集';
            document.getElementById('exercise-id').value = exercise.id;
            document.getElementById('exercise-key').value = exercise.key;
            document.getElementById('exercise-name').value = exercise.name;
            document.getElementById('exercise-part').value = exercise.part;
            document.getElementById('exercise-detailed-part').value = exercise.detailedPart || '';
            document.getElementById('exercise-description').value = exercise.description || '';
        } else {
            title.textContent = '新規運動追加';
            form.reset();
            document.getElementById('exercise-id').value = '';
        }
        
        modal.show();
    }

    async saveExercise() {
        const exerciseId = document.getElementById('exercise-id').value;
        const exerciseData = {
            key: document.getElementById('exercise-key').value.trim(),
            name: document.getElementById('exercise-name').value.trim(),
            part: document.getElementById('exercise-part').value,
            detailedPart: document.getElementById('exercise-detailed-part').value.trim(),
            description: document.getElementById('exercise-description').value.trim()
        };

        // 기본 유효성 검사
        if (!exerciseData.key || !exerciseData.name || !exerciseData.part) {
            alert('필수 필드를 모두 입력해주세요.');
            return;
        }

        try {
            const url = exerciseId ? `/api/exercises/${exerciseId}` : '/api/exercises';
            const method = exerciseId ? 'PUT' : 'POST';
            
            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(exerciseData)
            });

            const result = await response.json();

            if (response.ok) {
                const modal = bootstrap.Modal.getInstance(document.getElementById('exerciseModal'));
                modal.hide();
                this.loadExercises();
                this.showSuccessMessage(exerciseId ? '운동이 수정되었습니다.' : '운동이 추가되었습니다.');
            } else {
                throw new Error(result.error || '저장 중 오류가 발생했습니다.');
            }
        } catch (error) {
            console.error('운동 저장 중 오류:', error);
            alert(error.message);
        }
    }

    editExercise(exerciseId) {
        const exercise = this.exercises.find(ex => ex.id === exerciseId);
        if (exercise) {
            this.showExerciseModal(exercise);
        }
    }

    confirmDeleteExercise(exerciseId, exerciseName) {
        this.exerciseToDelete = exerciseId;
        const modal = new bootstrap.Modal(document.getElementById('deleteConfirmModal'));
        modal.show();
    }

    async deleteExercise() {
        if (!this.exerciseToDelete) return;

        try {
            const response = await fetch(`/api/exercises/${this.exerciseToDelete}`, {
                method: 'DELETE'
            });

            const result = await response.json();

            if (response.ok) {
                const modal = bootstrap.Modal.getInstance(document.getElementById('deleteConfirmModal'));
                modal.hide();
                this.exerciseToDelete = null;
                this.loadExercises();
                this.showSuccessMessage('운동이 삭제되었습니다.');
            } else {
                throw new Error(result.error || '삭제 중 오류가 발생했습니다.');
            }
        } catch (error) {
            console.error('운동 삭제 중 오류:', error);
            alert(error.message);
        }
    }

    showFirebaseStatus() {
        const modal = new bootstrap.Modal(document.getElementById('firebaseStatusModal'));
        modal.show();
    }

    showLoading(show) {
        const loading = document.getElementById('exercise-loading');
        loading.style.display = show ? 'block' : 'none';
    }

    showError(show, message = '') {
        const error = document.getElementById('exercise-error');
        if (show) {
            error.textContent = message || 'データの読み込み中にエラーが発生しました。';
            error.style.display = 'block';
        } else {
            error.style.display = 'none';
        }
    }

    showSuccessMessage(message) {
        // Toast 알림 또는 간단한 알림으로 성공 메시지 표시
        const toast = document.createElement('div');
        toast.className = 'toast align-items-center text-white bg-success border-0';
        toast.style.position = 'fixed';
        toast.style.top = '20px';
        toast.style.right = '20px';
        toast.style.zIndex = '9999';
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        `;
        
        document.body.appendChild(toast);
        const toastBootstrap = new bootstrap.Toast(toast);
        toastBootstrap.show();
        
        // 3초 후 자동 제거
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 3000);
    }

    translatePart(part) {
        const translations = {
            'chest': '胸',
            'back': '背中',
            'shoulders': '肩',
            'legs': '脚',
            'arms': '腕',
            'core': 'コア'
        };
        return translations[part] || part;
    }

    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// 페이지 로드 시 초기화
let exerciseManager;
document.addEventListener('DOMContentLoaded', () => {
    exerciseManager = new ExerciseManager();
}); 