"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";

/**
 * HeroFlux — a GPU particle flux that stages the product's core idea:
 * VOICE becoming TEXT. Particles are born on the left as a turbulent, audio-like
 * cloud (curl-noise drift, a "breathing" amplitude), stream rightward through a
 * flow field, and resolve on the right into a calm, ruled line — speech settling
 * into a sentence. A faint warm "rec" ember rides the leading edge.
 *
 * One canvas. All motion lives on the GPU (a single ShaderMaterial; particle
 * lifetimes recycle in the vertex shader off a per-point seed — no per-frame CPU
 * buffer writes). Themed off the site's --fg / --accent / --rec CSS vars and
 * re-themed live on light/dark toggle. SSR-safe ("use client", every window/DOM
 * access inside useEffect), paused offscreen and on prefers-reduced-motion,
 * subtle mouse parallax, pointer-events: none. Fully disposed on unmount.
 *
 * Drop it behind the hero as a full-bleed, absolutely-positioned backdrop:
 *   <HeroFlux className="absolute inset-0 -z-10" />
 */
export default function HeroFlux({ className = "" }: { className?: string }) {
  const mountRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return;
    if (typeof window === "undefined") return;

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const scene = new THREE.Scene();
    // Orthographic so the flux reads as a flat, designed plane (no perspective
    // distortion at the bleed edges). Units are normalized to ~[-1.6,1.6] x.
    const camera = new THREE.OrthographicCamera(-1.6, 1.6, 1, -1, 0.1, 10);
    camera.position.z = 3;

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, powerPreference: "high-performance" });
    } catch {
      return; // No WebGL — fail silent, the section still renders without the backdrop.
    }
    renderer.setPixelRatio(dpr);
    renderer.setClearAlpha(0);
    mount.appendChild(renderer.domElement);

    // ---- Particles. Each carries an immutable seed + base lane; the shader
    // animates position from those, so the buffer is uploaded exactly once. ----
    const COUNT = reduced ? 2600 : 11000;
    const aSeed = new Float32Array(COUNT);      // 0..1 phase offset (recycle)
    const aLane = new Float32Array(COUNT);      // -1..1 vertical band
    const aRand = new Float32Array(COUNT);      // 0..1 per-point jitter
    const aSpeed = new Float32Array(COUNT);     // 0.6..1.4 speed multiplier
    for (let i = 0; i < COUNT; i++) {
      aSeed[i] = Math.random();
      // Bias lanes toward the centre so the resolved "line" is dense in the middle.
      const g = (Math.random() + Math.random() + Math.random()) / 3 - 0.5;
      aLane[i] = g * 2;
      aRand[i] = Math.random();
      aSpeed[i] = 0.6 + Math.random() * 0.8;
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("aSeed", new THREE.BufferAttribute(aSeed, 1));
    geometry.setAttribute("aLane", new THREE.BufferAttribute(aLane, 1));
    geometry.setAttribute("aRand", new THREE.BufferAttribute(aRand, 1));
    geometry.setAttribute("aSpeed", new THREE.BufferAttribute(aSpeed, 1));
    // position is unused for layout but three wants a "position" attribute to
    // compute the draw range / bounding sphere.
    geometry.setAttribute("position", new THREE.BufferAttribute(new Float32Array(COUNT * 3), 3));
    geometry.boundingSphere = new THREE.Sphere(new THREE.Vector3(0, 0, 0), 4);

    const cssVar = (name: string, fallback: string) => {
      const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
      try { return new THREE.Color(v || fallback); } catch { return new THREE.Color(fallback); }
    };
    const readColors = () => ({
      fg: cssVar("--fg", "#f4f4f6"),
      accent: cssVar("--accent", "#f4ede0"),
      rec: cssVar("--rec", "#ff5a4d"),
    });
    const c0 = readColors();

    const uniforms = {
      uTime: { value: 0 },
      uDpr: { value: dpr },
      uAspect: { value: 1 },
      uMouse: { value: new THREE.Vector2(0, 0) },
      uColor: { value: c0.fg.clone() },
      uAccent: { value: c0.accent.clone() },
      uRec: { value: c0.rec.clone() },
      uAmp: { value: 1 }, // "audio" amplitude — eased, breathing
    };

    const material = new THREE.ShaderMaterial({
      uniforms,
      transparent: true,
      depthWrite: false,
      depthTest: false,
      blending: THREE.AdditiveBlending,
      vertexShader: /* glsl */ `
        uniform float uTime;
        uniform float uDpr;
        uniform float uAspect;
        uniform vec2  uMouse;
        uniform float uAmp;

        attribute float aSeed;
        attribute float aLane;
        attribute float aRand;
        attribute float aSpeed;

        varying float vLife;   // 0 (born) .. 1 (resolved)
        varying float vEdge;   // leading-edge ember weight
        varying float vTurb;   // turbulence (chaos -> calm) for color/alpha
        varying float vRand;

        // cheap value noise
        float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
        float noise(vec2 p){
          vec2 i = floor(p), f = fract(p);
          float a = hash(i), b = hash(i + vec2(1.0,0.0));
          float c = hash(i + vec2(0.0,1.0)), d = hash(i + vec2(1.0,1.0));
          vec2 u = f*f*(3.0-2.0*f);
          return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        }

        void main() {
          // Recycling life: each point marches 0->1 then wraps, offset by seed.
          float life = fract(aSeed + uTime * 0.052 * aSpeed);
          vLife = life;
          vRand = aRand;

          // X sweeps left (-1.45, voice) to right (1.45, text).
          float x = mix(-1.45, 1.45, life);

          // Turbulence collapses as the point travels: chaos on the left,
          // a clean ruled line on the right. amp "breathes" like spoken audio.
          float calm = smoothstep(0.18, 0.96, life);     // 0 chaotic -> 1 calm
          float turb = (1.0 - calm);
          vTurb = turb;

          // Flow-field displacement (curl-ish): two noise octaves, scaled by turb.
          float t = uTime * 0.35;
          float n1 = noise(vec2(x * 2.2 + t, aLane * 3.0 + aSeed * 12.0));
          float n2 = noise(vec2(x * 4.5 - t * 1.3, aLane * 5.0 + aRand * 9.0));
          float swirl = (n1 - 0.5) * 1.5 + (n2 - 0.5) * 0.8;

          // Base vertical position: wide spray on the left, funnels to a thin
          // line on the right (the "sentence").
          float spread = mix(0.85, 0.07, calm);
          float audio = sin(uTime * 1.6 + aLane * 6.2831 + aSeed * 30.0) * 0.18 * uAmp;
          float y = aLane * spread
                  + swirl * spread * 1.2
                  + audio * turb
                  + sin(x * 9.0 + uTime * 0.8) * 0.012 * calm; // faint ripple on the line

          // Subtle mouse parallax — points lean toward the cursor, more so when
          // chaotic (the cloud is "stirred", the resolved line stays composed).
          y += uMouse.y * 0.10 * (0.4 + turb);
          x += uMouse.x * 0.06 * (0.4 + turb);

          vEdge = smoothstep(0.55, 0.0, abs(life - 0.30)) * turb; // ember near birth-front

          vec3 pos = vec3(x, y, 0.0);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

          // Size: larger, softer in the cloud; crisp and small on the line.
          float size = mix(3.4, 1.7, calm) + vEdge * 2.2;
          // fade in at birth, fade out at death so recycling is invisible
          float lifeFade = smoothstep(0.0, 0.06, life) * smoothstep(1.0, 0.86, life);
          gl_PointSize = size * uDpr * (0.5 + lifeFade);
        }
      `,
      fragmentShader: /* glsl */ `
        precision mediump float;
        uniform vec3 uColor;
        uniform vec3 uAccent;
        uniform vec3 uRec;
        varying float vLife;
        varying float vEdge;
        varying float vTurb;
        varying float vRand;

        void main() {
          vec2 c = gl_PointCoord - 0.5;
          float d = dot(c, c);
          if (d > 0.25) discard;
          float soft = smoothstep(0.25, 0.0, d);

          // Color narrative: warm accent in the turbulent cloud -> clean fg on
          // the resolved line; a warm "rec" ember on the leading front.
          vec3 col = mix(uColor, uAccent, vTurb * 0.6);
          col = mix(col, uRec, vEdge * 0.7);

          // Alpha: cloud is airy + dithered (per-point), the line is crisp.
          float lifeFade = smoothstep(0.0, 0.07, vLife) * smoothstep(1.0, 0.84, vLife);
          float a = soft * lifeFade;
          a *= mix(0.34, 0.62, 1.0 - vTurb);   // line slightly brighter than haze
          a *= 0.7 + vRand * 0.5;              // organic twinkle
          a += vEdge * soft * 0.35;            // ember glow

          gl_FragColor = vec4(col, a);
        }
      `,
    });

    const points = new THREE.Points(geometry, material);
    scene.add(points);

    const resize = () => {
      const w = mount.clientWidth || 1;
      const h = mount.clientHeight || 1;
      renderer.setSize(w, h, false);
      const aspect = w / h;
      uniforms.uAspect.value = aspect;
      // Keep X framing constant; let Y scale with aspect so the field bleeds.
      camera.left = -1.6;
      camera.right = 1.6;
      camera.top = 1.6 / aspect;
      camera.bottom = -1.6 / aspect;
      camera.updateProjectionMatrix();
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(mount);

    // Live re-theme on light/dark toggle.
    const themeObs = new MutationObserver(() => {
      const c = readColors();
      uniforms.uColor.value.copy(c.fg);
      uniforms.uAccent.value.copy(c.accent);
      uniforms.uRec.value.copy(c.rec);
    });
    themeObs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

    // Pause offscreen.
    let visible = true;
    const io = new IntersectionObserver(([e]) => { visible = e.isIntersecting; }, { threshold: 0 });
    io.observe(mount);

    // Subtle mouse parallax — eased toward target, listener on window so it
    // works even though the canvas itself is pointer-events: none.
    const target = new THREE.Vector2(0, 0);
    const onMove = (e: PointerEvent) => {
      target.x = (e.clientX / window.innerWidth) * 2 - 1;
      target.y = -((e.clientY / window.innerHeight) * 2 - 1);
    };
    if (!reduced) window.addEventListener("pointermove", onMove, { passive: true });

    let raf = 0;
    const clock = new THREE.Clock();
    let amp = 1;
    const renderFrame = (time: number) => {
      uniforms.uTime.value = time;
      // Ease mouse + "breathing" amplitude.
      uniforms.uMouse.value.x += (target.x - uniforms.uMouse.value.x) * 0.04;
      uniforms.uMouse.value.y += (target.y - uniforms.uMouse.value.y) * 0.04;
      const targetAmp = 0.75 + 0.45 * (0.5 + 0.5 * Math.sin(time * 0.9));
      amp += (targetAmp - amp) * 0.05;
      uniforms.uAmp.value = amp;
      renderer.render(scene, camera);
    };

    const tick = () => {
      raf = requestAnimationFrame(tick);
      if (!visible) return;
      renderFrame(clock.getElapsedTime());
    };

    if (reduced) {
      uniforms.uTime.value = 6.0;
      uniforms.uAmp.value = 0.4;
      renderFrame(6.0); // one composed static frame
    } else {
      tick();
    }

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      io.disconnect();
      themeObs.disconnect();
      window.removeEventListener("pointermove", onMove);
      geometry.dispose();
      material.dispose();
      renderer.dispose();
      if (renderer.domElement.parentNode === mount) mount.removeChild(renderer.domElement);
    };
  }, []);

  return (
    <div
      ref={mountRef}
      aria-hidden
      className={className}
      style={{ pointerEvents: "none" }}
    />
  );
}
