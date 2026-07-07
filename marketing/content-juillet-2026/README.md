# Verba, Contenu marketing · Juillet 2026

> Pack d'exécution prêt-à-publier pour **juillet 2026**, construit **sur** la stratégie déjà produite (`../*.md` + `../Verba-Marketing-Strategy.pdf`), pas réinventé. Tout est ancré sur le **runway de lancement Product Hunt du mardi 28 juillet 2026**.
> Méta/notes en **français** · tout le contenu à publier est en **anglais** (cible dev/Mac anglophone), réutilisé **verbatim** des docs de stratégie.

## Par où commencer
**→ [`00-calendrier-editorial-juillet-2026.md`](00-calendrier-editorial-juillet-2026.md)** est la **colonne vertébrale** : le plan jour-par-jour (1-31 juil) qui renvoie, pour chaque pièce, au fichier de copy détaillé ci-dessous.

## Les fichiers
| Réf | Fichier | Contenu |
|---|---|---|
| 00 | `00-calendrier-editorial-juillet-2026.md` | Calendrier jour-par-jour + vue hebdo (runway T-4→T+8) + runbook jour-J |
| 01 | `01-social-x-build-in-public.md` | X : ~30 posts datés (threads, build-in-public, hooks, swipe bank, 14 angles) |
| 02 | `02-social-communautes-reddit-hn-lobsters.md` | Reddit (r/macapps, r/ClaudeAI), Show HN, Lobsters, Discords + étiquette |
| 03 | `03-social-linkedin.md` | LinkedIn, segments Expand (privacy / opérateurs voice-first), après le beachhead |
| 04 | `04-sequences-email.md` | Séquences cold-email A-E + teaser + launch email + onboarding/lifecycle |
| 05 | `05-creatifs-pub.md` | Pub payante (4 angles × Meta/Reddit/X/Google RSA/retargeting), **copy + briefs visuels** |
| 06 | `06-launch-kit-28-juillet.md` | Kit de lancement complet (PH, Show HN, Reddit, X thread) + runbook H-par-H + gates |
| 07 | `07-partenariats-outreach.md` | Outreach : créateurs/affiliation (Dub 30 %), newsletters, Raycast, earned-media indie-Mac |

## Positionnement (l'ancre de tout le pack)
- **Narratif :** *"The Mac dictation app that became a voice agent."*
- **3 piliers :** (1) Privé par défaut (on-device, même la planification) · (2) Bring-your-own-AI (réutilise l'abo Claude Code, sans clé) · (3) Voice → action (JARVIS agit après confirmation, sur 1 000+ apps).
- **Beachhead :** développeurs Mac Claude Code-native (semaines 1-4), puis élargissement (privacy → opérateurs → multilingues → note-takers).
- **Prix :** $9.99/mo · $84/yr · essai 33 dictations sans carte.

## ⚠️ Garde-fous avant publication (non négociables, L2 honnêteté)
1. **Tier "Founder's Edition / Lifetime $149", N'EXISTE PAS ENCORE dans Stripe** (seuls monthly + annual sont live). C'est le **levier de lancement prévu**, à **construire et tester en T-4** (bloqueur #1 de la checklist). Ne jamais publier la ligne `$149` avant le **feu vert Go/No-Go (ven 24 juil)** confirmant le SKU live + testé + entitlement + `?ref`. Les templates qui la contiennent portent une note `[PRÉREQUIS]` à retirer/valider avant envoi.
2. **Aucune feature inventée**, tout claim trace au produit live. iOS = scaffolded → jamais mentionné.
3. **Claim privacy exact :** *"your audio never leaves your Mac, local history with an off switch"* (jamais "nothing written to disk").
4. **Étape de confirmation** toujours visible dans les démos JARVIS (c'est l'argument de confiance).
5. **Une seule histoire de free-tier :** 33 dictations (le holdout "10 000 mots" de `api/try/route.ts` est corrigé côté site dans cette même mission).

## Provenance
Généré par un Dynamic Workflow OmegaOS (8 agents génération → 8 agents de vérif adversariale, R-VERIFY) à partir du SSOT stratégie. Vérif : alignement positionnement, garde-fou Lifetime, zéro feature inventée, dates juillet exactes (contrôlées via `date`), complétude, **8/8 passés**.

---
**Resume :** dossier juillet complet (8 livrables + ce README, ~42k mots), prêt à exécuter sur le runway du lancement PH 28 juillet, garde-fous honnêteté en tête.
