"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { toPng } from "html-to-image";

// ─── Canvas Dimensions ────────────────────────────────────────────────────────
const W = 1320;   const H = 2868;  // iPhone 6.9"
const AW = 1080;  const AH = 1920; // Android phone
const FGW = 1024; const FGH = 500; // Feature Graphic

// ─── Export Sizes ─────────────────────────────────────────────────────────────
const IPHONE_SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;

const ANDROID_SIZES = [{ label: "Phone", w: 1080, h: 1920 }] as const;
const FG_SIZES      = [{ label: "Feature Graphic", w: 1024, h: 500 }] as const;

// ─── iPhone Mockup Measurements ───────────────────────────────────────────────
const MK_W = 1022; const MK_H = 2082;
const SC_L  = (52   / MK_W) * 100;
const SC_T  = (46   / MK_H) * 100;
const SC_W  = (918  / MK_W) * 100;
const SC_H  = (1990 / MK_H) * 100;
const SC_RX = (126  / 918)  * 100;
const SC_RY = (126  / 1990) * 100;
const MK_RATIO = MK_W / MK_H;

// ─── Device Types ─────────────────────────────────────────────────────────────
type Device = "iphone" | "android" | "feature-graphic";

// ─── Width Helpers ────────────────────────────────────────────────────────────
function phoneW(cW: number, cH: number, clamp = 0.84) {
  return Math.min(clamp, 0.72 * (cH / cW) * MK_RATIO);
}

// ─── Image Preloading ────────────────────────────────────────────────────────
const IMAGE_PATHS = [
  "/mockup.png",
  "/app-icon.png",
  "/screenshots/dashboard.png",
  "/screenshots/group.png",
  "/screenshots/standings.png",
];

const imageCache: Record<string, string> = {};

async function preloadAllImages() {
  await Promise.all(
    IMAGE_PATHS.map(async (path) => {
      const resp = await fetch(path);
      const blob = await resp.blob();
      const dataUrl = await new Promise<string>((resolve) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
      });
      imageCache[path] = dataUrl;
    })
  );
}

function img(path: string): string {
  return imageCache[path] || path;
}

// ─── Design Tokens ───────────────────────────────────────────────────────────
const ORANGE  = "#E8734A";
const ORANGE2 = "#FF9A6C";
const BG_DARK = "#0A0A0B";
const BG_MID  = "#111113";
const WHITE   = "#FFFFFF";
const MUTED   = "rgba(255,255,255,0.55)";

// ─── Device Frame Components ──────────────────────────────────────────────────
function Phone({ src, alt, style }: { src: string; alt: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: `${MK_W}/${MK_H}`, ...style }}>
      <img src={img("/mockup.png")} alt="" style={{ display: "block", width: "100%", height: "100%" }} draggable={false} />
      <div style={{
        position: "absolute", zIndex: 10, overflow: "hidden",
        left: `${SC_L}%`, top: `${SC_T}%`, width: `${SC_W}%`, height: `${SC_H}%`,
        borderRadius: `${SC_RX}% / ${SC_RY}%`,
      }}>
        <img src={src} alt={alt} style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} draggable={false} />
      </div>
    </div>
  );
}

function AndroidPhone({ src, alt, style }: { src: string; alt: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: "9/19.5", ...style }}>
      <div style={{
        width: "100%", height: "100%",
        borderRadius: "8% / 4%",
        background: "linear-gradient(160deg, #2a2a2e 0%, #18181b 100%)",
        boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.08), 0 8px 40px rgba(0,0,0,0.55)",
        position: "relative", overflow: "hidden",
      }}>
        <div style={{
          position: "absolute", top: "1.5%", left: "50%",
          transform: "translateX(-50%)", width: "3%", height: "1.4%",
          borderRadius: "50%", background: "#0d0d0f",
          border: "1px solid rgba(255,255,255,0.06)", zIndex: 20,
        }} />
        <div style={{
          position: "absolute", left: "3.5%", top: "2%",
          width: "93%", height: "96%",
          borderRadius: "5.5% / 2.6%", overflow: "hidden", background: "#000",
        }}>
          <img src={src} alt={alt} style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} draggable={false} />
        </div>
      </div>
    </div>
  );
}

// ─── Caption Component ────────────────────────────────────────────────────────
function Caption({ cW, label, headline, dark = false }: {
  cW: number;
  label: string;
  headline: React.ReactNode;
  dark?: boolean;
}) {
  const fg = dark ? WHITE : WHITE;
  const labelColor = ORANGE;
  return (
    <div style={{ textAlign: "center", color: fg }}>
      <div style={{
        fontSize: cW * 0.028, fontWeight: 600, letterSpacing: "0.12em",
        textTransform: "uppercase", color: labelColor, marginBottom: cW * 0.018,
      }}>
        {label}
      </div>
      <div style={{
        fontSize: cW * 0.092, fontWeight: 900, lineHeight: 1.0,
        color: WHITE, letterSpacing: "-0.02em",
      }}>
        {headline}
      </div>
    </div>
  );
}

// ─── Decorative Glow ─────────────────────────────────────────────────────────
function OrangeGlow({ cW, cH, opacity = 0.22, offsetY = 0.55 }: { cW: number; cH: number; opacity?: number; offsetY?: number }) {
  const size = cW * 1.6;
  return (
    <div style={{
      position: "absolute",
      left: "50%", top: `${offsetY * 100}%`,
      transform: "translate(-50%, -50%)",
      width: size, height: size,
      borderRadius: "50%",
      background: `radial-gradient(ellipse at center, ${ORANGE} 0%, transparent 65%)`,
      opacity,
      pointerEvents: "none",
      zIndex: 0,
    }} />
  );
}

// ─── Slide 1: Hero ────────────────────────────────────────────────────────────
function Slide1({ cW, cH, PhoneComp }: { cW: number; cH: number; PhoneComp: typeof Phone }) {
  const fw = phoneW(cW, cH) * 100;
  return (
    <div style={{ width: "100%", height: "100%", position: "relative", overflow: "hidden",
      background: `linear-gradient(180deg, ${BG_DARK} 0%, #13100E 100%)` }}>
      <OrangeGlow cW={cW} cH={cH} opacity={0.18} offsetY={0.72} />
      {/* Top grid lines decoration */}
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: cH * 0.5,
        background: `repeating-linear-gradient(90deg, transparent, transparent ${cW * 0.12 - 1}px, rgba(255,255,255,0.025) ${cW * 0.12}px)`,
        pointerEvents: "none", zIndex: 0 }} />
      {/* App icon row */}
      <div style={{ position: "absolute", top: cH * 0.058, left: 0, right: 0,
        display: "flex", justifyContent: "center", alignItems: "center", gap: cW * 0.03, zIndex: 5 }}>
        <img src={img("/app-icon.png")} alt="icon"
          style={{ width: cW * 0.11, height: cW * 0.11, borderRadius: cW * 0.022 }} draggable={false} />
        <span style={{ fontSize: cW * 0.042, fontWeight: 800, color: WHITE, letterSpacing: "-0.01em" }}>PES Arena</span>
      </div>
      {/* Caption */}
      <div style={{ position: "absolute", top: cH * 0.13, left: 0, right: 0,
        padding: `0 ${cW * 0.08}px`, zIndex: 5 }}>
        <Caption cW={cW} label="Sân chơi của bạn"
          headline={<>Số liệu<br />của bạn.</>} />
      </div>
      {/* Phone */}
      <PhoneComp
        src={img("/screenshots/dashboard.png")}
        alt="Dashboard"
        style={{
          position: "absolute", bottom: 0, zIndex: 10,
          width: `${fw}%`,
          left: "50%", transform: `translateX(-50%) translateY(12%)`,
        }}
      />
    </div>
  );
}

// ─── Slide 2: Group Stats ─────────────────────────────────────────────────────
function Slide2({ cW, cH, PhoneComp }: { cW: number; cH: number; PhoneComp: typeof Phone }) {
  const fw = phoneW(cW, cH, 0.80) * 100;
  return (
    <div style={{ width: "100%", height: "100%", position: "relative", overflow: "hidden",
      background: `linear-gradient(170deg, #150D08 0%, #0E0E12 55%, #121212 100%)` }}>
      {/* Orange accent strip left */}
      <div style={{
        position: "absolute", top: 0, left: 0, width: cW * 0.012, height: "100%",
        background: `linear-gradient(180deg, transparent 0%, ${ORANGE} 40%, transparent 100%)`,
        opacity: 0.7, zIndex: 0,
      }} />
      <OrangeGlow cW={cW} cH={cH} opacity={0.14} offsetY={0.35} />
      {/* Caption top */}
      <div style={{ position: "absolute", top: cH * 0.085, left: 0, right: 0,
        padding: `0 ${cW * 0.08}px`, zIndex: 5, textAlign: "center" }}>
        <Caption cW={cW} label="Nhóm"
          headline={<>Cạnh tranh<br />cùng đồng đội.</>} />
      </div>
      {/* Stats pills — nằm giữa caption và phone */}
      <div style={{
        position: "absolute", top: cH * 0.27, left: 0, right: 0,
        display: "flex", justifyContent: "center",
        flexWrap: "wrap", gap: cW * 0.025, zIndex: 5,
        padding: `0 ${cW * 0.06}px`,
      }}>
        {[
          { label: "Thành tích", icon: "🏆" },
          { label: "Thống kê", icon: "📊" },
          { label: "Lịch sử", icon: "📅" },
        ].map((p) => (
          <div key={p.label} style={{
            background: "rgba(232,115,74,0.13)",
            border: `1px solid rgba(232,115,74,0.28)`,
            borderRadius: cW * 0.06,
            padding: `${cW * 0.016}px ${cW * 0.032}px`,
            display: "flex", alignItems: "center", gap: cW * 0.014,
            fontSize: cW * 0.026, fontWeight: 600, color: ORANGE2,
            whiteSpace: "nowrap",
          }}>
            <span>{p.icon}</span>
            <span>{p.label}</span>
          </div>
        ))}
      </div>
      {/* Phone — shifted slightly left */}
      <PhoneComp
        src={img("/screenshots/group.png")}
        alt="Group"
        style={{
          position: "absolute", bottom: 0, zIndex: 10,
          width: `${fw}%`,
          left: "52%", transform: `translateX(-50%) translateY(10%)`,
        }}
      />
    </div>
  );
}

// ─── Slide 3: Standings ───────────────────────────────────────────────────────
function Slide3({ cW, cH, PhoneComp }: { cW: number; cH: number; PhoneComp: typeof Phone }) {
  const fw = phoneW(cW, cH) * 100;
  return (
    <div style={{ width: "100%", height: "100%", position: "relative", overflow: "hidden",
      background: `linear-gradient(160deg, #0A0A0B 0%, #141014 60%, #0A0A0B 100%)` }}>
      {/* Radial top accent */}
      <div style={{
        position: "absolute", top: 0, left: "50%",
        transform: "translateX(-50%)",
        width: cW * 1.2, height: cH * 0.5,
        background: `radial-gradient(ellipse at top, rgba(232,115,74,0.12) 0%, transparent 65%)`,
        pointerEvents: "none", zIndex: 0,
      }} />
      {/* Rank number decoration */}
      <div style={{
        position: "absolute", top: cH * 0.055, right: cW * 0.06,
        fontSize: cW * 0.28, fontWeight: 900,
        color: "rgba(232,115,74,0.06)", lineHeight: 1,
        letterSpacing: "-0.04em", zIndex: 0,
        userSelect: "none",
      }}>
        #1
      </div>
      {/* Caption */}
      <div style={{ position: "absolute", top: cH * 0.085, left: 0, right: 0,
        padding: `0 ${cW * 0.08}px`, zIndex: 5 }}>
        <Caption cW={cW} label="Bảng xếp hạng"
          headline={<>Ai đang<br />dẫn đầu?</>} />
        <div style={{ marginTop: cW * 0.04, fontSize: cW * 0.034, color: MUTED,
          textAlign: "center", lineHeight: 1.5, fontWeight: 400 }}>
          BXH cập nhật sau mỗi trận đấu.
        </div>
      </div>
      {/* Phone */}
      <PhoneComp
        src={img("/screenshots/standings.png")}
        alt="Standings"
        style={{
          position: "absolute", bottom: 0, zIndex: 10,
          width: `${fw}%`,
          left: "50%", transform: `translateX(-50%) translateY(12%)`,
        }}
      />
    </div>
  );
}

// ─── Feature Graphic ─────────────────────────────────────────────────────────
function FeatureGraphicSlide({ cW, cH }: { cW: number; cH: number }) {
  return (
    <div style={{
      width: "100%", height: "100%", position: "relative", overflow: "hidden",
      background: `linear-gradient(135deg, #0D0B09 0%, #120E0B 40%, #0A0A0B 100%)`,
      display: "flex", alignItems: "center",
    }}>
      {/* Glow behind icon */}
      <div style={{
        position: "absolute", left: cW * 0.12, top: "50%", transform: "translateY(-50%)",
        width: cH * 1.2, height: cH * 1.2, borderRadius: "50%",
        background: `radial-gradient(ellipse at center, rgba(232,115,74,0.25) 0%, transparent 65%)`,
        pointerEvents: "none",
      }} />
      {/* Right glow */}
      <div style={{
        position: "absolute", right: -cW * 0.1, top: "50%", transform: "translateY(-50%)",
        width: cH * 1.5, height: cH * 1.5, borderRadius: "50%",
        background: `radial-gradient(ellipse at center, rgba(232,115,74,0.08) 0%, transparent 60%)`,
        pointerEvents: "none",
      }} />
      {/* Flex row: trái icon+tên, phải tagline */}
      <div style={{
        position: "relative", zIndex: 5,
        width: "100%",
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: `0 ${cW * 0.06}px`,
        boxSizing: "border-box",
      }}>
        {/* Left: icon + name + tagline */}
        <div style={{ display: "flex", alignItems: "center", gap: cW * 0.032, flex: "0 0 auto", maxWidth: "50%" }}>
          <img src={img("/app-icon.png")} alt="icon"
            style={{
              width: cH * 0.48, height: cH * 0.48,
              borderRadius: cH * 0.09,
              boxShadow: `0 8px 32px rgba(0,0,0,0.6)`,
              flexShrink: 0,
            }} draggable={false} />
          <div>
            <div style={{
              fontSize: cW * 0.058, fontWeight: 900,
              color: WHITE, letterSpacing: "-0.02em", lineHeight: 1.1,
            }}>
              PES Arena
            </div>
            <div style={{
              fontSize: cW * 0.026, color: MUTED,
              marginTop: cH * 0.05, fontWeight: 400, lineHeight: 1.45,
            }}>
              Tạo nhóm, theo dõi số liệu,<br />cạnh tranh cùng đồng đội.
            </div>
            <div style={{
              marginTop: cH * 0.07,
              width: cW * 0.09, height: 3,
              background: `linear-gradient(90deg, ${ORANGE}, transparent)`,
              borderRadius: 2,
            }} />
          </div>
        </div>
        {/* Right: tagline */}
        <div style={{ textAlign: "right", flex: "0 0 auto", maxWidth: "40%" }}>
          <div style={{
            fontSize: cW * 0.036, fontWeight: 800, color: WHITE,
            lineHeight: 1.2, letterSpacing: "-0.01em",
          }}>
            Số liệu của bạn.<br />
            <span style={{ color: ORANGE }}>Câu chuyện của bạn.</span>
          </div>
          <div style={{
            marginTop: cH * 0.07, fontSize: cW * 0.021,
            color: MUTED, fontWeight: 400,
          }}>
            Miễn phí — App Store & Google Play
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Slide Preview Wrapper ────────────────────────────────────────────────────
function ScreenshotPreview({ children, cW, cH }: { children: React.ReactNode; cW: number; cH: number }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => {
      const s = el.clientWidth / cW;
      setScale(s);
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, [cW]);

  return (
    <div ref={containerRef} style={{ width: "100%", position: "relative", paddingBottom: `${(cH / cW) * 100}%` }}>
      <div style={{
        position: "absolute", top: 0, left: 0,
        width: cW, height: cH,
        transformOrigin: "top left", transform: `scale(${scale})`,
        overflow: "hidden",
        borderRadius: 12,
        boxShadow: "0 4px 24px rgba(0,0,0,0.18)",
      }}>
        {children}
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function ScreenshotsPage() {
  const [ready, setReady] = useState(false);
  const [device, setDevice] = useState<Device>("iphone");
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exporting, setExporting] = useState<string | null>(null);

  const exportRefs = useRef<(HTMLDivElement | null)[]>([]);

  useEffect(() => {
    preloadAllImages().then(() => setReady(true));
  }, []);

  const { cW, cH, currentSizes } = (() => {
    if (device === "android") return { cW: AW, cH: AH, currentSizes: ANDROID_SIZES as typeof ANDROID_SIZES };
    if (device === "feature-graphic") return { cW: FGW, cH: FGH, currentSizes: FG_SIZES as typeof FG_SIZES };
    return { cW: W, cH: H, currentSizes: IPHONE_SIZES as typeof IPHONE_SIZES };
  })();

  const PhoneComp = device === "android" ? AndroidPhone : Phone;

  type SlideEntry = { id: string; el: React.ReactNode };

  const slides: SlideEntry[] = device === "feature-graphic"
    ? [{ id: "feature-graphic", el: <FeatureGraphicSlide cW={cW} cH={cH} /> }]
    : [
        { id: "hero",      el: <Slide1 cW={cW} cH={cH} PhoneComp={PhoneComp as typeof Phone} /> },
        { id: "group",     el: <Slide2 cW={cW} cH={cH} PhoneComp={PhoneComp as typeof Phone} /> },
        { id: "standings", el: <Slide3 cW={cW} cH={cH} PhoneComp={PhoneComp as typeof Phone} /> },
      ];

  async function captureSlide(el: HTMLElement, w: number, h: number): Promise<string> {
    el.style.left = "0px";
    el.style.opacity = "1";
    el.style.zIndex = "-1";
    const opts = { width: w, height: h, pixelRatio: 1, cacheBust: true };
    await toPng(el, opts);
    const dataUrl = await toPng(el, opts);
    el.style.left = "-9999px";
    el.style.opacity = "";
    el.style.zIndex = "";
    return dataUrl;
  }

  const exportAll = useCallback(async () => {
    const size = currentSizes[sizeIdx] as { w: number; h: number; label: string };
    for (let i = 0; i < slides.length; i++) {
      setExporting(`${i + 1}/${slides.length}`);
      const el = exportRefs.current[i];
      if (!el) continue;
      const dataUrl = await captureSlide(el, size.w, size.h);
      const a = document.createElement("a");
      a.href = dataUrl;
      a.download = `${String(i + 1).padStart(2, "0")}-${slides[i].id}-${device}-${size.w}x${size.h}.png`;
      a.click();
      await new Promise((r) => setTimeout(r, 350));
    }
    setExporting(null);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [device, sizeIdx, slides.length]);

  if (!ready) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#f3f4f6" }}>
        <p style={{ color: "#6b7280", fontSize: 16 }}>Loading assets…</p>
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "#f3f4f6", position: "relative", overflowX: "hidden" }}>

      {/* ── Toolbar ── */}
      <div style={{ position: "sticky", top: 0, zIndex: 50, background: "white", borderBottom: "1px solid #e5e7eb", display: "flex", alignItems: "center" }}>

        {/* Scrollable controls */}
        <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, padding: "10px 16px", overflowX: "auto", minWidth: 0 }}>
          <span style={{ fontWeight: 700, fontSize: 14, whiteSpace: "nowrap", color: "#111" }}>PES Arena · Screenshots</span>

          {/* Device tabs */}
          <div style={{ display: "flex", gap: 4, background: "#f3f4f6", borderRadius: 8, padding: 4, flexShrink: 0 }}>
            {(["iphone", "android", "feature-graphic"] as Device[]).map((d) => (
              <button key={d} onClick={() => { setDevice(d); setSizeIdx(0); }}
                style={{ padding: "4px 14px", borderRadius: 6, border: "none", cursor: "pointer", fontSize: 12, fontWeight: 600, whiteSpace: "nowrap",
                  background: device === d ? "white" : "transparent",
                  color: device === d ? "#2563eb" : "#6b7280" }}>
                {d === "iphone" ? "iPhone" : d === "android" ? "Android" : "Feature Graphic"}
              </button>
            ))}
          </div>

          {/* Size selector */}
          {device !== "feature-graphic" && (
            <select value={sizeIdx} onChange={(e) => setSizeIdx(Number(e.target.value))}
              style={{ fontSize: 12, border: "1px solid #e5e7eb", borderRadius: 6, padding: "4px 10px", background: "white" }}>
              {currentSizes.map((s, i) => (
                <option key={i} value={i}>{s.label} — {s.w}×{s.h}</option>
              ))}
            </select>
          )}
        </div>

        {/* Export button — always visible */}
        <div style={{ flexShrink: 0, padding: "10px 16px", borderLeft: "1px solid #e5e7eb" }}>
          <button onClick={exportAll} disabled={!!exporting}
            style={{ padding: "7px 20px", background: exporting ? "#93c5fd" : "#2563eb", color: "white",
              border: "none", borderRadius: 8, fontSize: 12, fontWeight: 600,
              cursor: exporting ? "default" : "pointer", whiteSpace: "nowrap" }}>
            {exporting ? `Exporting… ${exporting}` : "Export All"}
          </button>
        </div>
      </div>

      {/* ── Grid ── */}
      <div style={{ padding: 24, display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 20 }}>
        {slides.map((slide, i) => (
          <div key={slide.id}>
            <div style={{ fontSize: 11, fontWeight: 600, color: "#6b7280", marginBottom: 8, textTransform: "uppercase", letterSpacing: "0.08em" }}>
              {String(i + 1).padStart(2, "0")} — {slide.id}
            </div>
            <ScreenshotPreview cW={cW} cH={cH}>
              {slide.el}
            </ScreenshotPreview>
          </div>
        ))}
      </div>

      {/* ── Off-screen export elements ── */}
      <div style={{ position: "absolute", left: "-9999px", top: 0, zIndex: 0 }}>
        {slides.map((slide, i) => {
          const size = currentSizes[sizeIdx] as { w: number; h: number };
          return (
            <div
              key={`export-${device}-${slide.id}`}
              ref={(el) => { exportRefs.current[i] = el; }}
              style={{ position: "absolute", left: "-9999px", width: size.w, height: size.h, overflow: "hidden" }}
            >
              {slide.el}
            </div>
          );
        })}
      </div>
    </div>
  );
}
