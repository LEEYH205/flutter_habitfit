#!/usr/bin/env node

/**
 * Achievement Templates 배포 스크립트 (Node.js)
 * 
 * 사용법:
 *   node scripts/deploy_achievement_templates_node.js
 * 
 * 또는:
 *   npm install firebase-admin (한 번만 실행)
 *   node scripts/deploy_achievement_templates_node.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK 초기화
// 서비스 계정 키 파일이 필요합니다
// 또는 환경 변수 GOOGLE_APPLICATION_CREDENTIALS를 설정하세요

async function main() {
    console.log('🚀 Achievement Templates 배포 시작...');

    try {
        // Firebase Admin SDK 초기화 확인
        if (!admin.apps.length) {
            // 방법 1: 환경 변수에서 서비스 계정 키 파일 경로 확인
            if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
                const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS);
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                });
            }
            // 방법 2: 프로젝트 루트에 serviceAccountKey.json 파일이 있는지 확인
            const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
            if (fs.existsSync(serviceAccountPath)) {
                const serviceAccount = require(serviceAccountPath);
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                });
            }
            // 방법 3: gcloud CLI 인증 사용 (gcloud auth application-default login 필요)
            else {
                try {
                    admin.initializeApp({
                        credential: admin.credential.applicationDefault(),
                    });
                } catch (e) {
                    console.error('❌ Firebase Admin SDK 초기화 실패');
                    console.error('');
                    console.error('자격 증명 설정 방법:');
                    console.error('1. Firebase Console에서 서비스 계정 키 다운로드:');
                    console.error('   https://console.firebase.google.com/project/flutterhabitfit/settings/serviceaccounts/adminsdk');
                    console.error('   → "새 비공개 키 생성" 클릭');
                    console.error('   → 다운로드한 JSON 파일을 프로젝트 루트에 serviceAccountKey.json으로 저장');
                    console.error('');
                    console.error('2. 또는 gcloud CLI 사용:');
                    console.error('   gcloud auth application-default login');
                    console.error('');
                    throw e;
                }
            }
        }
        console.log('✅ Firebase Admin SDK 초기화 완료');

        // JSON 파일 읽기
        const jsonPath = path.join(__dirname, '..', 'achievement_templates.json');
        if (!fs.existsSync(jsonPath)) {
            console.error('❌ achievement_templates.json 파일을 찾을 수 없습니다.');
            console.error(`   경로: ${jsonPath}`);
            process.exit(1);
        }

        const jsonString = fs.readFileSync(jsonPath, 'utf8');
        const templates = JSON.parse(jsonString);
        console.log(`✅ JSON 파일 읽기 완료: ${Object.keys(templates).length}개 업적 템플릿`);

        // Firestore에 배포
        const db = admin.firestore();
        const batch = db.batch();
        let successCount = 0;
        let updateCount = 0;
        let createCount = 0;

        for (const [docId, data] of Object.entries(templates)) {
            const docRef = db.collection('achievement_templates').doc(docId);

            try {
                // 기존 문서 확인
                const existingDoc = await docRef.get();
                if (existingDoc.exists) {
                    console.log(`🔄 업데이트: ${docId}`);
                    updateCount++;
                } else {
                    console.log(`➕ 생성: ${docId}`);
                    createCount++;
                }

                batch.set(docRef, data, { merge: true });
                successCount++;
            } catch (e) {
                console.error(`❌ 오류 (${docId}): ${e.message}`);
            }
        }

        // 배치 커밋
        await batch.commit();
        console.log('');
        console.log('✅ 배포 완료!');
        console.log(`   - 총 ${Object.keys(templates).length}개 업적 템플릿`);
        console.log(`   - 생성: ${createCount}개`);
        console.log(`   - 업데이트: ${updateCount}개`);
        console.log(`   - 성공: ${successCount}개`);

        process.exit(0);
    } catch (e) {
        console.error('❌ 배포 실패:', e.message);
        console.error('스택 트레이스:', e.stack);
        process.exit(1);
    }
}

main();

