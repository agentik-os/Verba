---
project: Verba
layer: context
produced_by: ads-competitors / market-competitors
status: filled
reconciles_with: ../market-research.md §2 (dataset vérifié), website/lib/competitors.ts, website/lib/compare-matrix.ts
---
# Competitive Landscape — Verba

> Données vérifiées maintenues dans le repo : `website/lib/competitors.ts` (« facts verified mid-2026 ») + la matrice
> `/compare` rebâtie (**24 features × 10 marques**, `website/lib/compare-matrix.ts`). Synthèse recoupée web (juin 2026).

## Direct competitors
| Nom | Positionnement | Prix | Canaux | Faiblesse que Verba attaque |
|---|---|---|---|---|
| **Wispr Flow** (T1, incumbent) | Cloud, cross-platform, poli, SOC2/HIPAA teams — **valo 2 Md$** | 15 $/mo (12 $/an) | Pub massive, PH, presse | Audio quitte toujours l'appareil ; le plus cher ; pas d'offline ; **pas de BYO-AI** (tu paies leur marge à vie) |
| **Superwhisper** (T2, local) | Power-tool local Mac, Whisper+Parakeet, 4.9/5 PH | 8,49 $/mo · 84,99 $/an · **249,99 $ à vie** | Indie, PH, bouche-à-oreille | **Sauve l'audio sur le disque par défaut ; clés API en clair** |
| **MacWhisper** (T2) | Transcripteur indie (GoodSnooze), **~1 900 avis PH @ 4.8/5** | ~69 $ à vie | App Store, PH | **File-first**, pas type-anywhere ; cleanup IA secondaire |
| **VoiceInk** (T2, OSS) | Open-source GPLv3, local Whisper+Parakeet, BYOK | 25–49 $ one-time | GitHub, communautés | **Polish IA en DIY** |
| **Aqua Voice** (T3) | Cloud, modèle « Avalon », édition langage naturel forte | ~8 $/mo | Web, PH | **Cloud-only** ; free capé à 1 000 mots à vie |
| **Willow Voice** (T3) | Cloud-default (offline = Pro-only), style-matching, SOC2/HIPAA | 12–15 $/mo | Web | Offline payant ; cloud par défaut |
| **TalkTastic** (T3) | **Le plus proche des "actions"** — commandes Mac-local app-aware | Gratuit (beta) | Web | **Commandes Mac-locales seulement** : pas d'exécution cross-app (Gmail/Slack/Linear/GitHub), pas de boucle agent confirm-gated, pas de BYO-AI |

## Indirect / substitutes
- **Apple Dictation** — gratuit, intégré, on-device, **zéro cleanup IA** (l'ancre « good enough » à battre sur la qualité).
- **Otter.ai** — 16,99 $/mo, notes de réunion, pas de dictée type-anywhere.
- **Ne pas dicter du tout** (clavier + muscle memory) ; **fenêtre LLM générique** (boucle copier-coller) ; embaucher un VA.

## Positioning gaps WE exploit
1. **« local + restructuration IA + BYO-Claude »** : case vide du marché — aucun défaut mental, c'est Verba.
2. **Réutiliser l'abo Claude Code sans clé** : *personne* ne le permet (catégorie-d'un).
3. **Privé par défaut honnête** : on-device + audio jamais uploadé (vs Wispr qui upload tout, vs Superwhisper clés en clair / audio disque).
4. **Voice → action confirm-gated sur 1 000+ apps** : aucun concurrent de dictée ne *fait* (TalkTastic s'arrête au Mac local).
5. **Prix + honnêteté** : 9,99 $ + pages `/vs` qui listent où les rivaux gagnent — désarme le scepticisme.

## Swipe-worthy angles competitors miss
- *« You're paying twice for AI. Here's the math. »* — calcul de coût original (Wispr markup vs abo Claude déjà payé).
- *« Does your dictation app upload your audio? »* — table on-device vs cloud, nommer Superwhisper (disque) / Wispr (cloud).
- *« Your voice shouldn't just type. It should* do. *»* — la démo JARVIS (créer une issue Linear / envoyer un mail, après confirm).
- *« The Mac dictation app that became a voice agent »* — le narratif maître que seul Verba peut écrire.
- **Honnêteté radicale** : afficher le `/compare` 24×10 — y compris là où Wispr (multi-plateforme) gagne — crédibilise tout le reste.
