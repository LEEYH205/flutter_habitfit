#!/usr/bin/env python3
"""
Debug the new singlepose-lightning-tflite-float16 model
"""

import tensorflow as tf
import numpy as np
import os

def debug_new_movenet():
    print("Debugging new singlepose-lightning-tflite-float16 model...")
    
    model_path = "temp/4.tflite"
    
    if not os.path.exists(model_path):
        print(f"❌ Model not found: {model_path}")
        return False
    
    try:
        # Load TFLite model
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        print("✅ New MoveNet model loaded successfully")
        
        # Get input details
        input_details = interpreter.get_input_details()
        print(f"\n📥 Input details:")
        for i, detail in enumerate(input_details):
            print(f"  Input {i}:")
            print(f"    Name: {detail['name']}")
            print(f"    Shape: {detail['shape']}")
            print(f"    Shape signature: {detail['shape_signature']}")
            print(f"    Dtype: {detail['dtype']}")
            print(f"    Quantization: {detail['quantization']}")
        
        # Get output details
        output_details = interpreter.get_output_details()
        print(f"\n📤 Output details:")
        for i, detail in enumerate(output_details):
            print(f"  Output {i}:")
            print(f"    Name: {detail['name']}")
            print(f"    Shape: {detail['shape']}")
            print(f"    Shape signature: {detail['shape_signature']}")
            print(f"    Dtype: {detail['dtype']}")
            print(f"    Quantization: {detail['quantization']}")
        
        # Test with different input types
        print(f"\n🧪 Testing with different input types...")
        
        # Test 1: uint8 input (as specified in model description)
        print(f"Test 1: uint8 input")
        try:
            test_input = np.random.randint(0, 256, (1, 192, 192, 3), dtype=np.uint8)
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]['index'])
            print(f"✅ Test 1 successful: Output shape {output.shape}, dtype {output.dtype}")
        except Exception as e:
            print(f"❌ Test 1 failed: {e}")
        
        # Test 2: int32 input (what we were using before)
        print(f"\nTest 2: int32 input")
        try:
            test_input = np.random.randint(0, 256, (1, 192, 192, 3), dtype=np.int32)
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]['index'])
            print(f"✅ Test 2 successful: Output shape {output.shape}, dtype {output.dtype}")
        except Exception as e:
            print(f"❌ Test 2 failed: {e}")
        
        # Test 3: float32 input
        print(f"\nTest 3: float32 input")
        try:
            test_input = np.random.random((1, 192, 192, 3)).astype(np.float32)
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]['index'])
            print(f"✅ Test 3 successful: Output shape {output.shape}, dtype {output.dtype}")
        except Exception as e:
            print(f"❌ Test 3 failed: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error debugging model: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = debug_new_movenet()
    if success:
        print("\n🎉 New MoveNet model debugging completed!")
    else:
        print("\n💥 Failed to debug new MoveNet model")
