#!/usr/bin/env python3
"""Generate PES Arena app icon: dark + light variants using app color palette."""

import cairosvg

SIZE = 1024
RADIUS = 180

GAMEPAD_PATH = (
    "M21.58 16.09l-1.09-7.66C20.21 6.46 18.52 5 16.53 5H7.47"
    "C5.48 5 3.79 6.46 3.51 8.43l-1.09 7.66C2.2 17.63 3.39 19"
    " 4.94 19c.68 0 1.32-.27 1.8-.75L8 17h8l1.26 1.25"
    "c.48.48 1.12.75 1.8.75 1.55 0 2.74-1.37 2.52-2.91z"
    "M11 11H9v2H8v-2H6v-1h2V8h1v2h2v1z"
    "m4-1c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1z"
    "m2 3c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1z"
)

# ── Layout math ──────────────────────────────────────────────────────────────
FONT_SIZE  = 176
GAP        = 56
CAP_RATIO  = 0.72

ICON_PX    = 880           # 2x bigger icon
S          = ICON_PX / 24.0

ICON_CONTENT_H = 14 * S
ICON_TOP_PAD   = 5 * S
TEXT_CAP_H     = FONT_SIZE * CAP_RATIO
BLOCK_H        = ICON_CONTENT_H + GAP + TEXT_CAP_H

BLOCK_TOP     = (SIZE - BLOCK_H) / 2
ICON_GROUP_Y  = BLOCK_TOP - ICON_TOP_PAD
ICON_GROUP_X  = (SIZE - ICON_PX) / 2
TEXT_BASELINE = BLOCK_TOP + ICON_CONTENT_H + GAP + TEXT_CAP_H
GLOW_CY       = BLOCK_TOP + ICON_CONTENT_H / 2
# ─────────────────────────────────────────────────────────────────────────────


def make_svg(bg_start: str, bg_mid: str, bg_end: str, icon_start: str, icon_end: str,
             text_start: str, text_end: str, glow: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}"
     xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{bg_start}"/>
      <stop offset="42%" stop-color="{bg_mid}"/>
      <stop offset="100%" stop-color="{bg_end}"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="{GLOW_CY/SIZE*100:.1f}%" r="36%">
      <stop offset="0%" stop-color="{glow}" stop-opacity="0.28"/>
      <stop offset="100%" stop-color="{glow}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="iconGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{icon_start}"/>
      <stop offset="100%" stop-color="{icon_end}"/>
    </linearGradient>
    <linearGradient id="textGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="{text_start}"/>
      <stop offset="100%" stop-color="{text_end}"/>
    </linearGradient>
  </defs>

  <rect width="{SIZE}" height="{SIZE}" rx="{RADIUS}" ry="{RADIUS}" fill="url(#bgGrad)"/>
  <ellipse cx="{SIZE/2:.1f}" cy="{GLOW_CY:.1f}" rx="300" ry="240" fill="url(#glow)"/>

  <g transform="translate({ICON_GROUP_X:.2f},{ICON_GROUP_Y:.2f}) scale({S:.6f})">
    <path d="{GAMEPAD_PATH}" fill="url(#iconGrad)"/>
  </g>

  <text x="{SIZE/2:.2f}" y="{TEXT_BASELINE:.2f}"
        font-family="Arial Black, Arial, sans-serif"
        font-weight="900"
        font-size="{FONT_SIZE}"
        letter-spacing="28"
        text-anchor="middle"
        fill="url(#textGrad)">PES</text>
</svg>"""


VARIANTS = [
    {
        "name": "dark",
        "out": "assets/images/icon.png",
        # Home gradient: accent(#E8734A)@16% over #121212 → #121212 → primary(#F0F0F0)@6% over #121212
        "bg_start": "#34221B", "bg_mid": "#121212", "bg_end": "#1F1F1F",
        "icon_start": "#F08050", "icon_end": "#C4522A",
        "text_start": "#FFFFFF", "text_end": "#E8C4B0",
        "glow": "#E8734A",
    },
    {
        "name": "light",
        "out": "assets/images/icon_light.png",
        # Home gradient: accent(#E8734A)@16% over #FAFAFA → #FAFAFA → primary(#2D2D2D)@6% over #FAFAFA
        "bg_start": "#F7E4DE", "bg_mid": "#FAFAFA", "bg_end": "#EEEEEE",
        "icon_start": "#F08050", "icon_end": "#C4522A",
        "text_start": "#2D1A10", "text_end": "#1A1A2A",
        "glow": "#E8734A",
    },
]

for v in VARIANTS:
    svg = make_svg(
        v["bg_start"], v["bg_mid"], v["bg_end"],
        v["icon_start"], v["icon_end"],
        v["text_start"], v["text_end"],
        v["glow"],
    )
    cairosvg.svg2png(bytestring=svg.encode(), write_to=v["out"],
                     output_width=SIZE, output_height=SIZE)
    print(f"[{v['name']}] → {v['out']}")
