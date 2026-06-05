import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Acknowledgements — Verba",
  description: "Open-source software and on-device models that power Verba.",
};

const groups: { title: string; items: { name: string; note: string; url: string }[] }[] = [
  {
    title: "Speech-recognition models",
    items: [
      { name: "OpenAI Whisper", note: "© 2022 OpenAI · MIT License", url: "https://github.com/openai/whisper" },
      { name: "NVIDIA Parakeet TDT 0.6B v3", note: "© NVIDIA · CC-BY-4.0 · used as a Core ML conversion (modified)", url: "https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3" },
    ],
  },
  {
    title: "Frameworks & converted weights",
    items: [
      { name: "WhisperKit", note: "© 2024 argmax, inc. · MIT License", url: "https://github.com/argmaxinc/WhisperKit" },
      { name: "Whisper Core ML weights", note: "converted by Argmax, derived from OpenAI Whisper (MIT)", url: "https://huggingface.co/argmaxinc/whisperkit-coreml" },
      { name: "FluidAudio", note: "© FluidInference · Apache License 2.0", url: "https://github.com/FluidInference/FluidAudio" },
      { name: "Parakeet Core ML weights", note: "converted by FluidInference, derived from NVIDIA Parakeet TDT v3 (CC-BY-4.0)", url: "https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml" },
    ],
  },
  {
    title: "Supporting libraries",
    items: [
      { name: "Sparkle", note: "MIT License", url: "https://sparkle-project.org" },
      { name: "swift-transformers · swift-jinja", note: "Apache-2.0 · Hugging Face", url: "https://github.com/huggingface/swift-transformers" },
      { name: "Apple swift-argument-parser, swift-collections, swift-crypto, swift-asn1", note: "Apache-2.0", url: "https://github.com/apple" },
    ],
  },
];

export default function Acknowledgements() {
  return (
    <main className="mx-auto max-w-3xl px-6 pb-24">
      <nav className="flex items-center justify-between py-6">
        <Link href="/" className="text-[17px] font-semibold tracking-tight">Verba</Link>
        <Link href="/" className="text-sm muted hover:text-[var(--fg)]">← Home</Link>
      </nav>
      <section className="py-12">
        <h1 className="text-4xl font-semibold tracking-tight">Acknowledgements</h1>
        <p className="mt-4 muted text-balance">
          Verba runs on-device using open-source software and models. We're grateful to their
          authors. Transcription happens on your Mac with the models below.
        </p>
        <div className="mt-10 space-y-8">
          {groups.map((g) => (
            <div key={g.title}>
              <h2 className="text-sm uppercase tracking-widest muted">{g.title}</h2>
              <div className="mt-3 space-y-2">
                {g.items.map((it) => (
                  <a key={it.name} href={it.url} target="_blank" rel="noreferrer" className="glass block rounded-xl p-4 transition hover:bg-[var(--tint-strong)]">
                    <div className="font-medium">{it.name}</div>
                    <div className="text-sm muted">{it.note}</div>
                  </a>
                ))}
              </div>
            </div>
          ))}
        </div>
        <p className="mt-10 text-xs muted">
          NVIDIA Parakeet TDT v3 is used under CC-BY-4.0 (https://creativecommons.org/licenses/by/4.0/),
          as a Core ML conversion of the original weights. Full license texts ship inside the app.
        </p>
      </section>
    </main>
  );
}
