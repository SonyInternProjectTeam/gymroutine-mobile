// 전역 변수
let templates = [];
let currentTemplate = null;
let isEditing = false;
let isFirebaseConnected = false;

// 글로벌 변수
let currentExerciseId;
let exerciseSearchModal;

// DOM 요소
const templateList = document.querySelector('.template-list');
const detailView = document.getElementById('detail-view');
const templateForm = document.getElementById('template-form');
const templateTitle = document.getElementById('template-title');
const editTemplateBtn = document.getElementById('edit-template');
const deleteTemplateBtn = document.getElementById('delete-template');
const viewTemplatesBtn = document.getElementById('view-templates');
const createTemplateBtn = document.getElementById('create-template');
const confirmDeleteBtn = document.getElementById('confirm-delete');
const refreshBtn = document.getElementById('refresh-templates');
const firebaseStatusBtn = document.getElementById('firebase-status');
const templateCountEl = document.getElementById('template-count');
const templateLoadingEl = document.querySelector('.template-loading');
const templateErrorEl = document.querySelector('.template-error');

// 모달
const confirmModal = new bootstrap.Modal(document.getElementById('confirmModal'));
const firebaseStatusModal = new bootstrap.Modal(document.getElementById('firebaseStatusModal'));

// 이벤트 리스너 등록
document.addEventListener('DOMContentLoaded', init);
viewTemplatesBtn.addEventListener('click', showTemplateList);
createTemplateBtn.addEventListener('click', showCreateForm);
editTemplateBtn.addEventListener('click', showEditForm);
deleteTemplateBtn.addEventListener('click', () => confirmModal.show());
confirmDeleteBtn.addEventListener('click', deleteTemplate);
refreshBtn.addEventListener('click', refreshTemplates);
firebaseStatusBtn.addEventListener('click', showFirebaseStatus);

// 페이지 로드 시 모달 초기화
document.addEventListener('DOMContentLoaded', function() {
  exerciseSearchModal = new bootstrap.Modal(document.getElementById('exerciseSearchModal'));

  // 운동 검색 이벤트 리스너
  document.getElementById('search-exercise-btn').addEventListener('click', searchExercises);
  document.getElementById('exercise-search-input').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
      searchExercises();
    }
  });

  // 부위 필터 클릭 이벤트
  document.querySelectorAll('.part-filter').forEach(button => {
    button.addEventListener('click', function() {
      const part = this.getAttribute('data-part');
      filterExercisesByPart(part);
    });
  });
});

// 초기화 함수
async function init() {
  showLoadingState(true);
  await checkFirebaseConnection();
  await loadTemplates();
  showLoadingState(false);
  renderTemplateList();
  updateTemplateCount();
}

// Firebase 연결 상태 확인
async function checkFirebaseConnection() {
  try {
    const response = await fetch('/api/templates?check=true');
    
    if (response.ok) {
      isFirebaseConnected = true;
      document.body.classList.add('firebase-connected');
      document.body.classList.remove('firebase-error');
      document.querySelector('.firebase-status-text').textContent = 'Firebase 연결됨';
    } else {
      throw new Error('Firebase 연결 실패');
    }
  } catch (error) {
    console.error('Firebase 연결 확인 중 에러:', error);
    isFirebaseConnected = false;
    document.body.classList.remove('firebase-connected');
    document.body.classList.add('firebase-error');
    document.querySelector('.firebase-status-text').textContent = 'Firebase 연결 오류';
  }
  
  updateFirebaseStatus();
  return isFirebaseConnected;
}

// Firebase 상태 업데이트
function updateFirebaseStatus() {
  const connectionStatus = document.querySelector('.firebase-connection-status');
  const projectId = document.querySelector('.firebase-project-id');
  
  if (isFirebaseConnected) {
    connectionStatus.textContent = '연결됨';
    connectionStatus.className = 'firebase-connection-status text-success';
    
    // 프로젝트 ID 표시 (Firebase 구성에서 가져옴)
    fetch('/api/firebase/config')
      .then(response => response.json())
      .then(config => {
        projectId.textContent = config.projectId || 'gymroutine-b7b6c';
      })
      .catch(() => {
        projectId.textContent = 'gymroutine-b7b6c';
      });
  } else {
    connectionStatus.textContent = '연결 오류';
    connectionStatus.className = 'firebase-connection-status text-danger';
    projectId.textContent = '알 수 없음';
  }
}

// Firebase 상태 모달 표시
function showFirebaseStatus() {
  updateFirebaseStatus();
  document.querySelector('.firebase-template-count').textContent = templates.length;
  firebaseStatusModal.show();
}

// 로딩 상태 표시
function showLoadingState(isLoading) {
  if (isLoading) {
    templateLoadingEl.style.display = 'block';
    templateList.style.opacity = '0.5';
  } else {
    templateLoadingEl.style.display = 'none';
    templateList.style.opacity = '1';
    
    // 에러 상태 체크
    templateErrorEl.style.display = isFirebaseConnected ? 'none' : 'block';
  }
}

// 템플릿 수 업데이트
function updateTemplateCount() {
  templateCountEl.textContent = templates.length;
  document.querySelector('.firebase-template-count').textContent = templates.length;
}

// 템플릿 새로고침
async function refreshTemplates() {
  showLoadingState(true);
  await loadTemplates();
  showLoadingState(false);
  renderTemplateList();
  updateTemplateCount();
  
  if (templates.length > 0) {
    showTemplateDetails(templates[0].templateId);
  } else {
    showEmptyState();
  }
}

// 빈 상태 표시
function showEmptyState() {
  templateTitle.textContent = '템플릿 상세 정보';
  editTemplateBtn.style.display = 'none';
  deleteTemplateBtn.style.display = 'none';
  detailView.style.display = 'block';
  templateForm.style.display = 'none';
  detailView.innerHTML = '<p class="text-muted">등록된 템플릿이 없습니다. 새 템플릿을 만드세요.</p>';
}

// 템플릿 불러오기
async function loadTemplates() {
  try {
    const response = await fetch('/api/templates');
    
    if (!response.ok) {
      throw new Error('템플릿 데이터를 불러오는데 실패했습니다.');
    }
    
    templates = await response.json();
    
    // Firebase Timestamp 객체를 Date로 변환 (필요한 경우)
    templates.forEach(template => {
      if (template.createdAt && template.createdAt._seconds) {
        template.createdAt = new Date(template.createdAt._seconds * 1000);
      }
    });
    
    // 생성일 기준 정렬 (최신순)
    templates.sort((a, b) => {
      const dateA = a.createdAt instanceof Date ? a.createdAt : new Date(0);
      const dateB = b.createdAt instanceof Date ? b.createdAt : new Date(0);
      return dateB - dateA;
    });
    
  } catch (error) {
    console.error('템플릿을 불러오는 중 에러 발생:', error);
    templateErrorEl.style.display = 'block';
    templates = [];
  }
}

// 템플릿 목록 렌더링
function renderTemplateList() {
  templateList.innerHTML = '';
  
  templates.forEach(template => {
    const li = document.createElement('li');
    li.className = 'list-group-item';
    li.textContent = template.name;
    li.dataset.id = template.templateId;
    
    li.addEventListener('click', () => {
      document.querySelectorAll('.list-group-item').forEach(item => {
        item.classList.remove('active');
      });
      li.classList.add('active');
      showTemplateDetails(template.templateId);
    });
    
    templateList.appendChild(li);
  });
}

// 템플릿 상세 정보 표시
async function showTemplateDetails(templateId) {
  try {
    const response = await fetch(`/api/templates/${templateId}`);
    currentTemplate = await response.json();
    
    templateTitle.textContent = currentTemplate.name;
    editTemplateBtn.style.display = 'inline-block';
    deleteTemplateBtn.style.display = 'inline-block';
    templateForm.style.display = 'none';
    detailView.style.display = 'block';
    
    detailView.innerHTML = `
      <div class="template-info">
        <h3>${currentTemplate.name} 
          <span class="badge bg-${currentTemplate.isPremium ? 'warning' : 'success'}">
            ${currentTemplate.isPremium ? 'Premium' : 'Free'}
          </span>
          <span class="badge bg-info">${currentTemplate.level}</span>
        </h3>
        <p>${currentTemplate.Notes}</p>
        <div class="row">
          <div class="col-md-6">
            <strong>루틴 타입:</strong> ${currentTemplate.isRoutine ? '루틴' : '단일 운동'}
          </div>
          <div class="col-md-6">
            <strong>기간:</strong> ${currentTemplate.duration}
          </div>
        </div>
        <div class="row mt-2">
          <div class="col-md-12">
            <strong>예정 요일:</strong> ${currentTemplate.scheduledDays.join(', ')}
          </div>
        </div>
      </div>
      
      <h4>운동 목록</h4>
      <div class="exercise-list">
        ${renderExercises(currentTemplate.exercises)}
      </div>
    `;
  } catch (error) {
    console.error('템플릿 상세 정보를 불러오는 중 에러 발생:', error);
    alert('템플릿 상세 정보를 불러오는 중 에러가 발생했습니다.');
  }
}

// 운동 목록 HTML 생성
function renderExercises(exercises) {
  if (!exercises || exercises.length === 0) {
    return '<p>등록된 운동이 없습니다.</p>';
  }
  
  return exercises.map((exercise, index) => `
    <div class="card exercise-card">
      <div class="card-body">
        <h5 class="card-title">
          ${exercise.name}
          <span class="badge bg-secondary">${exercise.part}</span>
          <small class="text-muted">휴식 시간: ${exercise.restTime}초</small>
        </h5>
        
        <table class="table table-sm sets-table">
          <thead>
            <tr>
              <th>세트</th>
              <th>반복 횟수</th>
              <th>무게 (kg)</th>
              ${exercise.Sets.some(set => set.duration) ? '<th>시간</th>' : ''}
            </tr>
          </thead>
          <tbody>
            ${exercise.Sets.map((set, setIndex) => `
              <tr>
                <td>${setIndex + 1}</td>
                <td>${set.reps}</td>
                <td>${set.weight}</td>
                ${set.duration ? `<td>${set.duration}</td>` : ''}
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    </div>
  `).join('');
}

// 템플릿 목록 보기
function showTemplateList() {
  viewTemplatesBtn.classList.add('active');
  createTemplateBtn.classList.remove('active');
  
  if (templates.length > 0) {
    // 첫 번째 템플릿 선택
    const firstTemplate = templates[0];
    document.querySelector(`[data-id="${firstTemplate.templateId}"]`)?.classList.add('active');
    showTemplateDetails(firstTemplate.templateId);
  } else {
    templateTitle.textContent = '템플릿 상세 정보';
    editTemplateBtn.style.display = 'none';
    deleteTemplateBtn.style.display = 'none';
    detailView.style.display = 'block';
    templateForm.style.display = 'none';
    detailView.innerHTML = '<p class="text-muted">등록된 템플릿이 없습니다. 새 템플릿을 만드세요.</p>';
  }
}

// 새 템플릿 생성 폼 표시
function showCreateForm() {
  isEditing = false;
  currentTemplate = null;
  
  viewTemplatesBtn.classList.remove('active');
  createTemplateBtn.classList.add('active');
  
  templateTitle.textContent = '새 템플릿 만들기';
  editTemplateBtn.style.display = 'none';
  deleteTemplateBtn.style.display = 'none';
  detailView.style.display = 'none';
  templateForm.style.display = 'block';
  
  renderTemplateForm();
}

// 템플릿 수정 폼 표시
function showEditForm() {
  isEditing = true;
  
  templateTitle.textContent = `${currentTemplate.name} 수정`;
  editTemplateBtn.style.display = 'none';
  deleteTemplateBtn.style.display = 'none';
  detailView.style.display = 'none';
  templateForm.style.display = 'block';
  
  renderTemplateForm();
}

// 템플릿 폼 렌더링
function renderTemplateForm() {
  const template = currentTemplate || {
    templateId: `template_${Date.now().toString().slice(-6)}`,
    name: '',
    isRoutine: true,
    scheduledDays: [],
    exercises: [],
    Notes: '',
    isPremium: false,
    level: 'Beginner',
    duration: ''
  };
  
  templateForm.innerHTML = `
    <form id="template-form-element">
      <div class="row">
        <div class="col-md-6">
          <div class="form-group">
            <label for="template-id">템플릿 ID</label>
            <input type="text" class="form-control" id="template-id" value="${template.templateId}" ${isEditing ? 'readonly' : ''} required>
          </div>
        </div>
        <div class="col-md-6">
          <div class="form-group">
            <label for="template-name">템플릿 이름</label>
            <input type="text" class="form-control" id="template-name" value="${template.name}" required>
          </div>
        </div>
      </div>
      
      <div class="row">
        <div class="col-md-6">
          <div class="form-group">
            <label for="template-type">타입</label>
            <select class="form-control" id="template-type">
              <option value="true" ${template.isRoutine ? 'selected' : ''}>루틴</option>
              <option value="false" ${!template.isRoutine ? 'selected' : ''}>단일 운동</option>
            </select>
          </div>
        </div>
        <div class="col-md-6">
          <div class="form-group">
            <label for="template-level">난이도</label>
            <select class="form-control" id="template-level">
              <option value="Beginner" ${template.level === 'Beginner' ? 'selected' : ''}>초급</option>
              <option value="Intermediate" ${template.level === 'Intermediate' ? 'selected' : ''}>중급</option>
              <option value="Advanced" ${template.level === 'Advanced' ? 'selected' : ''}>고급</option>
            </select>
          </div>
        </div>
      </div>
      
      <div class="row">
        <div class="col-md-6">
          <div class="form-group">
            <label for="template-duration">기간</label>
            <input type="text" class="form-control" id="template-duration" value="${template.duration}">
          </div>
        </div>
        <div class="col-md-6">
          <div class="form-group">
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="template-premium" ${template.isPremium ? 'checked' : ''}>
              <label class="form-check-label" for="template-premium">
                프리미엄
              </label>
            </div>
          </div>
        </div>
      </div>
      
      <div class="form-group">
        <label>예정 요일</label>
        <div class="row">
          ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map(day => `
            <div class="col-md-3 col-6">
              <div class="form-check">
                <input class="form-check-input" type="checkbox" value="${day}" id="day-${day.toLowerCase()}" ${template.scheduledDays.includes(day) ? 'checked' : ''}>
                <label class="form-check-label" for="day-${day.toLowerCase()}">${day}</label>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
      
      <div class="form-group">
        <label for="template-notes">메모</label>
        <textarea class="form-control" id="template-notes" rows="3">${template.Notes}</textarea>
      </div>
      
      <h4 class="mt-4">운동 목록</h4>
      <div id="exercises-container">
        ${template.exercises.map((exercise, index) => renderExerciseForm(exercise, index)).join('')}
      </div>
      
      <button type="button" class="btn btn-primary add-exercise-btn" onclick="addExerciseForm()">
        <i class="bi bi-plus-circle"></i> 운동 추가
      </button>
      
      <div class="mt-4 d-flex justify-content-end">
        <button type="button" class="btn btn-secondary me-2" onclick="cancelForm()">취소</button>
        <button type="submit" class="btn btn-success">저장</button>
      </div>
    </form>
  `;
  
  // 이벤트 리스너 등록
  document.getElementById('template-form-element').addEventListener('submit', saveTemplate);
  
  // 전역 함수 등록 (동적 폼 관리용)
  window.addExerciseForm = addExerciseForm;
  window.removeExerciseForm = removeExerciseForm;
  window.addSetForm = addSetForm;
  window.removeSetForm = removeSetForm;
  window.cancelForm = cancelForm;
}

// 운동 폼 렌더링
function renderExerciseForm(exercise = {}, index) {
  const exerciseId = Date.now() + index;
  const defaultExercise = {
    part: '',
    name: '',
    key: '',
    restTime: '60',
    Sets: [{ reps: 10, weight: 0 }],
    ...exercise
  };
  
  return `
    <div class="card mb-3 exercise-form" data-exercise-id="${exerciseId}">
      <div class="card-header d-flex justify-content-between align-items-center">
        <span>운동 #${index + 1}</span>
        <i class="bi bi-trash delete-exercise-btn" onclick="removeExerciseForm(${exerciseId})"></i>
      </div>
      <div class="card-body">
        <div class="row mb-3">
          <div class="col-12">
            <button type="button" class="btn btn-outline-secondary btn-sm w-100" onclick="openExerciseSearch(${exerciseId})">
              <i class="bi bi-search"></i> 운동 찾기
            </button>
          </div>
        </div>
      
        <div class="row">
          <div class="col-md-6">
            <div class="form-group">
              <label>운동 부위</label>
              <input type="text" class="form-control exercise-part" value="${defaultExercise.part}" required>
            </div>
          </div>
          <div class="col-md-6">
            <div class="form-group">
              <label>운동 이름</label>
              <input type="text" class="form-control exercise-name" value="${defaultExercise.name}" required>
            </div>
          </div>
        </div>
        
        <div class="row">
          <div class="col-md-6">
            <div class="form-group">
              <label>고유 키</label>
              <input type="text" class="form-control exercise-key" value="${defaultExercise.key}" required>
            </div>
          </div>
          <div class="col-md-6">
            <div class="form-group">
              <label>휴식 시간 (초)</label>
              <input type="number" class="form-control exercise-rest" value="${defaultExercise.restTime}" min="0" required>
            </div>
          </div>
        </div>
        
        <h6 class="mt-3">세트</h6>
        <div class="sets-container">
          ${defaultExercise.Sets.map((set, setIndex) => renderSetForm(exerciseId, set, setIndex)).join('')}
        </div>
        
        <button type="button" class="btn btn-sm btn-outline-primary mt-2" onclick="addSetForm(${exerciseId})">
          <i class="bi bi-plus-circle"></i> 세트 추가
        </button>
      </div>
    </div>
  `;
}

// 세트 폼 렌더링
function renderSetForm(exerciseId, set = {}, index) {
  const setId = Date.now() + index;
  const defaultSet = {
    reps: 10,
    weight: 0,
    duration: '',
    ...set
  };
  
  return `
    <div class="row mb-2 set-form" data-set-id="${setId}">
      <div class="col-md-3">
        <div class="input-group">
          <span class="input-group-text">세트 ${index + 1}</span>
        </div>
      </div>
      <div class="col-md-3">
        <div class="input-group">
          <span class="input-group-text">반복</span>
          <input type="number" class="form-control set-reps" value="${defaultSet.reps}" min="0" required>
        </div>
      </div>
      <div class="col-md-3">
        <div class="input-group">
          <span class="input-group-text">무게</span>
          <input type="number" class="form-control set-weight" value="${defaultSet.weight}" min="0" step="0.5" required>
        </div>
      </div>
      <div class="col-md-2">
        <div class="input-group">
          <input type="text" class="form-control set-duration" value="${defaultSet.duration}" placeholder="시간 (선택)">
        </div>
      </div>
      <div class="col-md-1 d-flex align-items-center">
        <i class="bi bi-trash delete-set-btn" onclick="removeSetForm(${exerciseId}, ${setId})"></i>
      </div>
    </div>
  `;
}

// 운동 폼 추가
function addExerciseForm() {
  const exercisesContainer = document.getElementById('exercises-container');
  const exerciseCount = exercisesContainer.querySelectorAll('.exercise-form').length;
  
  const newExerciseHtml = renderExerciseForm({}, exerciseCount);
  exercisesContainer.insertAdjacentHTML('beforeend', newExerciseHtml);
}

// 운동 폼 제거
function removeExerciseForm(exerciseId) {
  const exerciseForm = document.querySelector(`.exercise-form[data-exercise-id="${exerciseId}"]`);
  if (exerciseForm) {
    exerciseForm.remove();
  }
}

// 세트 폼 추가
function addSetForm(exerciseId) {
  const exerciseForm = document.querySelector(`.exercise-form[data-exercise-id="${exerciseId}"]`);
  const setsContainer = exerciseForm.querySelector('.sets-container');
  const setCount = setsContainer.querySelectorAll('.set-form').length;
  
  const newSetHtml = renderSetForm(exerciseId, {}, setCount);
  setsContainer.insertAdjacentHTML('beforeend', newSetHtml);
}

// 세트 폼 제거
function removeSetForm(exerciseId, setId) {
  const exerciseForm = document.querySelector(`.exercise-form[data-exercise-id="${exerciseId}"]`);
  const setForm = exerciseForm.querySelector(`.set-form[data-set-id="${setId}"]`);
  
  if (setForm) {
    // 마지막 세트는 삭제하지 않음
    const setsCount = exerciseForm.querySelectorAll('.set-form').length;
    if (setsCount > 1) {
      setForm.remove();
    } else {
      alert('최소 하나의 세트가 필요합니다.');
    }
  }
}

// 폼 취소
function cancelForm() {
  if (isEditing && currentTemplate) {
    // 수정 취소 시 상세 보기로 돌아감
    showTemplateDetails(currentTemplate.templateId);
  } else {
    // 생성 취소 시 템플릿 목록으로 돌아감
    showTemplateList();
  }
}

// 템플릿 저장
async function saveTemplate(event) {
  event.preventDefault();
  
  // 폼 데이터 수집
  const formData = {
    templateId: document.getElementById('template-id').value,
    name: document.getElementById('template-name').value,
    isRoutine: document.getElementById('template-type').value === 'true',
    level: document.getElementById('template-level').value,
    duration: document.getElementById('template-duration').value,
    isPremium: document.getElementById('template-premium').checked,
    Notes: document.getElementById('template-notes').value,
    scheduledDays: Array.from(document.querySelectorAll('input[type="checkbox"][id^="day-"]:checked')).map(el => el.value),
    exercises: []
  };
  
  // 운동 데이터 수집
  document.querySelectorAll('.exercise-form').forEach(exerciseEl => {
    const exercise = {
      part: exerciseEl.querySelector('.exercise-part').value,
      name: exerciseEl.querySelector('.exercise-name').value,
      key: exerciseEl.querySelector('.exercise-key').value,
      restTime: exerciseEl.querySelector('.exercise-rest').value,
      Sets: []
    };
    
    // 세트 데이터 수집
    exerciseEl.querySelectorAll('.set-form').forEach(setEl => {
      const set = {
        reps: parseInt(setEl.querySelector('.set-reps').value),
        weight: parseFloat(setEl.querySelector('.set-weight').value)
      };
      
      const duration = setEl.querySelector('.set-duration').value;
      if (duration) {
        set.duration = duration;
      }
      
      exercise.Sets.push(set);
    });
    
    formData.exercises.push(exercise);
  });
  
  try {
    const url = isEditing 
      ? `/api/templates/${currentTemplate.templateId}`
      : '/api/templates';
    
    const method = isEditing ? 'PUT' : 'POST';
    
    const response = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(formData)
    });
    
    if (response.ok) {
      await loadTemplates();
      renderTemplateList();
      
      const savedTemplate = await response.json();
      currentTemplate = savedTemplate;
      showTemplateDetails(savedTemplate.templateId);
      
      alert(isEditing ? '템플릿이 수정되었습니다.' : '새 템플릿이 생성되었습니다.');
    } else {
      const error = await response.json();
      throw new Error(error.message || '저장 중 오류가 발생했습니다.');
    }
  } catch (error) {
    console.error('템플릿 저장 중 에러 발생:', error);
    alert(error.message || '템플릿 저장 중 에러가 발생했습니다.');
  }
}

// 템플릿 삭제
async function deleteTemplate() {
  if (!currentTemplate) return;
  
  try {
    const response = await fetch(`/api/templates/${currentTemplate.templateId}`, {
      method: 'DELETE'
    });
    
    if (response.ok) {
      confirmModal.hide();
      
      await loadTemplates();
      renderTemplateList();
      
      // 삭제 후 목록 표시
      templateTitle.textContent = '템플릿 상세 정보';
      editTemplateBtn.style.display = 'none';
      deleteTemplateBtn.style.display = 'none';
      detailView.style.display = 'block';
      templateForm.style.display = 'none';
      
      if (templates.length > 0) {
        showTemplateDetails(templates[0].templateId);
      } else {
        detailView.innerHTML = '<p class="text-muted">등록된 템플릿이 없습니다. 새 템플릿을 만드세요.</p>';
      }
      
      alert('템플릿이 삭제되었습니다.');
    } else {
      const error = await response.json();
      throw new Error(error.message || '삭제 중 오류가 발생했습니다.');
    }
  } catch (error) {
    console.error('템플릿 삭제 중 에러 발생:', error);
    alert(error.message || '템플릿 삭제 중 에러가 발생했습니다.');
    confirmModal.hide();
  }
}

// 운동 검색 모달 열기
function openExerciseSearch(exerciseId) {
  currentExerciseId = exerciseId;
  document.getElementById('exercise-search-input').value = '';
  document.getElementById('exercise-search-results').innerHTML = '<div class="text-center p-3">운동을 검색하거나 부위를 선택하세요.</div>';
  
  // 활성화된 부위 필터 초기화
  document.querySelectorAll('.part-filter').forEach(btn => {
    btn.classList.remove('active');
  });
  document.querySelector('.part-filter[data-part="all"]').classList.add('active');
  
  exerciseSearchModal.show();
}

// 운동 검색 기능
async function searchExercises() {
  const keyword = document.getElementById('exercise-search-input').value.trim();
  if (!keyword) {
    return;
  }
  
  const resultsContainer = document.getElementById('exercise-search-results');
  const loadingIndicator = document.getElementById('exercise-search-loading');
  
  try {
    resultsContainer.style.display = 'none';
    loadingIndicator.style.display = 'block';
    
    const response = await fetch(`/api/exercises/search?keyword=${encodeURIComponent(keyword)}`);
    
    if (!response.ok) {
      throw new Error('검색 요청 실패');
    }
    
    const exercises = await response.json();
    displaySearchResults(exercises);
  } catch (error) {
    resultsContainer.innerHTML = `<div class="alert alert-danger">검색 중 오류가 발생했습니다: ${error.message}</div>`;
  } finally {
    loadingIndicator.style.display = 'none';
    resultsContainer.style.display = 'block';
  }
}

// 부위별 운동 필터링
async function filterExercisesByPart(part) {
  // 필터 버튼 활성화 상태 변경
  document.querySelectorAll('.part-filter').forEach(btn => {
    btn.classList.remove('active');
  });
  document.querySelector(`.part-filter[data-part="${part}"]`).classList.add('active');
  
  const resultsContainer = document.getElementById('exercise-search-results');
  const loadingIndicator = document.getElementById('exercise-search-loading');
  
  try {
    resultsContainer.style.display = 'none';
    loadingIndicator.style.display = 'block';
    
    let exercises;
    
    if (part === 'all') {
      const response = await fetch('/api/exercises');
      if (!response.ok) throw new Error('데이터 로드 실패');
      exercises = await response.json();
    } else {
      const response = await fetch(`/api/exercises/byPart/${part}`);
      if (!response.ok) throw new Error('데이터 로드 실패');
      exercises = await response.json();
    }
    
    displaySearchResults(exercises);
  } catch (error) {
    resultsContainer.innerHTML = `<div class="alert alert-danger">운동 로드 중 오류가 발생했습니다: ${error.message}</div>`;
  } finally {
    loadingIndicator.style.display = 'none';
    resultsContainer.style.display = 'block';
  }
}

// 검색 결과 표시
function displaySearchResults(exercises) {
  const resultsContainer = document.getElementById('exercise-search-results');
  
  if (!exercises || exercises.length === 0) {
    resultsContainer.innerHTML = '<div class="alert alert-info">검색 결과가 없습니다.</div>';
    return;
  }
  
  let html = '<div class="list-group">';
  
  exercises.forEach(exercise => {
    html += `
      <div class="exercise-search-item" onclick="selectExercise('${exercise.id}', '${exercise.key}', '${exercise.part}', '${exercise.name}')">
        <div class="d-flex justify-content-between align-items-center">
          <strong>${exercise.name}</strong>
          <span class="exercise-tag">${exercise.part}</span>
        </div>
        ${exercise.description ? `<small class="text-muted">${exercise.description}</small>` : ''}
      </div>
    `;
  });
  
  html += '</div>';
  resultsContainer.innerHTML = html;
}

// 운동 선택 
function selectExercise(id, key, part, name) {
  const exerciseForm = document.querySelector(`.exercise-form[data-exercise-id="${currentExerciseId}"]`);
  
  if (exerciseForm) {
    exerciseForm.querySelector('.exercise-key').value = key;
    exerciseForm.querySelector('.exercise-part').value = part;
    exerciseForm.querySelector('.exercise-name').value = name;
  }
  
  exerciseSearchModal.hide();
} 