"""Synthesizes the game's sound effects as 16-bit mono WAV files in audio/.

Run from the project folder:  python tools/gen_sounds.py

Everything is built from noise and sine waves with the Python standard library,
so there are no recorded samples or third-party assets. Output is deterministic.
"""

import math
import os
import random
import struct

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")


def write_wav(name, samples, peak=0.7, loop=False):
    """Normalizes to `peak` and writes a WAV. Looping files get a 'smpl' chunk,
    which Godot's importer reads to loop the whole file."""
    top = max(1e-9, max(abs(s) for s in samples))
    pcm = b"".join(struct.pack("<h", int(s / top * peak * 32767)) for s in samples)
    fmt = struct.pack("<HHIIHH", 1, 1, RATE, RATE * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(pcm)) + pcm
    if loop:
        smpl = struct.pack("<9I", 0, 0, 1_000_000_000 // RATE, 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, len(samples) - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    body = b"WAVE" + chunks
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", len(body)) + body)
    print(f"{name}: {len(samples) / RATE:.2f} s")


def lowpass(samples, cutoff):
    a = 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)
    y, out = 0.0, []
    for x in samples:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(samples, cutoff):
    return [x - y for x, y in zip(samples, lowpass(samples, cutoff))]


def wind(rng):
    """Soft airy rush: filtered noise with slow gusts, crossfaded into a seamless loop."""
    length, fade = 6 * RATE, RATE // 2
    total = length + fade
    noise = [rng.uniform(-1, 1) for _ in range(total)]
    body = lowpass(lowpass(noise, 520), 900)
    hiss = lowpass(highpass(noise, 2500), 6000)
    out = []
    for i in range(total):
        t = i / RATE
        # Gust rates repeat exactly over the 6 s loop.
        gust = 0.65 + 0.25 * math.sin(2 * math.pi * t / 3.0) + 0.1 * math.sin(2 * math.pi * t / 1.5 + 1.0)
        out.append((body[i] * 3.0 + hiss[i] * 0.25) * gust)
    for i in range(fade):
        k = i / fade
        out[i] = out[i] * k + out[length + i] * (1 - k)
    return out[:length]


def chime():
    """Gentle glassy bell with a soft second note a fifth above."""
    n = int(2.4 * RATE)
    out = [0.0] * n
    for start, freq, gain in ((0.0, 880.0, 1.0), (0.09, 1318.5, 0.55)):
        s0 = int(start * RATE)
        for i in range(n - s0):
            t = i / RATE
            env = min(1.0, t / 0.004) * math.exp(-t / 0.75)
            v = (math.sin(2 * math.pi * freq * t)
                 + 0.3 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t / 0.3)
                 + 0.08 * math.sin(2 * math.pi * freq * 4.2 * t) * math.exp(-t / 0.15))
            out[s0 + i] += gain * env * v
    return out


def tap(rng):
    """Light paper tap: a short papery click over a soft low thump."""
    n = int(0.16 * RATE)
    click = lowpass(highpass([rng.uniform(-1, 1) for _ in range(n)], 1800), 6000)
    out = []
    for i in range(n):
        t = i / RATE
        out.append(click[i] * math.exp(-t / 0.012) * 1.4 + math.sin(2 * math.pi * 210 * t) * math.exp(-t / 0.03) * 0.5)
    return out


def crumple(rng):
    """Paper crumpling: dense crackles that thin out, over a soft rustle."""
    n = int(0.85 * RATE)
    out = [0.0] * n
    rustle = lowpass(highpass([rng.uniform(-1, 1) for _ in range(n)], 600), 4000)
    for i in range(n):
        t = i / RATE
        out[i] = rustle[i] * 0.25 * min(1.0, t / 0.02) * math.exp(-t / 0.35)
    t = 0.0
    while t < 0.8:
        start = int(t * RATE)
        size = rng.randint(int(0.001 * RATE), int(0.007 * RATE))
        amp = rng.uniform(0.3, 1.0) * math.exp(-t / 0.4)
        burst = highpass([rng.uniform(-1, 1) for _ in range(size)], rng.uniform(1500, 4000))
        for j, b in enumerate(burst):
            if start + j < n:
                out[start + j] += b * amp * math.exp(-j / (size * 0.35))
        t += rng.uniform(0.002, 0.018) + t * 0.03
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(1)
    write_wav("wind.wav", wind(rng), peak=0.6, loop=True)
    write_wav("chime.wav", chime(), peak=0.6)
    write_wav("tap.wav", tap(rng), peak=0.75)
    write_wav("crumple.wav", crumple(rng), peak=0.8)


if __name__ == "__main__":
    main()
