# 업적 템플릿 Firebase 설정 가이드

## Firebase Console 직접 링크

### Firestore Database (업적 템플릿 컬렉션)
**직접 링크**: https://console.firebase.google.com/project/flutterhabitfit/firestore/data/~2Fachievement_templates

### Firestore Database (메인 페이지)
**직접 링크**: https://console.firebase.google.com/project/flutterhabitfit/firestore

---

## 업적 템플릿 추가 방법

### 1. Firebase Console 접속
위의 링크를 클릭하거나, 직접 접속:
1. [Firebase Console](https://console.firebase.google.com/)
2. 프로젝트 선택: **flutterhabitfit**
3. 왼쪽 메뉴에서 **Firestore Database** 클릭

### 2. 컬렉션 생성 (처음 한 번만)

**중요**: Firestore는 컬렉션이 자동으로 생성되지 않습니다. 첫 번째 문서를 추가하면 컬렉션이 자동으로 생성됩니다.

**방법 1: Firestore Database 메인 페이지에서**
1. Firestore Database 메인 페이지 접속: https://console.firebase.google.com/project/flutterhabitfit/firestore
2. **컬렉션 시작** 버튼 클릭 (처음이면) 또는 **컬렉션 추가** 버튼 클릭
3. 컬렉션 ID 입력: `achievement_templates`
4. 첫 번째 문서 ID 입력: `level_5` (또는 원하는 업적 ID)
5. 필드 추가 (아래 예시 참고)
6. **저장** 버튼 클릭

**방법 2: 데이터 탭에서 직접**
1. Firestore Database → **데이터** 탭 접속
2. 빈 화면에서 **컬렉션 시작** 버튼 클릭
3. 컬렉션 ID: `achievement_templates`
4. 문서 ID: `level_5`
5. 필드 추가 후 저장

### 3. 문서 추가
각 업적마다 문서를 추가하세요. 문서 구조:

#### 문서 ID 예시:
- `level_5`
- `level_10`
- `level_20`
- `level_30`
- `points_1000`
- `points_5000`
- `points_10000`
- `habit_7days` (7일 연속 습관 완료)
- `habit_30days` (30일 연속 습관 완료)
- `workout_first` (첫 운동 완료)
- 등등...

#### 필드 구조:

| 필드명 | 타입 | 값 예시 | 필수 |
|--------|------|---------|------|
| `title` | string | "첫 번째 레벨업" | ✅ |
| `description` | string | "레벨 5 달성" | ✅ |
| `icon` | string | "🎯" | ✅ |
| `pointsReward` | number | 50 | ✅ |
| `category` | string | "level" | ✅ |
| `requirements` | map | `{ "level": 5 }` | ❌ |
| `isSecret` | boolean | false | ❌ |

#### 카테고리 종류:
- `level`: 레벨 관련 업적
- `points`: 포인트 관련 업적
- `habit`: 습관 관련 업적
- `workout`: 운동 관련 업적
- `social`: 소셜 관련 업적
- `general`: 일반 업적

---

## 예시 문서들

### 예시 1: 레벨 업적
**문서 ID**: `level_5`
```json
{
  "title": "첫 번째 레벨업",
  "description": "레벨 5 달성",
  "icon": "🎯",
  "pointsReward": 50,
  "category": "level",
  "requirements": {
    "level": 5
  },
  "isSecret": false
}
```

### 예시 2: 포인트 업적
**문서 ID**: `points_1000`
```json
{
  "title": "첫 1000점",
  "description": "1000 포인트 달성",
  "icon": "💯",
  "pointsReward": 100,
  "category": "points",
  "requirements": {
    "points": 1000
  },
  "isSecret": false
}
```

### 예시 3: 습관 업적
**문서 ID**: `habit_7days`
```json
{
  "title": "일주일의 전사",
  "description": "7일 연속으로 습관을 완료하세요",
  "icon": "📅",
  "pointsReward": 75,
  "category": "habit",
  "requirements": {
    "streak": 7
  },
  "isSecret": false
}
```

### 예시 4: 운동 업적
**문서 ID**: `workout_first`
```json
{
  "title": "첫 걸음",
  "description": "첫 번째 운동을 완료하세요",
  "icon": "🏃",
  "pointsReward": 25,
  "category": "workout",
  "requirements": {
    "workoutCount": 1
  },
  "isSecret": false
}
```

---

## 빠른 추가 방법

1. **Firebase Console 접속**: https://console.firebase.google.com/project/flutterhabitfit/firestore/data/~2Fachievement_templates

2. **문서 추가** 버튼 클릭

3. **문서 ID 입력** (예: `level_5`)

4. **필드 추가**:
   - `title` (string) → "첫 번째 레벨업"
   - `description` (string) → "레벨 5 달성"
   - `icon` (string) → "🎯"
   - `pointsReward` (number) → 50
   - `category` (string) → "level"
   - `requirements` (map) → `{ "level": 5 }`
   - `isSecret` (boolean) → false

5. **저장** 버튼 클릭

6. 반복하여 다른 업적들도 추가

---

## 주의사항

- **문서 ID**는 업적의 고유 ID로 사용되므로, 기존 코드와 일치해야 합니다
- `requirements` 필드는 선택사항이지만, 업적 달성 조건을 추적하는 데 사용됩니다
- `isSecret`이 `true`인 경우, 달성하기 전까지 사용자에게 업적이 숨겨집니다
- 모든 사용자가 읽을 수 있지만, 쓰기는 관리자만 가능합니다

---

## 확인 방법

업적 템플릿이 제대로 추가되었는지 확인하려면:
1. 앱에서 포인트 페이지 접속
2. 업적 탭 확인
3. Firebase Console에서 추가한 업적들이 표시되는지 확인

