#!/usr/bin/env python3
"""
RoutineX 앱 아이콘 생성 스크립트 (이미지 기반)
제공된 이미지를 기반으로 모든 플랫폼용 아이콘 생성
"""

from PIL import Image, ImageDraw, ImageFilter
import os

def resize_and_center_image(source_img, target_size, bg_color=(255, 255, 255, 255)):
    """이미지를 목표 크기로 리사이즈하고 중앙에 배치"""
    # 투명 배경 생성
    result = Image.new('RGBA', (target_size, target_size), bg_color)
    
    # 원본 이미지 비율 유지하며 리사이즈
    source_img = source_img.convert('RGBA')
    
    # 이미지가 정사각형이 되도록 크기 계산
    scale = min(target_size / source_img.width, target_size / source_img.height)
    new_width = int(source_img.width * scale)
    new_height = int(source_img.height * scale)
    
    # 리사이즈
    resized = source_img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # 중앙에 배치
    x = (target_size - new_width) // 2
    y = (target_size - new_height) // 2
    
    result.paste(resized, (x, y), resized)
    return result

def create_ios_icon_from_source(source_img, size):
    """iOS 아이콘 생성"""
    return resize_and_center_image(source_img, size, (255, 255, 255, 255))

def create_android_adaptive_foreground_from_source(source_img, size=108):
    """Android Adaptive Icon Foreground 생성"""
    # 원본 이미지에서 불꽃과 도트 부분만 추출하여 중앙 66x66 안전 영역에 맞춤
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # 이미지 리사이즈 (안전 영역 고려)
    safe_area = 66
    scale = safe_area / max(source_img.width, source_img.height)
    new_width = int(source_img.width * scale)
    new_height = int(source_img.height * scale)
    
    resized = source_img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # 중앙에 배치
    x = (size - new_width) // 2
    y = (size - new_height) // 2
    
    result.paste(resized, (x, y), resized)
    return result

def create_android_adaptive_background_from_source(source_img, size=108):
    """Android Adaptive Icon Background 생성 (원본 이미지의 배경색 기반)"""
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(result)
    
    # 원본 이미지에서 배경색 추출 (흰색)
    bg_color = (255, 255, 255, 255)
    
    # 그라데이션 배경 생성
    for y in range(size):
        ratio = y / size
        r = int(255 - ratio * 10)  # 255 -> 245
        g = int(255 - ratio * 10)  # 255 -> 245
        b = int(255 - ratio * 10)  # 255 -> 245
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    return result

def create_android_legacy_from_source(source_img, size):
    """Android Legacy Icon 생성"""
    return resize_and_center_image(source_img, size, (255, 255, 255, 255))

def main():
    """메인 함수"""
    print("🔥 RoutineX 앱 아이콘 생성 중 (이미지 기반)...")
    
    # 원본 이미지 로드
    source_path = "image-crop.png"
    if not os.path.exists(source_path):
        print(f"❌ 원본 이미지를 찾을 수 없습니다: {source_path}")
        return
    
    try:
        source_img = Image.open(source_path)
        print(f"✅ 원본 이미지 로드 완료: {source_img.size}")
    except Exception as e:
        print(f"❌ 이미지 로드 실패: {e}")
        return
    
    # iOS 아이콘 크기들
    ios_sizes = [1024, 512, 256, 180, 167, 152, 120, 87, 76, 60]
    
    # iOS 아이콘 생성
    print("📱 iOS 아이콘 생성 중...")
    for size in ios_sizes:
        icon = create_ios_icon_from_source(source_img, size)
        filename = f"ios/icon-{size}.png"
        icon.save(filename, "PNG")
        print(f"  ✅ {filename} 생성 완료")
    
    # Android Adaptive Icons
    print("🤖 Android 아이콘 생성 중...")
    
    # Foreground
    foreground = create_android_adaptive_foreground_from_source(source_img, 108)
    foreground.save("android/adaptive-foreground.png", "PNG")
    print("  ✅ adaptive-foreground.png 생성 완료")
    
    # Background
    background = create_android_adaptive_background_from_source(source_img, 108)
    background.save("android/adaptive-background.png", "PNG")
    print("  ✅ adaptive-background.png 생성 완료")
    
    # Legacy Android Icons
    android_sizes = [192, 144, 96, 72, 48, 36]
    for size in android_sizes:
        icon = create_android_legacy_from_source(source_img, size)
        filename = f"android/legacy-{size}.png"
        icon.save(filename, "PNG")
        print(f"  ✅ {filename} 생성 완료")
    
    print("🎉 모든 아이콘 생성 완료!")

if __name__ == "__main__":
    main()
