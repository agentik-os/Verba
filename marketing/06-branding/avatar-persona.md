---
project: Verba
layer: 06-branding
produced_by: marketing-machine-upgrade (spec §2.3 avatar-persona.md)
status: filled
decision: scene-led / product-led, NO recurring human avatar, NO soul trained now
source_of_truth: marketing/03-visual-identity/higgsfield/avatar-soul.md
---
# Avatar / Persona, Verba

## Décision : **scene-led, pas de porte-parole humain récurrent**

`hasRecurringAvatar: false` · `soul_id: null` · `heygen_avatar_id: null` → **générer sans `--soul-id`.**

Verba est une app **macOS native** dont l'identité est **produit- et scène-led** (`avatar-soul.md`). La marque récurrente
est le **glyphe MicMark** + la loi « Black-craft » + le **rec-dot #ff5a4d**, pas un visage. Un avatar humain entrant en
collision avec l'esthétique mate/quasi-noire/sans-personnes du DA **affaiblirait la cohérence** (DA §Photography :
*« product-led, never stock people »*). Ce n'est **pas** un manque : c'est la décision de marque.

**Pourquoi (raisonnement, repris de `avatar-soul.md`) :**
- **Catégorie & goût :** l'argument est la *précision Apple* + la *confidentialité*, une UI réelle et un Mac convainquent plus qu'un visage généré.
- **Cohérence :** MicMark + rec-dot donnent déjà une signature reconnaissable, gratuite, infiniment reproductible.
- **Honnêteté (L2) :** un « fondateur » synthétique ferait croire à une preuve sociale qu'on n'a pas encore (« pas de témoignages publics », product-marketing.md).
- **Coût/risque :** entraîner un Soul = dépendance CLI Higgsfield payante (R-VISUAL-ID) sans gain pour une marque scene-led.

---

## Le « persona » de Verba = un ENVIRONNEMENT récurrent

Puisqu'aucun visage ne se répète, ce qui se répète, et qui doit rester **verrouillé** pour la cohérence de série (spec §2.2 series discipline), c'est la **scène**. Traiter ces réglages comme le persona sheet le serait pour un humain.

- **« Sujet » récurrent :** le Mac Apple Silicon (MacBook Pro / iMac) + l'**UI Verba réelle**, la pill/overlay près de la menu-bar, le feed d'action JARVIS avec le bouton **Confirm** visible, la waveform on-device.
- **3-5 réglages récurrents** (l'équivalent des « recurring settings » du spec) :
 1. **Bureau de dev, nuit**, terminal sombre / Cursor / Linear, mains sur clavier qui *s'arrêtent* pendant qu'on parle.
 2. **Plan macro d'UI**, la pill Verba ou la carte d'action JARVIS, hairline borders, sur panel #0c0c10.
 3. **Champ type-led #050507**, grands chiffres `tabular-nums` (le cost-math BYO-AI, « 9,99 $ »), beaucoup de vide.
 4. **Boucle fermée on-device**, waveform/audio contenu dans une frontière d'appareil dessinée (« audio never leaves your Mac »).
 5. **Grille de compare honnête**, le look /compare, colonne Verba subtilement mise en avant, une ligne où un rival gagne.
- **Palette wardrobe (= palette de scène) :** tirée de `tokens.color`, matte anodized aluminium, dark glass, near-black #050507, le seul point #ff5a4d.
- **Voice/tone (lié à `.agents/product-marketing.md`) :** précis · privé · malicieux · pro-user · sans prétention. Confiant, franc, jamais vendeur.
- **Scene do/don'ts :** montrer **toujours** le Confirm dans les démos d'action · **jamais** « Composio » · jamais de personnes stock, néon, 3D plastique, dégradé pastel.

## Realism defaults (spec §2.3 · §4.2)

- Comme il n'y a **pas de Soul**, chaque shot lensé (Mac, mains, environnement) reçoit le **bloc anti-générique** de `prompt-library/kill-list.md` : candid, pas posé, pores de peau visibles si une main est cadrée, lumière ambiante inégale, léger flou de mouvement sur une main, cadrage un peu penché, `shot on Ricoh GR III / Canon AE-1`, grain Kodak Gold 200.
- **UI toujours nette et réelle** (screenshots), le grain reste sur l'environnement, jamais sur la capture d'écran.
- Lumière : **une** source douce directionnelle, low-key matte, pièce quasi-noire. Voir `tokens.photo`.

---

## Brief conditionnel, SI un porte-parole devenait nécessaire (Phase 2, NON entraîné maintenant)

*(Ne rien entraîner tant que ce brief n'est pas explicitement activé par l'opérateur, R-VISUAL-ID.)*

- **Qui :** un dev/fondateur Mac, 28-40 ans, sobre, crédible auprès du beachhead Claude Code, **jamais** « influenceur ».
- **Source de référence :** le **vrai fondateur** (Agentik/Dafnck) en priorité, **pas** un visage synthétique, pour rester honnête (L2).
- **Personnalité à irradier :** précis, privé, malicieux, pro-user, sans prétention (les 5 adjectifs de marque).
- **Si on entraînait alors :** `higgsfield-soul-id` sur ≥20 photos ≥960px, angles/expressions variés, pas de lunettes de soleil (~5 min, ~25 crédits) → remplir `soul_id` ici + dans `tokens.json.avatar` ; `heygen_avatar_id` pour les talking-heads. `prompt-library/avatar-heygen.md` détaille comment HeyGen se brancherait.
- **Quand reconsidérer :** vague de contenu créateur/UGC (Phase 2) où un visage récurrent augmenterait la confiance, pas avant.

> **Par défaut, aujourd'hui et jusqu'à activation explicite : générer SANS `--soul-id`.** L'identité = produit + MicMark + loi Black-craft.
