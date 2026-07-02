---
project: Verba
layer: copy
produced_by: mk-copywriting
status: filled
reconciles_with: ../../.agents/product-marketing.md §Customer Language + ../social-content.md + website/app/page.tsx
note: La copy publiable cible des Mac-users anglophones (décision canonique). EN = à shipper sur verba.run/ads anglophones ; FR = variantes pour le marché francophone. Voir 00-context/product-marketing.md §Note de langue.
---
# Core Copy — Verba

## Taglines (5)
| # | EN (ship) | FR (variante) |
|---|---|---|
| 1 | **Speak it. Send it clean.** | Dis-le. Envoie-le propre. |
| 2 | The Mac dictation app that became a voice agent. | L'app de dictée Mac devenue agent vocal. |
| 3 | Your voice shouldn't just type. It should *do*. | Ta voix ne devrait pas juste écrire. Elle devrait *agir*. |
| 4 | Bring your own AI. Stop paying twice. | Apporte ton IA. Arrête de payer deux fois. |
| 5 | Private by default. Yours by design. | Privé par défaut. À toi par conception. |

## Hero headline + subhead variants
- **H1 (privacy + BYO) :** *Speak it. Send it clean — on your Mac, with the AI you already pay for.*
  **Sub :** Press a key, talk, and Verba turns your rambling into clean, ready-to-send text — on-device, then your own Claude restructures it. No upload. No second AI bill.
- **H2 (action / JARVIS) :** *Now your voice doesn't just type. It acts.*
  **Sub :** Say "create the Linear issue" or "email Anna the summary." JARVIS plans the steps on your Mac, shows you exactly what it'll do, and acts only after you confirm — across 1,000+ connected apps.
- **H3 (developer wedge) :** *Dictate to Claude Code without typing a word.*
  **Sub :** Speak a 20-minute spec, get a clean Opus-grade prompt pasted into Cursor or Claude Code — using the subscription you already have. No key, no markup.
- **FR (privacy) :** *Dis-le, envoie-le propre — sur ton Mac, avec l'IA que tu paies déjà.*

## Value-prop blocks
1. **Privé par défaut** — Whisper/Parakeet on-device : ton audio ne quitte jamais ton Mac et n'est jamais uploadé (la sync est texte-only). Historique local avec off-switch + auto-prune ; clés dans le Keychain. *Même la planification d'action de JARVIS tourne on-device.*
2. **Bring your own AI** — réutilise ton abo **Claude Code sans clé**, ou clé Anthropic / OpenRouter / Ollama local. Verba ne fait **aucun** appel API facturé → zéro marge sur l'IA que tu paies déjà.
3. **Voice → action (JARVIS)** — dicte l'intention, JARVIS planifie, te montre, **agit sur ta confirmation** — sur 1 000+ apps connectées + actions Mac natives.
4. **Fait plus que transcrire** — Context (vision, lit ton écran), Notes (1 h structuré), Translate (parle ta langue, envoie la leur), dictées empilées.

## Feature → benefit table
| Feature (produit) | Benefit (à dire) |
|---|---|
| On-device Whisper/Parakeet | « Ton audio ne quitte jamais ton Mac. » |
| Claude Code sans clé (`ClaudeCode.swift`) | « Réutilise l'abo que tu paies déjà — zéro marge. » |
| JARVIS confirm-gated (`ActionExecutor.swift`) | « Dis-le, confirme, c'est fait — il demande avant d'agir. » |
| 6 modes routés Haiku/Sonnet/Opus | « Le bon modèle à chaque tâche — tu paies la puissance là où ça compte. » |
| Context mode (vision) | « Réponds au mail à l'écran sans copier-coller. » |
| Notes (jusqu'à 1 h) | « 40 min de ramble → un doc structuré. » |
| Translate (15 cibles) | « Parle français, envoie en anglais natif. » |
| 9,99 $/mo vs 12–17 $ | « Plus, pour moins. » |

## CTAs
- **Primaire :** *Try free — no card, no key* / FR : *Essaie gratuitement — sans carte, sans clé*
- **Secondaire :** *See how it compares* (→ `/compare`) / FR : *Vois le comparatif*
- **Developer :** *Dictate your next spec* / **Action :** *Let JARVIS do it*
- **Launch (après Go/No-Go) :** *Get the Founder's Edition — lifetime, first 200* ⚠️ *(SKU à valider avant publication)*

## Objection-handling copy
| Objection | Réponse (à shipper) |
|---|---|
| « Gérer des clés API ? » | « Pas besoin. Claude Code installé → Verba utilise ton abo, sans clé. Ou Ollama local. Ou l'essai gratuit — sans carte. » |
| « Mac-only ? » | « Honnêtement : oui, Verba est le meilleur natif macOS aujourd'hui. Besoin de Windows/mobile maintenant ? Wispr Flow y gagne — on le dit sur nos pages /vs. » |
| « C'est vraiment privé ? » | « Mode on-device : transcription locale ; ton audio ne quitte jamais ton Mac (sync texte-only). Off-switch + auto-prune ; clés Keychain. Les outils cloud uploadent chaque mot. » |
| « Pourquoi payer si Apple Dictation est gratuit ? » | « Apple ne fait que transcrire. Verba transforme le ramble en texte propre, structuré, prêt-à-envoyer — modes, intent, ton par app. » |
| « Un agent vocal avec accès à mon Gmail/Slack ? » | « Paranoïaque par design : auto-run read-only seulement ; **chaque écriture montrée, exécutée sur ta confirmation** ; le plan est généré sur ton Mac par ton IA ; déconnecte une app quand tu veux. » |
