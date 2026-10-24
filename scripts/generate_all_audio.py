import wave
import math
import struct
import os
import random

SAMPLE_RATE = 44100

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def write_wav(filename, samples_l, samples_r):
    ensure_dir(filename)
    num_samples = len(samples_l)
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2) # 16-bit
        wf.setframerate(SAMPLE_RATE)
        raw_bytes = bytearray()
        for i in range(num_samples):
            sl = max(-1.0, min(1.0, samples_l[i]))
            sr = max(-1.0, min(1.0, samples_r[i]))
            il = int(sl * 32767.0)
            ir = int(sr * 32767.0)
            raw_bytes.extend(struct.pack('<hh', il, ir))
        wf.writeframes(raw_bytes)
    print(f"Generated: {filename} ({num_samples / SAMPLE_RATE:.2f}s)")

# ─────────────────────────────────────────────────────────────────────────────
# 1. BGM: MAIN MENU (Atmospheric, Mysterious Title Music)
# ─────────────────────────────────────────────────────────────────────────────
def generate_bgm_menu(filename):
    duration = 16.0
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    # Celestial chords: Dm -> Bb -> F -> C
    # Pad frequencies:
    chords = [
        # (start_t, end_t, freqs)
        (0.0, 4.0, [146.83, 220.0, 261.63, 349.23]), # Dm
        (4.0, 8.0, [116.54, 233.08, 293.66, 349.23]), # Bb
        (8.0, 12.0, [174.61, 261.63, 349.23, 440.0]), # F
        (12.0, 16.0, [130.81, 196.0, 261.63, 329.63]), # C
    ]

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val_l = 0.0
        val_r = 0.0

        # Sub drone D (73.4 Hz)
        sub = math.sin(2.0 * math.pi * 73.42 * t) * 0.15

        # Chords with envelope
        for c_start, c_end, freqs in chords:
            if c_start <= t < c_end:
                ct = t - c_start
                c_dur = c_end - c_start
                # Gentle attack and release
                env = math.sin(math.pi * (ct / c_dur)) ** 0.8
                for idx, f in enumerate(freqs):
                    pan = 0.3 + 0.4 * (idx / max(1, len(freqs) - 1))
                    osc1 = math.sin(2.0 * math.pi * f * t)
                    osc2 = math.sin(2.0 * math.pi * (f * 1.002) * t) * 0.5
                    wave_sum = (osc1 + osc2) * 0.07 * env
                    val_l += wave_sum * (1.0 - pan)
                    val_r += wave_sum * pan

        # High celestial bell chimes at specific beats
        bell_times = [1.0, 3.5, 6.0, 9.5, 13.0]
        bell_pitches = [587.33, 698.46, 880.0, 783.99, 659.25]
        for bt, bp in zip(bell_times, bell_pitches):
            if t >= bt:
                dt = t - bt
                bell_env = math.exp(-dt * 2.5) * (1.0 if dt < 2.0 else 0.0)
                b1 = math.sin(2.0 * math.pi * bp * dt)
                b2 = math.sin(2.0 * math.pi * (bp * 2.76) * dt) * 0.3
                bell = (b1 + b2) * bell_env * 0.08
                val_l += bell * 0.6
                val_r += bell * 0.4

        # Subtle cavern wind
        noise = (random.random() * 2.0 - 1.0) * 0.012

        samples_l[i] = val_l + sub * 0.7 + noise
        samples_r[i] = val_r + sub * 0.7 + noise

    # Crossfade loop edges (1.2 seconds)
    fade = int(1.2 * SAMPLE_RATE)
    for j in range(fade):
        w = j / fade
        samples_l[j] = samples_l[num_samples - fade + j] * (1.0 - w) + samples_l[j] * w
        samples_r[j] = samples_r[num_samples - fade + j] * (1.0 - w) + samples_r[j] * w

    write_wav(filename, samples_l, samples_r)

# ─────────────────────────────────────────────────────────────────────────────
# 2. BGM: NORMAL EXPLORATION (Cheerful, Warm Retro Adventure)
# ─────────────────────────────────────────────────────────────────────────────
def generate_bgm_exploration(filename):
    # 12.0 seconds loop, BPM = 100 (1 beat = 0.6s, 20 beats)
    duration = 12.0
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    # Chord progression: C -> G -> Am -> F (3.0s each)
    # Bassline notes (root and 5th bounce, cheerful retro triangle):
    bass_notes = [
        # (start_t, duration, freq)
        (0.0, 0.5, 130.81), (0.75, 0.4, 196.00), (1.5, 0.5, 130.81), (2.25, 0.4, 196.00), # C
        (3.0, 0.5, 98.00),  (3.75, 0.4, 146.83), (4.5, 0.5, 98.00),  (5.25, 0.4, 146.83), # G
        (6.0, 0.5, 110.00), (6.75, 0.4, 164.81), (7.5, 0.5, 110.00), (8.25, 0.4, 164.81), # Am
        (9.0, 0.5, 87.31),  (9.75, 0.4, 130.81), (10.5, 0.5, 87.31), (11.25, 0.4, 130.81), # F
    ]

    # Cheerful, curious melody (soft rounded flute/bell lead):
    # C5(523), D5(587), E5(659), G5(783), A5(880), etc.
    melody_notes = [
        (0.0, 0.5, 523.25), (0.6, 0.3, 587.33), (1.0, 0.8, 659.25), (2.0, 0.7, 783.99),
        (3.0, 0.5, 783.99), (3.6, 0.3, 659.25), (4.0, 0.8, 587.33), (5.0, 0.6, 493.88),
        (6.0, 0.5, 440.00), (6.6, 0.3, 523.25), (7.0, 0.7, 659.25), (8.0, 0.7, 587.33),
        (9.0, 0.5, 523.25), (9.6, 0.4, 440.00), (10.2, 0.5, 392.00), (10.8, 0.9, 523.25),
    ]

    # Warm arpeggios (soft marimba/harp plucks):
    arp_chords = [
        (0.0, [261.63, 329.63, 392.0, 523.25]),
        (3.0, [196.00, 246.94, 293.66, 392.00]),
        (6.0, [220.00, 261.63, 329.63, 440.00]),
        (9.0, [174.61, 220.00, 261.63, 349.23]),
    ]

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val_l = 0.0
        val_r = 0.0

        # 1. Bassline (rounded triangle wave with soft attack/decay)
        for b_start, b_dur, b_freq in bass_notes:
            if b_start <= t < b_start + b_dur:
                bt = t - b_start
                b_env = math.sin(math.pi * (bt / b_dur)) ** 0.6
                # Triangle harmonic series: sum of (1/n^2) * sin(n*w*t)
                b_wave = math.sin(2.0 * math.pi * b_freq * bt) + 0.11 * math.sin(6.0 * math.pi * b_freq * bt)
                val_l += b_wave * b_env * 0.16
                val_r += b_wave * b_env * 0.16

        # 2. Melody (warm singing flute / soft square with vibrato)
        for m_start, m_dur, m_freq in melody_notes:
            if m_start <= t < m_start + m_dur + 0.2:
                mt = t - m_start
                m_env = math.sin(math.pi * min(1.0, mt / m_dur)) * math.exp(-max(0.0, mt - m_dur) * 6.0)
                vibrato = math.sin(2.0 * math.pi * 5.0 * mt) * 3.0 if mt > 0.15 else 0.0
                freq = m_freq + vibrato
                # Soft blend of sine and gentle odd harmonic
                m_wave = math.sin(2.0 * math.pi * freq * mt) + 0.25 * math.sin(6.0 * math.pi * freq * mt)
                val_l += m_wave * m_env * 0.14 * 0.8
                val_r += m_wave * m_env * 0.14 * 1.0

        # 3. Arpeggio plucks (repeating 16th-note plucks)
        bar_idx = int(t / 3.0) % len(arp_chords)
        chord_start, notes = arp_chords[bar_idx]
        arp_step = int((t - chord_start) / 0.375) % len(notes)
        arp_t = (t - chord_start) % 0.375
        arp_freq = notes[arp_step]
        arp_env = math.exp(-arp_t * 9.0)
        arp_wave = math.sin(2.0 * math.pi * arp_freq * arp_t) * arp_env * 0.06
        val_l += arp_wave * 1.1
        val_r += arp_wave * 0.7

        samples_l[i] = val_l
        samples_r[i] = val_r

    # Clean loop wrap
    fade = int(0.8 * SAMPLE_RATE)
    for j in range(fade):
        w = j / fade
        samples_l[j] = samples_l[num_samples - fade + j] * (1.0 - w) + samples_l[j] * w
        samples_r[j] = samples_r[num_samples - fade + j] * (1.0 - w) + samples_r[j] * w

    write_wav(filename, samples_l, samples_r)

# ─────────────────────────────────────────────────────────────────────────────
# 3. BGM: ECLIPSE MODE (Dark, Ominous, Haunting Shadow Music)
# ─────────────────────────────────────────────────────────────────────────────
def generate_bgm_eclipse(filename):
    duration = 16.0
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    # Slow, sparse, eerie chords: Cm -> Abm -> Ddim -> Cm
    chords = [
        (0.0, 4.0, [65.41, 130.81, 155.56, 196.00]),  # C minor
        (4.0, 8.0, [51.91, 103.83, 164.81, 207.65]),  # Ab minor
        (8.0, 12.0, [73.42, 146.83, 174.61, 207.65]), # D diminished
        (12.0, 16.0, [65.41, 130.81, 155.56, 233.08]), # Cm(add9)
    ]

    # Sparse, haunting high bell notes
    eerie_bells = [
        (1.2, 587.33), (3.8, 466.16), (6.5, 415.30), (9.0, 369.99), (11.5, 311.13), (14.0, 329.63)
    ]

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val_l = 0.0
        val_r = 0.0

        # Low pulsing sub-drone with slow beat
        lfo = math.sin(2.0 * math.pi * 0.25 * t)
        sub = math.sin(2.0 * math.pi * 48.99 * t) * (0.18 + 0.06 * lfo)

        # Chords with dark filtered envelope
        for c_start, c_end, freqs in chords:
            if c_start <= t < c_end:
                ct = t - c_start
                c_dur = c_end - c_start
                env = math.sin(math.pi * (ct / c_dur)) ** 1.2
                for idx, f in enumerate(freqs):
                    pan = 0.25 + 0.5 * (idx / max(1, len(freqs) - 1))
                    osc1 = math.sin(2.0 * math.pi * f * t)
                    osc2 = math.sin(2.0 * math.pi * (f * 1.004) * t) * 0.6
                    w = (osc1 + osc2) * env * 0.08
                    val_l += w * (1.0 - pan)
                    val_r += w * pan

        # Sparse eerie chimes
        for bt, bf in eerie_bells:
            if t >= bt:
                dt = t - bt
                if dt < 2.5:
                    b_env = math.exp(-dt * 2.0)
                    trem = math.sin(2.0 * math.pi * 6.0 * dt) * 4.0
                    b = (math.sin(2.0 * math.pi * (bf + trem) * dt) + 0.3 * math.sin(2.0 * math.pi * (bf * 2.6) * dt)) * b_env * 0.09
                    val_l += b * 0.4
                    val_r += b * 0.7

        # Void breathing hiss / cavern texture
        hiss = (random.random() * 2.0 - 1.0) * 0.018 * (0.8 + 0.3 * lfo)

        samples_l[i] = val_l + sub + hiss
        samples_r[i] = val_r + sub + hiss

    # Loop crossfade
    fade = int(1.2 * SAMPLE_RATE)
    for j in range(fade):
        w = j / fade
        samples_l[j] = samples_l[num_samples - fade + j] * (1.0 - w) + samples_l[j] * w
        samples_r[j] = samples_r[num_samples - fade + j] * (1.0 - w) + samples_r[j] * w

    write_wav(filename, samples_l, samples_r)

# ─────────────────────────────────────────────────────────────────────────────
# 4. SFX: READING NOTE / INSCRIPTION / MESSAGE
# ─────────────────────────────────────────────────────────────────────────────
def generate_sfx_message(filename):
    duration = 0.55
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Soft parchment paper rustle (filtered noise flutter)
        rustle = 0.0
        if t < 0.22:
            r_env = math.sin(math.pi * (t / 0.22))
            noise = (random.random() * 2.0 - 1.0) * 0.22 * r_env
            rustle = noise

        # Delicate mystic crystal chime (480Hz -> 960Hz)
        chime = 0.0
        if t >= 0.06:
            ct = t - 0.06
            c_env = math.exp(-ct * 8.0)
            c1 = math.sin(2.0 * math.pi * 784.0 * ct)
            c2 = math.sin(2.0 * math.pi * 1046.5 * ct) * 0.5
            chime = (c1 + c2) * c_env * 0.28

        samples_l[i] = (rustle * 0.8 + chime * 1.0) * 0.8
        samples_r[i] = (rustle * 1.0 + chime * 0.8) * 0.8

    write_wav(filename, samples_l, samples_r)

# ─────────────────────────────────────────────────────────────────────────────
# 5. SFX: TABLET RIDDLE ACTIVATION
# ─────────────────────────────────────────────────────────────────────────────
def generate_sfx_tablet(filename):
    duration = 0.65
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 6.0)
        # Deep stone resonant ring (low gong/chime)
        f1 = 220.0
        f2 = 440.0
        f3 = 554.37 # C# harmonic
        stone = (math.sin(2.0 * math.pi * f1 * t) * 0.6 + math.sin(2.0 * math.pi * f2 * t) * 0.3 + math.sin(2.0 * math.pi * f3 * t) * 0.2) * env * 0.35
        # Soft click
        click = (math.sin(2.0 * math.pi * 800.0 * t) * math.exp(-t * 40.0)) * 0.3 if t < 0.05 else 0.0

        samples_l[i] = (stone + click) * 0.85
        samples_r[i] = (stone * 0.9 + click * 1.1) * 0.85

    write_wav(filename, samples_l, samples_r)

# ─────────────────────────────────────────────────────────────────────────────
# 6. SFX: EXIT GATE UNLOCKED & ENTERED
# ─────────────────────────────────────────────────────────────────────────────
def generate_sfx_gate_open(filename):
    duration = 1.2
    num_samples = int(duration * SAMPLE_RATE)
    samples_l = [0.0] * num_samples
    samples_r = [0.0] * num_samples

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # 1. Distant heavy iron gear latch (t = 0..0.4)
        latch = 0.0
        if t < 0.4:
            lt = t
            l_env = math.exp(-lt * 12.0)
            f_latch = 180.0 * math.exp(-lt * 20.0) + 75.0
            latch = math.sin(2.0 * math.pi * f_latch * lt) * l_env * 0.45

        # 2. Portal / gate mystical release chime (t = 0.15..1.2)
        release = 0.0
        if t >= 0.15:
            rt = t - 0.15
            r_env = math.exp(-rt * 3.5)
            # Arpeggiated ascending chime: C5 -> E5 -> G5 -> C6
            chime = (
                math.sin(2.0 * math.pi * 523.25 * rt) * 0.3 +
                math.sin(2.0 * math.pi * 659.25 * rt) * 0.3 +
                math.sin(2.0 * math.pi * 783.99 * rt) * 0.3 +
                math.sin(2.0 * math.pi * 1046.5 * rt) * 0.2
            ) * r_env
            release = chime * 0.35

        samples_l[i] = (latch * 0.9 + release * 1.1) * 0.8
        samples_r[i] = (latch * 1.1 + release * 0.9) * 0.8

    write_wav(filename, samples_l, samples_r)

if __name__ == "__main__":
    out_dir = "assets/audio"
    generate_bgm_menu(os.path.join(out_dir, "bgm_menu.wav"))
    generate_bgm_exploration(os.path.join(out_dir, "bgm_exploration.wav"))
    generate_bgm_eclipse(os.path.join(out_dir, "bgm_eclipse.wav"))
    generate_sfx_message(os.path.join(out_dir, "sfx_message.wav"))
    generate_sfx_tablet(os.path.join(out_dir, "sfx_tablet.wav"))
    generate_sfx_gate_open(os.path.join(out_dir, "sfx_gate_open.wav"))
    print("All audio files generated successfully!")
