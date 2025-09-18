#!/usr/bin/env python3
"""
TFDS Food-101의 정확한 클래스 순서로 라벨 파일 생성
알파벳 순서로 정렬된 101개 클래스
"""

import tensorflow_datasets as tfds
import pathlib

def create_correct_labels():
    """TFDS Food-101의 정확한 클래스 순서로 라벨 파일 생성"""
    print("📊 TFDS Food-101 클래스 정보 로딩 중...")
    
    # TFDS Food-101 정보 가져오기
    builder = tfds.builder("food101")
    class_names = builder.info.features["label"].names
    
    print(f"✅ 클래스 수: {len(class_names)}개")
    print(f"📝 첫 5개 클래스: {class_names[:5]}")
    print(f"📝 마지막 5개 클래스: {class_names[-5:]}")
    
    # 라벨 파일 저장
    output_dir = pathlib.Path("../assets/models")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    labels_path = output_dir / "food_labels.txt"
    with open(labels_path, 'w', encoding='utf-8') as f:
        for label in class_names:
            f.write(f"{label}\n")
    
    print(f"✅ 라벨 파일 저장됨: {labels_path}")
    print(f"📏 총 {len(class_names)}개 클래스")
    
    # 검증
    with open(labels_path, 'r', encoding='utf-8') as f:
        saved_labels = [line.strip() for line in f.readlines()]
    
    if saved_labels == class_names:
        print("✅ 라벨 순서 검증 완료: TFDS와 일치")
    else:
        print("❌ 라벨 순서 불일치 발견!")
        return False
    
    return True

if __name__ == "__main__":
    create_correct_labels()




