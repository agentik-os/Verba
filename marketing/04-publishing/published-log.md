---
project: Verba
layer: publishing
purpose: journal des publications réellement programmées/envoyées via omega-zernio (SSOT exécution)
status: live
---
# Journal de publication — Verba

> Une entrée par post réellement programmé/publié. Les calendriers (`05-calendar/`) sont le plan ; ce fichier est le fait.

## 2026-07-02 (J1)

### Post 1 — X (EN, plan 14j J1, P3 BYO-AI) — 🤖 AUTO
- **zernio _id :** `6a4666d680802ae763d7edff` · status `scheduled` · `2026-07-02T14:00:00Z` (16:00 CEST)
- **Compte :** twitter @verba_run
- **Texte (raccourci pour la limite 280, 274/280) :**
  > Have Claude Code? Then you can dictate all day on your Mac — no API key, no extra AI bill.
  >
  > Verba reuses the sub you already pay for: you speak, it transcribes on-device, your own Claude cleans it up right at your cursor.
  >
  > Stop paying twice for AI. → verba.run
- **Visuel :** Higgsfield nano_banana_2, job `9d66729a-b588-4d17-826e-1aded1c129e2` (1:1 cost-math, deux abos barrés vs $9.99, on-brand #050507/#ff5a4d).

### Post 2 — X (FR, plan 90j J1, P2 privacy) — 🤖 AUTO
- **zernio _id :** `6a4666d980802ae763d7ee4e` · status `scheduled` · `2026-07-02T16:30:00Z` (18:30 CEST)
- **Compte :** twitter @verba_run
- **Décision opérationnelle :** les 2 plans (14j EN + 90j FR) visaient tous deux X à 16:00 → décalé la piste FR à 18:30 pour ne pas doubler le même créneau sur le même compte.
- **Texte (raccourci 264/280, accents corrigés vs JSON source) :**
  > Petite question gênante : ton app de dictée, elle upload ta voix en ce moment ?
  >
  > Verba fait l'inverse : Whisper tourne sur ton Mac, ton audio ne le quitte jamais. Historique local, vrai bouton off.
  >
  > Privé par défaut. À toi par conception. → verba.run
- **Visuel :** Higgsfield nano_banana_2, job `8f8435a0-bc9b-4321-86a6-84c004a03d00` (1:1 MacBook outline, waveform qui reste dans l'écran, cadenas, caption FR « Privé par défaut. Ton audio ne quitte jamais ton Mac. »). Une v1 avec caption EN (job `ea4f051b-b103-4c66-a999-85b68dee00b7`) a été régénérée en FR pour cohérence de piste.

**Garde-fous vérifiés :** pas de `$149 Founder`, pas d'iOS, claim privacy exact (« audio ne quitte jamais ton Mac / bouton off »), pas de « Composio ».

**Leçon récurrente :** la limite X compte l'URL à 23 chars (t.co) — viser ≤ 266 chars bruts avec `verba.run` dans le texte. Les textes des calendriers 14j/90j dépassent souvent 280 → toujours resserrer + `--dry-run` avant schedule.
