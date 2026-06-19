import wave
import struct
import math
import os

def generate_wav(filename, freq_start, freq_end, duration, volume=0.5):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            # Linear frequency sweep
            freq = freq_start + (freq_end - freq_start) * (t / duration)
            value = int(volume * 32767.0 * math.sin(2.0 * math.pi * freq * t))
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

# Generate basic sounds
generate_wav('assets/audio/sfx/move.wav', 200, 300, 0.1, 0.3)
generate_wav('assets/audio/sfx/attack.wav', 400, 800, 0.15, 0.5)
generate_wav('assets/audio/sfx/hit.wav', 800, 200, 0.2, 0.6)
generate_wav('assets/audio/sfx/death.wav', 300, 50, 0.5, 0.7)

print("Generated WAV files successfully.")
