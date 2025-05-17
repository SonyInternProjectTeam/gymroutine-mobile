# Firebase 연동 및 데이터 업로드 가이드

## Firebase 프로젝트 설정

1. [Firebase 콘솔](https://console.firebase.google.com/)에 로그인하세요.
2. "프로젝트 추가"를 클릭하고 새 프로젝트를 생성합니다.
3. 생성된 프로젝트에서 "Firestore Database"를 선택하고 데이터베이스를 생성합니다.
    - 시작 모드를 선택할 때는 "테스트 모드"를 선택하세요.
    - 나중에 실제 서비스에 맞게 보안 규칙을 수정할 수 있습니다.
4. 프로젝트 설정에서 웹 앱을 추가하고 SDK 구성 정보를 확인합니다.

## 구성 파일 설정

1. `config/firebase.js` 파일을 엽니다.
2. Firebase 콘솔에서 얻은 구성 정보를 복사하여 `firebaseConfig` 객체에 붙여넣습니다:

```javascript
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
};
```

## 템플릿 데이터 업로드

템플릿 데이터를 Firebase에 업로드하려면 다음 명령을 실행하세요:

```bash
npm run upload-templates
```

이 명령은 `data/templates.js` 파일의 모든 템플릿 데이터를 Firebase Firestore의 `Templates` 컬렉션에 업로드합니다.

## 서버 실행

Firebase 연동을 완료한 후 서버를 실행하려면:

```bash
npm start
```

또는 개발 모드로 실행하려면:

```bash
npm run dev
```

서버가 실행되면 `http://localhost:3000`에서 앱에 접속할 수 있습니다.

## 문제 해결

-   Firebase 연결에 문제가 있다면 구성 정보가 올바른지 확인하세요.
-   Firestore 규칙이 데이터 읽기/쓰기를 허용하는지 확인하세요.
-   네트워크 오류가 발생하는 경우 Firebase 콘솔에서 해당 서비스의 상태를 확인하세요.
