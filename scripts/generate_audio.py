import wave
import math
import struct
import os
import random

SAMPLE_RATE = 44100

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def write_wav(filename, samples_left, samples_right):
    ensure_dir(filename)
    num_samples = len(samples_left)
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2) # 16-bit
        wf.setframerate(SAMPLE_RATE)
        raw_bytes = bytearray()
        for i in range(num_samples):
            # Clamp to -1.0 to 1.0
            sl = max(-1.0, min(1.0, samples_left[i]))
            sr = max(-1.0, min(1.0, samples_right[i]))
            il = int(sl * 32767.0)
            ir = int(sr * 32767.0)
            raw_bytes.extend(struct.pack('<hh', il, ir))
        wf.writeframes(raw_bytes)
    print(f"Generated: {filename} ({num_samples / SAMPLE_RATE:.2f}s)")

def generate_bgm(filename):
    duration = 16.0 # 16 seconds loop
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    # Drone frequencies: A1 (55Hz), E2 (82.4Hz), A2 (110Hz), C3 (130.8Hz)
    drones = [
        (55.0, 0.22, 0.0),
        (55.3, 0.18, 1.2), # slight detune for slow stereo beating
        (82.4, 0.14, 0.5),
        (110.0, 0.10, 0.8),
        (130.81, 0.08, 1.5),
        (164.81, 0.06, 2.0),
    ]

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # LFO modulation for subtle movement
        lfo1 = math.sin(2.0 * math.pi * 0.125 * t) # 8s period
        lfo2 = math.cos(2.0 * math.pi * 0.083 * t) # 12s period

        val_l = 0.0
        val_r = 0.0

        for freq, amp, phase in drones:
            # Sub-drone
            s1 = math.sin(2.0 * math.pi * freq * t + phase)
            s2 = math.sin(2.0 * math.pi * (freq * 1.002) * t + phase + 0.4)
            # Add subtle harmonic saturation
            s1 = math.tanh(s1 * 1.2)
            s2 = math.tanh(s2 * 1.2)
            val_l += s1 * amp * (0.85 + 0.15 * lfo1)
            val_r += s2 * amp * (0.85 + 0.15 * lfo2)

        # Ethereal pad chord: Dm / Am notes entering and swelling softly
        # Swell 1 (t around 4s)
        env1 = math.exp(-((t - 4.5) ** 2) / 6.0)
        pad1_l = (math.sin(2.0 * math.pi * 220.0 * t) + 0.5 * math.sin(2.0 * math.pi * 261.63 * t)) * env1 * 0.12
        pad1_r = (math.sin(2.0 * math.pi * 220.5 * t) + 0.5 * math.sin(2.0 * math.pi * 329.63 * t)) * env1 * 0.12

        # Swell 2 (t around 12s)
        env2 = math.exp(-((t - 12.0) ** 2) / 7.0)
        pad2_l = (math.sin(2.0 * math.pi * 196.0 * t) + 0.6 * math.sin(2.0 * math.pi * 293.66 * t)) * env2 * 0.10
        pad2_r = (math.sin(2.0 * math.pi * 196.4 * t) + 0.6 * math.sin(2.0 * math.pi * 349.23 * t)) * env2 * 0.10

        # Subtle noise / dark cavern breath
        noise_l = (random.random() * 2.0 - 1.0) * 0.015 * (1.0 + 0.4 * lfo1)
        noise_r = (random.random() * 2.0 - 1.0) * 0.015 * (1.0 + 0.4 * lfo2)

        samples_l[i] = val_l + pad1_l + pad2_l + noise_l
        samples_r[i] = val_r + pad1_r + pad2_r + noise_r

    # Smooth seamless loop crossfade (1.5 seconds crossfade at boundaries)
    fade_len = int(1.5 * SAMPLE_RATE)
    for j in range(fade_len):
        w = j / fade_len
        end_idx = num_samples - fade_len + j
        start_idx = j
        # blend tail into head
        blended_l = samples_l[end_idx] * (1.0 - w) + samples_l[start_idx] * w
        blended_r = samples_r[end_idx] * (1.0 - w) + samples_r[start_idx] * w
        samples_l[start_idx] = blended_l
        samples_r[start_idx] = blended_r
        samples_l[end_idx] = blended_l
        samples_r[end_idx] = blended_r

    write_wav(filename, samples_l, samples_r)

def generate_sfx_switch(filename):
    duration = 0.85
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 4.8) # Exponential decay

        # Rising shimmer frequency: 320 Hz to 640 Hz
        freq = 340.0 + 380.0 * (1.0 - math.exp(-t * 9.0))
        # High crystal chime harmonics
        c1 = math.sin(2.0 * math.pi * freq * t)
        c2 = math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.5
        c3 = math.sin(2.0 * math.pi * (freq * 2.75) * t) * 0.25
        chime = (c1 + c2 + c3) * env * 0.35

        # Low resonant sub-whoosh
        sub_env = math.sin(math.pi * min(1.0, t / 0.5)) if t < 0.5 else 0.0
        sub = math.sin(2.0 * math.pi * (90.0 - 30.0 * t) * t) * sub_env * 0.28

        # Ethereal noise sweep
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 6.0) * 0.08

        samples_l[i] = (chime * 0.9 + sub + noise) * 0.85
        samples_r[i] = (chime * 1.0 + sub + noise * 0.9) * 0.85

    write_wav(filename, samples_l, samples_r)

def generate_sfx_mechanism(filename):
    duration = 0.95
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # 1. Stone grind rumble (t = 0.0 to 0.55)
        grind = 0.0
        if t < 0.55:
            g_env = math.sin(math.pi * (t / 0.55))
            f_grind = 65.0 + 30.0 * math.sin(t * 40.0)
            noise_grind = (random.random() * 2.0 - 1.0) * 0.18
            grind = (math.sin(2.0 * math.pi * f_grind * t) * 0.35 + noise_grind) * g_env

        # 2. Heavy iron latch / clack at t = 0.42
        clack = 0.0
        if t >= 0.42:
            dt = t - 0.42
            c_env = math.exp(-dt * 28.0)
            f_clack = 280.0 * math.exp(-dt * 15.0)
            metal = math.sin(2.0 * math.pi * f_clack * dt) + 0.4 * math.sin(2.0 * math.pi * 840.0 * dt)
            click_impulse = (1.0 if dt < 0.003 else 0.0) * 0.6
            clack = (metal * 0.45 + click_impulse) * c_env

        samples_l[i] = (grind + clack) * 0.75
        samples_r[i] = (grind * 0.95 + clack * 1.05) * 0.75

    write_wav(filename, samples_l, samples_r)

def generate_sfx_reveal(filename):
    duration = 2.8
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Impact hit at t=0
        hit_env = math.exp(-t * 2.2)
        # Deep sub drop
        sub_freq = 80.0 * math.exp(-t * 1.8) + 28.0
        sub = math.sin(2.0 * math.pi * sub_freq * t) * hit_env * 0.45

        # Dissonant tritone chord (diminished 5th tension): 260Hz + 368Hz + 520Hz + 735Hz
        chord_env = math.exp(-t * 1.4)
        vibrato = math.sin(2.0 * math.pi * 6.5 * t) * 12.0 # eerie tremor
        d1 = math.sin(2.0 * math.pi * (260.0 + vibrato) * t) * 0.22
        d2 = math.sin(2.0 * math.pi * (368.0 - vibrato) * t) * 0.20
        d3 = math.sin(2.0 * math.pi * (520.0 + vibrato * 1.4) * t) * 0.16
        d4 = math.sin(2.0 * math.pi * (735.0 - vibrato * 1.4) * t) * 0.12
        dissonance = (d1 + d2 + d3 + d4) * chord_env

        # Metallic scraping shimmer
        scrape_env = math.exp(-t * 1.8) * (1.0 - math.exp(-t * 8.0))
        noise = (random.random() * 2.0 - 1.0) * 0.10 * scrape_env

        samples_l[i] = (sub + dissonance + noise) * 0.8
        samples_r[i] = (sub + dissonance * 1.1 + noise * 0.9) * 0.8

    write_wav(filename, samples_l, samples_r)

if __name__ == "__main__":
    out_dir = "assets/audio"
    generate_bgm(os.path.join(out_dir, "bgm_ambience.wav"))
    generate_sfx_switch(os.path.join(out_dir, "sfx_switch.wav"))
    generate_sfx_mechanism(os.path.join(out_dir, "sfx_mechanism.wav"))
    generate_sfx_reveal(os.path.join(out_dir, "sfx_reveal.wav"))
    print("All audio files generated successfully!")
