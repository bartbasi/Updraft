# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
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


def downdraft(rng):
    """Cool sinking air: a soft hiss whose pitch slides down, over a low falling tone."""
    n = int(1.3 * RATE)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    out = []
    lp = 0.0
    lp2 = 0.0
    phase = 0.0
    for i in range(n):
        t = i / RATE
        k = t / 1.3
        cutoff = 2600.0 * (1.0 - k) + 500.0
        a = 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)
        lp += a * (noise[i] - lp)
        lp2 += a * (lp - lp2)
        env = min(1.0, t / 0.15) * (1.0 - k) ** 1.5
        phase += 2 * math.pi * (330.0 - 140.0 * k) / RATE
        out.append((lp2 * 2.2 + 0.18 * math.sin(phase)) * env)
    return out


def bell_notes(notes, length, decay=0.5):
    """Soft bell plucks: notes is a list of (start_s, freq, gain)."""
    n = int(length * RATE)
    out = [0.0] * n
    for start, freq, gain in notes:
        s0 = int(start * RATE)
        for i in range(n - s0):
            t = i / RATE
            env = min(1.0, t / 0.003) * math.exp(-t / decay)
            v = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t / 0.12)
            out[s0 + i] += gain * env * v
    return out


def style_good():
    """A cheerful two-note pop for a style pass."""
    return bell_notes([(0.0, 1318.5, 0.8), (0.07, 1760.0, 1.0)], 0.7, 0.18)


def style_perfect():
    """A brighter rising sparkle for a near-perfect pass."""
    return bell_notes([(0.0, 1046.5, 0.7), (0.06, 1318.5, 0.75), (0.12, 1568.0, 0.8), (0.18, 2093.0, 1.0), (0.26, 2637.0, 0.45)], 1.1, 0.3)


def whoosh(rng):
    """A soft airy swell, for rushing past things and bursting outside."""
    n = int(0.8 * RATE)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        k = t / 0.8
        cutoff = 600.0 + 2400.0 * math.sin(math.pi * k)
        a = 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)
        lp += a * (noise[i] - lp)
        out.append(lp * math.sin(math.pi * k) ** 1.5)
    return out


def pop(rng):
    """A balloon popping: a sharp crack, a short rubbery slap and a puff of air."""
    n = int(0.45 * RATE)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    crack = highpass(noise, 1800)
    puff = lowpass(noise, 1200)
    out = []
    for i in range(n):
        t = i / RATE
        v = crack[i] * math.exp(-t / 0.006) * 1.6
        v += puff[i] * min(1.0, t / 0.004) * math.exp(-t / 0.08) * 1.2
        v += math.sin(2 * math.pi * 140 * t) * math.exp(-t / 0.04) * 0.5
        out.append(v)
    return out


def vario():
    """One soft variometer beep: a short sine with a little second harmonic."""
    n = int(0.09 * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.005) * math.exp(-t / 0.06)
        out.append(env * (math.sin(2 * math.pi * 660 * t) + 0.15 * math.sin(2 * math.pi * 1320 * t)))
    return out


def sigh(rng):
    """Lift lost: a soft falling tone with a breath of noise under it."""
    n = int(0.38 * RATE)
    noise = lowpass(highpass([rng.uniform(-1, 1) for _ in range(n)], 600), 2400)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        freq = 470.0 * (300.0 / 470.0) ** (t / 0.38)  # an exponential glide down
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.04) * (1.0 - t / 0.38) ** 1.5
        out.append(env * (math.sin(phase) + 0.5 * noise[i]))
    return out


def gull():
    """A gull's "kee-ow": a quick rise, then a long fall, with a little vibrato."""
    n = int(0.55 * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        if t < 0.08:
            freq = 1500.0 + 400.0 * (t / 0.08)
        else:
            freq = 1900.0 - 800.0 * ((t - 0.08) / 0.47) ** 0.8
        freq *= 1.0 + 0.03 * math.sin(2 * math.pi * 7.0 * t)
        phase += 2 * math.pi * freq / RATE
        env = min(1.0, t / 0.015) * (1.0 - t / 0.55) ** 1.2
        out.append(env * (math.sin(phase) + 0.25 * math.sin(2 * phase) + 0.1 * math.sin(3 * phase)))
    return out


def sink_tick():
    """A low, soft tick for sinking air."""
    n = int(0.06 * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.003) * math.exp(-t / 0.045)
        out.append(env * (math.sin(2 * math.pi * 210 * t) + 0.3 * math.sin(2 * math.pi * 420 * t)))
    return out


def splash(rng):
    """Landing on the water: a soft slap, a rush of spray and a couple of bubbly blips."""
    n = int(0.7 * RATE)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    spray = lowpass(highpass(noise, 900), 5000)
    body = lowpass(noise, 500)
    out = []
    for i in range(n):
        t = i / RATE
        v = body[i] * math.exp(-t / 0.05) * 2.5
        v += spray[i] * min(1.0, t / 0.01) * math.exp(-t / 0.18) * 0.9
        for start, f in [(0.18, 520.0), (0.31, 640.0)]:  # bubbles: short rising blips
            if t > start:
                u = t - start
                v += 0.35 * math.sin(2 * math.pi * f * (1.0 + 2.0 * u) * u) * math.exp(-u / 0.03)
        out.append(v)
    return out


def star():
    """Endless's star pickup: a bright, quick "tink" (a sine at 1568 Hz with two soft overtones)."""
    n = int(0.16 * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.002) * math.exp(-t / 0.045)
        out.append(env * (math.sin(2 * math.pi * 1568 * t) + 0.35 * math.sin(2 * math.pi * 3136 * t)
                          + 0.15 * math.sin(2 * math.pi * 4704 * t)))
    return out


def flutter(rng):
    """Snagging a kite's ring or a line: a papery flutter, noise band-passed to 600-2400 Hz,
    shaken at 22 Hz and dying away."""
    n = int(0.3 * RATE)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(n)]
    band = lowpass(highpass(noise, 600), 2400)
    out = []
    for i, x in enumerate(band):
        t = i / RATE
        env = min(1.0, t / 0.01) * math.exp(-t / 0.09)
        out.append(x * env * (0.55 + 0.45 * math.sin(2 * math.pi * 22 * t)))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(1)
    write_wav("wind.wav", wind(rng), peak=0.6, loop=True)
    write_wav("chime.wav", chime(), peak=0.6)
    write_wav("tap.wav", tap(rng), peak=0.75)
    write_wav("crumple.wav", crumple(rng), peak=0.8)
    write_wav("downdraft.wav", downdraft(rng), peak=0.6)
    write_wav("style_good.wav", style_good(), peak=0.55)
    write_wav("style_perfect.wav", style_perfect(), peak=0.6)
    write_wav("whoosh.wav", whoosh(rng), peak=0.6)
    write_wav("pop.wav", pop(rng), peak=0.8)
    write_wav("vario.wav", vario(), peak=0.6)
    write_wav("sigh.wav", sigh(rng), peak=0.5)
    write_wav("gull.wav", gull(), peak=0.55)
    write_wav("sink_tick.wav", sink_tick(), peak=0.6)
    write_wav("splash.wav", splash(rng), peak=0.7)
    write_wav("star.wav", star(), peak=0.4)  # -8 dBFS
    write_wav("flutter.wav", flutter(rng), peak=0.32)  # -10 dBFS


if __name__ == "__main__":
    main()
