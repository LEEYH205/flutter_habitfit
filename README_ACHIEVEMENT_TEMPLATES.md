# Achievement Templates 배포 가이드

`achievement_templates` 컬렉션의 데이터를 코드로 관리하고 배포할 수 있습니다.

## 파일 구조

```
habitfit_mvp/
├── achievement_templates.json          # 업적 템플릿 데이터 (JSON 형식)
├── scripts/
│   ├── deploy_achievement_templates.dart  # Dart 배포 스크립트
│   └── deploy_achievement_templates.sh    # Shell 배포 스크립트
└── README_ACHIEVEMENT_TEMPLATES.md     # 이 파일
```

## 배포 방법

### 방법 1: Dart 스크립트 직접 실행

```bash
cd /Users/leeyoungho/develop/flutter/habitfit_mvp
dart run scripts/deploy_achievement_templates.dart
```

### 방법 2: Shell 스크립트 실행

```bash
cd /Users/leeyoungho/develop/flutter/habitfit_mvp
./scripts/deploy_achievement_templates.sh
```

또는:

```bash
bash scripts/deploy_achievement_templates.sh
```

## achievement_templates.json 파일 수정

`achievement_templates.json` 파일을 수정하여 업적 템플릿을 추가/수정할 수 있습니다.

### 파일 형식

```json
{
  "문서ID": {
    "title": "업적 제목",
    "description": "업적 설명",
    "icon": "이모지",
    "pointsReward": 포인트_보상,
    "category": "카테고리",
    "requirements": {
      "조건_필드": 조건_값
    },
    "isSecret": false
  }
}
```

### 예시

```json
{
  "level_5": {
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
}
```

## 업적 템플릿 추가/수정 후 배포

1. `achievement_templates.json` 파일 수정
2. 배포 스크립트 실행
3. Firebase Console에서 확인

## 주의사항

- **문서 ID**는 업적의 고유 ID로 사용되므로 변경 시 주의
- 기존 문서는 `merge: true` 옵션으로 업데이트되므로, 기존 필드는 유지됩니다
- 새 필드를 추가하면 자동으로 추가됩니다
- 기존 필드를 삭제하려면 Firebase Console에서 수동으로 삭제해야 합니다

## 현재 업적 템플릿 목록

- `level_1`: 첫 로그인
- `level_5`: 첫 번째 레벨업
- `level_10`: 두 번째 레벨업
- `level_20`: 달성자
- `level_30`: 마스터
- `points_1000`: 첫 1000점
- `points_5000`: 포인트 마스터
- `points_10000`: 포인트 레전드
- `habit_7days`: 일주일의 전사
- `habit_30days`: 한 달의 전사
- `workout_first`: 첫 걸음

## 버전 관리

`achievement_templates.json` 파일을 Git에 커밋하여 버전 관리할 수 있습니다.

```bash
git add achievement_templates.json
git commit -m "업적 템플릿 추가/수정"
git push
```

## Firebase Console에서 확인

배포 후 Firebase Console에서 확인:
https://console.firebase.google.com/project/flutterhabitfit/firestore/data/~2Fachievement_templates

