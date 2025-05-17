# 헬스 루틴 관리자

운동 루틴과 템플릿을 관리할 수 있는 웹 애플리케이션입니다.

## 기능

-   운동 루틴 템플릿 조회, 생성, 수정, 삭제
-   각 템플릿에 여러 운동 추가 가능
-   각 운동에 여러 세트 설정 가능
-   템플릿 타입, 난이도, 기간 설정
-   템플릿 예약 요일 설정

## 설치 방법

1. 저장소 클론

```
git clone <repository-url>
cd gym-routine-manager
```

2. 의존성 설치

```
npm install
```

3. 환경 변수 설정

`.env.example` 파일을 복사하여 `.env` 파일을 생성하고 필요한 Firebase 정보를 입력합니다:

```
cp .env.example .env
```

그리고 `.env` 파일을 열어 다음 값들을 설정합니다:

```
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_APP_ID=your_app_id
```

4. 서버 실행

```
npm start
```

개발 모드로 실행하려면:

```
npm run dev
```

## 사용 방법

1. 웹 브라우저에서 `http://localhost:3000` 접속
2. 왼쪽 사이드바에서 템플릿 목록 확인
3. "새 템플릿 만들기" 버튼을 클릭하여 새 템플릿 생성
4. 각 템플릿을 클릭하여 상세 정보 확인 및 수정/삭제

## 기술 스택

-   Node.js
-   Express.js
-   HTML, CSS, JavaScript
-   Bootstrap 5
-   Firebase Firestore

## 데이터 구조

템플릿 예시:

```
{
  "templateId": "template_002",
  "name": "Upper Body Strength",
  "isRoutine": true,
  "scheduledDays": ["Tuesday", "Thursday"],
  "exercises": [
    {
      "part": "chest",
      "name": "benchpress",
      "key": "benchpress",
      "restTime": "90",
      "Sets": [
        { "reps": 8, "weight": 60 },
        { "reps": 6, "weight": 65 },
        { "reps": 4, "weight": 70 }
      ]
    },
    // 더 많은 운동...
  ],
  "Notes": "중급자를 위한 상체 근력 루틴",
  "isPremium": false,
  "level": "Intermediate",
  "duration": "6 weeks"
}
```
