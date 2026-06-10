"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";

/**
 * A GPU sound-wave field: a plane of points rippling like spoken audio.
 * Raw Three.js (one canvas, shader-driven so there are no per-frame CPU buffer
 * updates), themed off the site's --fg color, paused when offscreen or when the
 * visitor prefers reduced motion. Purely decorative: pointer-events are off.
 */
export default function WaveField({ className = "" }: { className?: string }) {
  const mountRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return;

    if (typeof window === "undefined") return;

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(50, 1, 0.1, 100);
    camera.position.set(0, 3.1, 6);
    camera.lookAt(0, 0, -1.5);

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, powerPreference: "high-performance" });
    } catch {
      return; // No WebGL — fail silent.
    }
    renderer.setPixelRatio(dpr);
    renderer.setClearAlpha(0);
    mount.appendChild(renderer.domElement);

    // Grid of points across the XZ plane (y is displaced in the vertex shader).
    const COLS = 140;
    const ROWS = 64;
    const W = 9;
    const D = 7;
    const positions = new Float32Array(COLS * ROWS * 3);
    let i = 0;
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        positions[i++] = (c / (COLS - 1) - 0.5) * 2 * W; // x
        positions[i++] = 0; // y baseline
        positions[i++] = (r / (ROWS - 1) - 0.5) * 2 * D - 1.5; // z (pushed back)
      }
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));

    const cssColor = (name: string, fallback: string) => {
      const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
      try { return new THREE.Color(v || fallback); } catch { return new THREE.Color(fallback); }
    };
    const readFg = () => cssColor("--fg", "#f3f4f7");
    const readAccent = () => cssColor("--accent", "#f4ede0");

    const uniforms = {
      uTime: { value: 0 },
      uSize: { value: 26 },
      uDpr: { value: dpr },
      uColor: { value: readFg() },
      uAccent: { value: readAccent() },
      uMouse: { value: new THREE.Vector2(0, 0) },
    };

    const material = new THREE.ShaderMaterial({
      uniforms,
      transparent: true,
      depthWrite: false,
      vertexShader: /* glsl */ `
        uniform float uTime;
        uniform float uSize;
        uniform float uDpr;
        uniform vec2  uMouse;
        varying float vFade;
        varying float vWave;
        void main() {
          vec3 p = position;
          // A travelling, voice-like swell — three interfering sines plus a
          // gentle cursor-led tilt so the field leans toward the pointer.
          float w =
              sin(p.x * 0.55 + uTime * 0.9) * 0.5
            + sin(p.z * 0.7  - uTime * 0.7) * 0.42
            + sin((p.x + p.z) * 0.4 + uTime * 0.5) * 0.32
            + sin(p.x * 1.4 - p.z * 0.9 + uTime * 1.3) * 0.12; // fine ripple
          w += uMouse.x * p.x * 0.012 + uMouse.y * 0.18;       // subtle parallax tilt
          p.y = w;
          vWave = w;
          vec4 mv = modelViewMatrix * vec4(p, 1.0);
          vFade = clamp(1.0 - (-mv.z - 3.0) / 15.0, 0.0, 1.0);
          gl_PointSize = uSize * uDpr * (1.0 / -mv.z);
          gl_Position = projectionMatrix * mv;
        }
      `,
      fragmentShader: /* glsl */ `
        uniform vec3 uColor;
        uniform vec3 uAccent;
        varying float vFade;
        varying float vWave;
        void main() {
          vec2 c = gl_PointCoord - 0.5;
          float d = dot(c, c);
          if (d > 0.25) discard;
          float soft = smoothstep(0.25, 0.0, d);
          // Crests catch a warm accent + lift toward white; troughs stay base fg.
          float hi = smoothstep(0.1, 1.0, vWave);
          vec3 col = mix(uColor, uAccent, hi * 0.55);
          col = mix(col, vec3(1.0), smoothstep(0.6, 1.1, vWave) * 0.4);
          gl_FragColor = vec4(col, soft * vFade * (0.7 + hi * 0.3) * 0.9);
        }
      `,
    });

    const points = new THREE.Points(geometry, material);
    scene.add(points);

    const resize = () => {
      const w = mount.clientWidth || 1;
      const h = mount.clientHeight || 1;
      renderer.setSize(w, h, false);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(mount);

    // Re-theme the points when the user toggles light/dark.
    const themeObs = new MutationObserver(() => {
      uniforms.uColor.value = readFg();
      uniforms.uAccent.value = readAccent();
    });
    themeObs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

    // Pause the loop when the canvas is scrolled out of view.
    let visible = true;
    const io = new IntersectionObserver(([e]) => { visible = e.isIntersecting; }, { threshold: 0 });
    io.observe(mount);

    // Subtle mouse parallax (canvas is pointer-events:none, so listen on window).
    const mTarget = new THREE.Vector2(0, 0);
    const onMove = (e: PointerEvent) => {
      mTarget.x = (e.clientX / window.innerWidth) * 2 - 1;
      mTarget.y = -((e.clientY / window.innerHeight) * 2 - 1);
    };
    if (!reduced) window.addEventListener("pointermove", onMove, { passive: true });

    let raf = 0;
    const clock = new THREE.Clock();
    const tick = () => {
      raf = requestAnimationFrame(tick);
      if (!visible) return;
      uniforms.uTime.value = clock.getElapsedTime();
      uniforms.uMouse.value.x += (mTarget.x - uniforms.uMouse.value.x) * 0.04;
      uniforms.uMouse.value.y += (mTarget.y - uniforms.uMouse.value.y) * 0.04;
      renderer.render(scene, camera);
    };
    if (reduced) {
      uniforms.uTime.value = 1.2;
      renderer.render(scene, camera); // one static frame
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

  return <div ref={mountRef} aria-hidden className={className} style={{ pointerEvents: "none" }} />;
}
