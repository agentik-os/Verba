# De 0 a 1 000 clients payants en 90 jours

> La strategie complete, le plan jour par jour (humain + automatise), et le playbook copie sur Cursor, Lovable, Replit et Higgsfield. Budget de depart proche de zero, croissance product-led.
> Projet Verba (verba.run) . Horizon 13 semaines, J1 = lun 7 juil 2026 . North star: 100 vers 500 vers 1 000 payants . Version 3 juil 2026.

## 1. L'essentiel

Verba est un vrai produit deja live dans une categorie validee a 2 Md$ (Wispr Flow). Le probleme n'est pas le marche, c'est la **distribution**. Les quatre fusees qu'on copie ont toutes fait la meme chose: **le produit lui-meme est la publicite**, croissance 100% organique avant toute depense pub, fondateur en public avec des chiffres bruts. On applique ce modele a un ticket de 9,99 $/mois.

**La cible, une echelle:**

| Palier | Clients payants | MRR (~7,6 &euro;/abo) | Telechargements @7% |
|---|---|---|---|
| Palier 1 | 100 | ~760 &euro;/mois | ~1 430 |
| Palier 2 | 500 | ~3 800 &euro;/mois | ~7 150 |
| Palier 3 | 1 000 | ~7 600 &euro;/mois | ~14 300 |
| Cap objectif | 2 000 | ~15 200 &euro;/mois | ~28 600 |

Cout d'inference: 0 (l'utilisateur apporte son IA, marge quasi pure). 1 000 payants = moins de 0,05% de la categorie.

**La strategie en une phrase:** gagner le developpeur Mac Claude Code-native en etant la seule appli de dictee qui **agit** (JARVIS: dicte, confirme, fait), transformer chaque demo "I said it, it did it" en **boucle de partage auto-repliquante**, batir en public avec des chiffres bruts, et ne payer de la pub qu'apres que la conversion soit prouvee.

**Les 5 non-negociables:**

1. **Le produit est la pub.** On construit la boucle "clip de partage" (endcard "Made with Verba"). Sans elle, on rame; avec elle, chaque client en ramene 2 a 3.
2. **Zero pub payante avant le palier 100.** Cursor a fait 200 M$ ARR sans un centime d'ads.
3. **Le fondateur poste tous les jours.** Chiffres bruts (MRR, installs, clip du jour) sur X, plus on amplifie chaque clip d'utilisateur.
4. **On gagne les moines d'abord.** Les gros utilisateurs de Claude Code, a fond, avant d'elargir.
5. **Des moments de lancement.** Product Hunt + Show HN le meme jour (28 juil), puis un second drop FOMO au palier 500.

## 2. Ce qu'on a deja (l'inventaire honnete)

**Deja construit et valide:**

- Produit live a verba.run: dictee on-device (Whisper/Parakeet), 6 modes, JARVIS (voix vers action, 1 000+ apps), BYO-Claude sans cle, 14 langues.
- Positionnement SSOT ecrit (product-marketing.md): 3 piliers, 5 personas, categorie "voix qui agit".
- Identite visuelle validee par l'operateur: blueprint deep-tech near-black + un accent rouge, moteur video Seedance 2.0 (UGC vox-pop).
- Moteur de contenu automatise (verba-daily.ts): image (Higgsfield nano_banana_2) + video (VO ElevenLabs + captions) 2/jour, publie via omega-zernio (15 comptes dont @verba_run).
- Calendrier 90 jours deja redige (94 posts), garde-fou R-NODASH code.
- Boucles de croissance codees: referral "Free Month", leaderboard, gamification. Codees mais pas encore visibles.
- Essai a valeur forcee: 33 dictees gratuites puis paywall.

**Ce qui manque (a construire en priorite):**

1. **La boucle "clip de partage" (#1).** Le bouton "partage ta demo voix vers action" avec endcard "Made with Verba" + lien. Le build le plus rentable des 90 jours.
2. **Le tier Founder / Lifetime** dans Stripe: n'existe pas encore. A construire et tester avant le lancement, c'est le levier FOMO.
3. **Instrumentation du funnel** bout-en-bout: telechargement, activation, 1re action, paywall, essai, payant.
4. **La preuve early:** zero testimonial public. Fabriquer 10 a 20 quotes honnetes.
5. **2 correctifs copy:** api/try dit encore "10 000 mots"; claim privacy a garder exact.

> Regle operateur (L0): le tag AUTO veut dire preparer, pas publier. Rien ne part sans GO explicite de l'operateur.

## 3. Comment Cursor, Lovable, Replit et Higgsfield ont explose

| Entreprise | Vitesse | Levier n.1 | Pub vs organique | La boucle |
|---|---|---|---|---|
| Cursor | ~1M vers 100M$ ARR en ~12 mois; ~360k payants, ~36% conversion | Moment "wow" sous 5 min + clips devs viraux | 100% organique, 0$ ads jusqu'a 200M$+ ARR | Output visible partage, le pair essaie, adoption bottom-up |
| Lovable | 0 vers 100M$ ARR en ~8 mois (record); retention J30 85% | Fondateur en public (ARR brut) + badge "Built with Lovable" | Quasi 100% organique, moins de 10% de l'an 1 en paid | App publiee porte le badge + remix, ~25k signups/mois |
| Replit | Agent (sept 2024): 10M vers 253M$ ARR en ~12 mois; 35M+ users | Boucle "made with Replit" (9M+ Repls publics) + vibe-coding | Massivement organique, pas d'equipe growth | App publique partageable, preuve, signup, fork |
| Higgsfield | 0 vers ~300M$ ARR en ~11 mois; 15M+ users, 4,5M videos/jour | Seeding createurs (10 000+) + trend-jacking (10 presets/jour) | Distribution-led, 1er commercial a 50M$ ARR | Trend, preset 1-clic, createurs inondent X/TikTok, signup |

**Le patron commun, 10 lois:**

1. **L'output est la pub.** Chaque artefact partage est une annonce gratuite qui se re-partage. Verba: le clip "I said it, it did it".
2. **Zero ads avant que ca convertisse.** La pub vient apres, pour amplifier une machine qui marche.
3. **Moment wow ultra-rapide.** Verba: 1re dictee sous 60s (chemin zero-cle Claude Code) + 1re action confirmee.
4. **Fondateur en public, chiffres bruts.** Le posting est le haut du funnel.
5. **Amplifier les victoires des users.** Reposter chaque clip d'utilisateur plutot que controler le narratif.
6. **Gagner les moines d'abord.** Une base etroite qui evangelise credibilise tout le reste.
7. **Gratuit gate sur l'usage, pas les features.** Verba: les 33 dictees, deja en place.
8. **Des moments de lancement.** Product Hunt ET Hacker News le meme jour.
9. **Fabriquer de l'UGC.** Des defis qui poussent les gens a produire la preuve pour toi.
10. **Velocite de sortie = raisons de poster.** Une cadence quotidienne bat un lancement poli unique.

> L'insight cle pour Verba: on a deja le moteur de contenu (loi 9-10), l'essai force (loi 7), la niche (loi 6) et de quoi lancer (loi 8). Ce qui manque et debloque tout, c'est la loi n.1, la boucle de partage. Higgsfield a paye 10 000 createurs; nous, sans budget, on remplace le cash par un defi "fais ton clip I-said-it-did-it" avec licences lifetime offertes a 20-50 semeurs.

## 4. La strategie Verba mise a jour, 4 moteurs

- **Moteur A, Fondateur en public.** Gareth poste tous les jours: MRR brut, installs, "command of the day" (clip). On amplifie chaque clip d'utilisateur. Cout 0.
- **Moteur B, La boucle de partage (le coeur).** Le clip "I said it, it did it" en un format reconnaissable et copiable, un par jour, chacun trend-jacke une douleur du moment. Le bouton "partage" in-app avec endcard "Made with Verba" ferme la boucle.
- **Moteur C, Communaute et lancements.** Show HN, r/ClaudeAI, r/macapps, Lobsters, Product Hunt. Reply-jack les threads viraux avec un clip brut dans l'heure.
- **Moteur D, Boucles produit deja codees.** Rendre visibles le referral et le leaderboard partageable, plus le SEO/GEO comparatif qui compose seul.

**Philosophie budget:**

- Palier 0 vers 100: **0 &euro;**, 100% organique.
- Palier 100 vers 500: **10-15 &euro;/j** de retargeting /compare, seulement si essai vers payant est prouve.
- Palier 500 vers 1000: **micro** (sponsoring 1-2 newsletters, affiliate % createurs), toujours secondaire a l'organique.

Regle d'or: la pub amplifie une conversion prouvee, elle ne la fabrique jamais.

## 5. L'echelle client 0 vers 100 vers 500 vers 1 000

**Palier 1 (mois 1), 0 vers 100 payants.** Objectif: 100 vrais fans gagnes a la main. Levier: fondateur en public + hand-seeding + lancement PH/Show HN. Gate de sortie: essai vers payant >= 6%, 10+ quotes, boucle clip fonctionne. Budget: 0 &euro;.

**Palier 2 (mois 2), 100 vers 500 payants.** Objectif: la boucle porte la croissance. Levier: boucle de partage seedee + concours hebdo UGC + SEO + demos createurs. Gate: coefficient referral > 0,3, un format de clip a > 20k vues repro, retargeting ROI-positif. Budget: 10-15 &euro;/j optionnel.

**Palier 3 (mois 3), 500 vers 1 000 payants.** Objectif: elargir au-dela des devs + moments FOMO. Levier: segments Expand (privacy pros, operateurs voice-first) + affiliate + second drop. Gate: 1 000 payants, moteur qui compose sans le fondateur en input quotidien. Budget: micro.

## 6. Le plan 90 jours, jour par jour

Chaque jour a une action AUTO (le moteur prepare, l'operateur valide) et une action HUMAIN (le fondateur, 30 min a 2h).

**Rituel quotidien fixe, ~25 min, tous les jours (non repete ci-dessous):**

1. Valider (GO) le post AUTO du jour avant publication (garde-fou L0).
2. Repondre a tous les replies et DM de la veille sur X.
3. Engager: commenter avec valeur 3-5 posts de devs Claude Code / comptes Mac-productivite.
4. Reply-jack: 1 thread viral pertinent avec un clip Verba brut.
5. Amplifier: reposter ou citer tout clip, mention ou review d'utilisateur.

### MOIS 1, Fondations et 100 premiers fans (0 vers 100 payants)

**S1 (7-13 juil), Rendre le funnel etanche + allumer le build-in-public**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 7 | Post, coder plus vite sans clavier + funnel instrumente | Corriger les 2 gaps copy (api/try vers 33 dictees, scrub privacy). JALON |
| Mar 8 | Post, dicter sans crainte (prive) + pages /vs rafraichies | Ecrire + epingler le narratif fondateur. Poster le 1er chiffre brut (installs). |
| Mer 9 | Post, payer l'IA une seule fois prepare | ENREGISTRER la demo canonique 60s + 4 cutdowns 15s. Actif parent. JALON |
| Jeu 10 | Post, dis-le une fois c'est fait + clip Linear monte | Lancer le brief dev de la boucle "clip de partage". Definir les KPIs. |
| Ven 11 | Post, une voix pour tout le workflow prepare | Rendre visibles referral + leaderboard. Poster le clip demo 60s avec hook. |
| Sam 12 | 1 post auto + monitoring | Passage valeur-d'abord r/ClaudeAI. Reperer 30 devs a semer. |
| Dim 13 | 1 post auto + digest | Revue S1, ecrire les 3 priorites de S2. Repos. |

**S2 (14-20 juil), Construire la boucle + fabriquer la preuve early**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 14 | Post, coder plus vite sans clavier + 1er clip format reconnaissable | Blog fondation #1 "Bring your own Claude, no key". Seeding 20 testeurs alpha. |
| Mar 15 | Post, dicter sans crainte (prive) + /compare verifiee | Tester le SKU Founder dans Stripe (achat test + entitlement + ?ref). |
| Mer 16 | Post, payer l'IA une seule fois + clip | Relancer les alpha: collecter 1 quote honnete + permission. Viser 10 quotes. |
| Jeu 17 | Post, dis-le une fois c'est fait + cutdown Gmail | Recette de la boucle clip: tester le partage in-app bout-en-bout. JALON |
| Ven 18 | Post, une voix pour tout le workflow + digest hebdo | Build-in-public hebdo (installs, quotes). Blog fondation #2 "Verba vs Wispr honnete". |
| Sam 19 | 1 post auto + monitoring | Passage Lobsters/Discord. Lister 20 createurs a semer. |
| Dim 20 | 1 post auto + digest | Revue S2, preparer le kit de lancement. Repos. |

**S3 (21-27 juil), Pre-launch: semer les createurs + preparer les moments**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 21 | Post, coder plus vite sans clavier + clip trend-jack code | Seed 20 createurs: Founder license + defi clip, pas d'ask payant. JALON |
| Mar 22 | Post, dicter sans crainte (prive) + pages use-case SEO en ligne | Preparer les assets Product Hunt (galerie, tagline, 1er commentaire, hunter). Teaser waitlist. |
| Mer 23 | Post, payer l'IA une seule fois + clip | Rediger le Show HN. Relancer les createurs. |
| Jeu 24 | Post, dis-le une fois c'est fait + cutdown Slack | Go / No-Go lancement. Valider le tier Founder a publier. JALON |
| Ven 25 | Post, une voix pour tout le workflow + digest hebdo | Build-in-public. Programmer les posts de lancement. Brief final createurs. |
| Sam 26 | 1 post auto teaser | Derniere passe communaute pre-launch (presence, pas de pitch). |
| Dim 27 | 1 post auto teaser + assets en file | Repetition du runbook lancement heure-par-heure. Repos. |

**S4 (28 juil-3 aout), SEMAINE DE LANCEMENT, franchir 100 payants**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Mar 28 | Assets lancement pousses (apres GO) + boucle clip active | LANCEMENT. Product Hunt + Show HN + X thread + LinkedIn. Tier Founder publie. 12h en commentaires. JALON |
| Mer 29 | Repost meilleurs moments PH/HN + clips createurs | r/macapps "Honest Verba vs Wispr" + r/ClaudeAI PSA. 2h chacun. JALON |
| Jeu 30 | Post recap + digest chiffres | Repondre a toutes les reviews. Reposter chaque clip user. Presse Mac indie. |
| Ven 31 | Post, dis-le une fois c'est fait + build-in-public "launch numbers" | Poster les chiffres bruts du lancement. Relancer createurs pour leur clip. |
| Sam 1 ao. | 1 post auto + monitoring | Passage Lobsters "how the launch went". Collecter testimonials. |
| Dim 2 | 1 post auto + digest hebdo | Revue lancement: 100 franchi? conversion? Gate palier 1? Ecrire S5. |
| Lun 3 | Post, coder plus vite sans clavier + boucle en regime | Post "1 semaine apres". Prioriser le format de clip gagnant. |

> Gate palier 1: passer a S5 seulement si essai vers payant >= 6%, 10+ quotes publiques, un clip user a genere un install traçable. Sinon iterer l'activation avant d'ajouter du volume.

### MOIS 2, La boucle porte la croissance (100 vers 500 payants)

**S5 (4-10 aout), Transformer la boucle en concours UGC hebdo**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 4 | Post, dicter sans crainte (prive) + clip format gagnant | Lancer le concours hebdo "best voice workflow wins lifetime + repost". JALON |
| Mar 5 | Post, payer l'IA une seule fois + 3 pages use-case SEO | Test micro-ads 10 &euro;/j retargeting /compare (si gate franchi). Mesurer CPA. |
| Mer 6 | Post, coder plus vite sans clavier + clip concours | Reposter les meilleures soumissions. Relancer createurs. |
| Jeu 7 | Post, dis-le une fois c'est fait + cutdown Calendar | Contacter 10 newsletters dev/Mac. Passage r/ClaudeAI. |
| Ven 8 | Post, une voix pour tout le workflow + build-in-public (MRR) | Milestone MRR. Annoncer gagnant, reposter son clip. |
| Sam 9 | 1 post auto + monitoring | Collecte testimonials. Analyser quel format performe. |
| Dim 10 | 1 post auto + digest | Revue S5: CPA? coefficient referral? Ecrire S6. |

**S6 (11-17 aout), Demos createurs live + amplifier ce qui marche**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 11 | Post, coder plus vite sans clavier + concours semaine 2 | Coordonner 3-5 demos createurs. Reposter chacune. JALON |
| Mar 12 | Post, dicter sans crainte (prive) + retargeting a 15 &euro;/j si CPA OK | Analyser: quels canaux amenent les payants? Doubler sur le gagnant. |
| Mer 13 | Post, payer l'IA une seule fois + clip createur | Reply-jack 2 threads "AI agent Mac". Relancer newsletters. |
| Jeu 14 | Post, dis-le une fois c'est fait + cutdown thematique | Blog use-case "dictation for Cursor/Claude Code". Passage Lobsters. |
| Ven 15 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR. Interviewer 2 clients pour mini case-study. |
| Sam 16 | 1 post auto + monitoring | Collecte + repost. Reperer un second format de clip. |
| Dim 17 | 1 post auto + digest | Revue S6: trajectoire vers 500? Ecrire S7. |

**S7 (18-24 aout), SEO qui compose + newsletters**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 18 | Post, coder plus vite sans clavier + concours S3 + nouvelles /vs | Placer 1-2 mentions newsletter. Reposter le concours. |
| Mar 19 | Post, dicter sans crainte (prive) + retargeting | Publier le case-study client #1. Relancer createurs restants. |
| Mer 20 | Post, payer l'IA une seule fois + clip | Passage r/productivity ou r/MacOS. Tester un nouveau hook. |
| Jeu 21 | Post, dis-le une fois c'est fait + cutdown | Reply-jack + amplifier. Optimiser onboarding selon les data. |
| Ven 22 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR. Thread "selling a $9.99 Mac app". |
| Sam 23 | 1 post auto + monitoring | Collecte + repost. Preparer le second format de clip. |
| Dim 24 | 1 post auto + digest | Revue S7. Ecrire S8 (push final vers 500). |

**S8 (25-31 aout), Push final vers 500**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 25 | Post, coder plus vite sans clavier + concours S4 | Bilan mi-parcours: distance a 500? Concentrer sur le canal #1. |
| Mar 26 | Post, dicter sans crainte (prive) + retargeting | Relancer tous les createurs pour un push coordonne. |
| Mer 27 | Post, payer l'IA une seule fois + clip | Reply-jack agressif. HN "Show HN update: 500 users". |
| Jeu 28 | Post, dis-le une fois c'est fait + cutdown | Case-study #2. Tester une offre annuelle nudge in-app. |
| Ven 29 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR "2 mois, X clients". Gagnant concours du mois. |
| Sam 30 | 1 post auto + monitoring | Collecte + repost. Reperer les segments Expand. |
| Dim 31 | 1 post auto + digest mensuel | Revue mois 2: 500 franchi? Gate palier 2? Plan mois 3. |

> Gate palier 2: passer au mois 3 seulement si coefficient referral > 0,3, un format de clip a > 20k vues reproductible, retargeting ROI-positif.

### MOIS 3, Elargir et composer (500 vers 1 000 payants)

**S9 (1-7 sept), Activer le segment privacy pros**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 1 | Post, dicter sans crainte (prive) (privacy pros) + SEO "private dictation for lawyers" | Lancer le message segment 1. Clip "your audio never leaves your Mac". JALON |
| Mar 2 | Post, payer l'IA une seule fois + retargeting multi-segment | Contacter 5 newsletters privacy/legal/medical. |
| Mer 3 | Post, coder plus vite sans clavier + clip | Mettre en place l'affiliate % createurs (Dub). Onboarder 3 affilies. |
| Jeu 4 | Post, dis-le une fois c'est fait + cutdown | Passage LinkedIn + communaute privacy. Reply-jack threads privacy. |
| Ven 5 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR. Case-study client pro. |
| Sam 6 | 1 post auto + monitoring | Collecte + repost. Preparer le second drop FOMO. |
| Dim 7 | 1 post auto + digest | Revue S9. Ecrire S10. |

**S10 (8-14 sept), Segment voice-first operators + affiliate en regime**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 8 | Post, dis-le une fois c'est fait (operateurs) + SEO "Jarvis for Mac" | Lancer le message segment 2. Clip "say it once, it does it all". JALON |
| Mar 9 | Post, coder plus vite sans clavier + affiliate links actifs | Recruter 5 affilies de plus. Suivre les conversions. |
| Mer 10 | Post, payer l'IA une seule fois + clip | Passage r/productivity + newsletters. Reply-jack "AI assistant". |
| Jeu 11 | Post, dicter sans crainte (prive) + cutdown | Thread "3 mois de build-in-public: les chiffres". |
| Ven 12 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR. Teaser le drop FOMO de la semaine prochaine. |
| Sam 13 | 1 post auto + monitoring | Preparer les assets du drop (Founder, sieges limites). |
| Dim 14 | 1 post auto + digest | Revue S10. Finaliser le runbook du drop. Repos. |

**S11 (15-21 sept), Second moment: drop FOMO (Founder, sieges limites)**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 15 | Assets drop pousses (apres GO) | DROP FOMO "Founder, 100 last seats, 3 days only". Fondateur-first. JALON |
| Mar 16 | Post rappel urgence + compteur | Relancer affilies pour amplifier. Repondre en continu. |
| Mer 17 | Post "last 24h" + clips amplifies | Dernier push, r/macapps update honnete. Cloture ce soir. |
| Jeu 18 | Post recap drop + digest | Bilan drop: sieges vendus, cash genere. Reposter. |
| Ven 19 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR post-drop. Chiffres bruts du drop. |
| Sam 20 | 1 post auto + monitoring | Collecte + repost. Contacter 2 podcasts dev/indie. |
| Dim 21 | 1 post auto + digest | Revue S11: distance a 1 000? Ecrire S12. |

**S12 (22-28 sept), Sponsoring newsletter cible + podcasts**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 22 | Post, coder plus vite sans clavier + placement newsletter #1 (paye, micro) | Activer 1-2 sponsorings newsletter dev. Mesurer CPA vs organique. JALON |
| Mar 23 | Post, payer l'IA une seule fois + retargeting | Enregistrer/publier un podcast dev-indie. |
| Mer 24 | Post, dicter sans crainte (prive) + clip | Passage communaute + amplification. Analyser le ROI du sponsoring. |
| Jeu 25 | Post, dis-le une fois c'est fait + cutdown | Case-study #3 (segment Expand). Relancer affilies. |
| Ven 26 | Post, une voix pour tout le workflow + build-in-public | Milestone MRR. Thread "presque 1 000 clients". |
| Sam 27 | 1 post auto + monitoring | Collecte + repost. Preparer la lifecycle email. |
| Dim 28 | 1 post auto + digest | Revue S12. Ecrire S13 + le plan 90-180j. |

**S13 (29 sept-5 oct), Consolider, retenir, franchir 1 000**

| Jour | AUTO | HUMAIN |
|---|---|---|
| Lun 29 | Post, coder plus vite sans clavier + lifecycle email active | Deployer la sequence email retention (activation, 1re action, winback). JALON |
| Mar 30 | Post, dicter sans crainte (prive) + retargeting | Push final vers 1 000: coordonner createurs + concours + clips sur 48h. |
| Mer 1 oct | Post, payer l'IA une seule fois + clip | Reply-jack + amplification max. HN "Show HN: 1000 paying users". |
| Jeu 2 | Post, dis-le une fois c'est fait + cutdown | Interviewer 3 clients. Verifier la sante churn. |
| Ven 3 | Post, une voix pour tout le workflow + build-in-public "90 days" | Poster la retro 90 jours avec tous les chiffres bruts. JALON |
| Sam 4 | 1 post auto + monitoring | Collecte finale. Documenter ce qui a marche/echoue. |
| Dim 5 | Digest 90 jours complet | Revue finale: 1 000 franchi? Ecrire le plan 90-180j vers 2 000-5 000. |

> Gate palier 3 (sortie du plan): 1 000 payants (~7 600 &euro;/mois). Le vrai signal: la croissance ne depend plus de la main du fondateur chaque jour. On enchaine sur le cycle 90-180j (2 000 puis 5 000), avec l'iOS pour tuer l'objection Mac-only.

## 7. Le moteur automatise vs l'humain

**Automatise (prepare, puis publie apres GO):** verba-daily.ts (image + video 2/jour), publication via omega-zernio (15 comptes, Reddit reste manuel), pages SEO/GEO (/vs, /compare, use-case, JSON-LD, llms.txt), boucles produit (referral, leaderboard, boucle clip), retargeting ads (palier 2+), lifecycle email (S13), digests quotidiens.

**Humain (jamais delegue):** le GO de publication (L0), le build-in-public fondateur, l'engagement communaute (replies, DM, reply-jack, amplification), les posts Reddit/HN (etiquette stricte), le seeding createurs et alpha, l'enregistrement des demos canoniques, les decisions de gate entre paliers.

> Garde-fous: English only pour la copy publiable, zero pricing dans le contenu organique (sauf le drop Founder valide), jamais d'ecran/UI visible dans les videos UGC, etape Confirm visible dans toute demo JARVIS, noms publics JARVIS et connected apps (jamais "Composio"), claim privacy exact, zero em-dash.

## 8. KPIs, rituels et budget

**North star:** Weekly Active Dictators (WAD). **Funnel:** download vers activation %, activation vers paywall %, paywall vers essai %, essai vers payant %, MRR, payants, churn, mix annuel %.

**KPIs de croissance (les nouveaux):** coefficient de referral (cible > 0,3), clips partages/semaine et installs traçables par clip, % d'actifs avec >= 1 app connectee, time-to-first-confirmed-action, CPA retargeting vs LTV, installs attribues createurs/affilies.

**Rituels:** quotidien (rituel 25 min + GO), hebdo dimanche (revue funnel, gagnant concours, priorites S+1), mensuel (cohortes + canaux vs le gate du palier).

**Budget total 90 jours:**

| Poste | Palier 1 | Palier 2 | Palier 3 |
|---|---|---|---|
| Ads retargeting | 0 &euro; | ~300-450 &euro; | ~300-450 &euro; |
| Sponsoring newsletter | 0 &euro; | 0 &euro; | ~200-500 &euro; |
| Seeding createurs | Licences offertes | Licences + affiliate % | Affiliate % sur ventes |
| Cash marketing incremental | ~0 &euro; | ~300-450 &euro; | ~500-950 &euro; |

Total cash incremental sur 90 jours: sous ~1 500 &euro;, et seulement apres preuve de conversion.

## 9. Sources

**Playbooks de croissance (recherche 3 juil 2026, citee):**

- Cursor: news.aakashg.com/p/how-cursor-grows, thegtmnewsletter.substack.com, productgrowth.blog/p/how-cursor-ai-hacked-growth, research.contrary.com/company/cursor
- Lovable: lennysnewsletter.com/p/building-lovable-anton-osika, techcrunch.com, the-ai-corner.com, productgrowth.blog/p/how-lovable-dev-hacked-their-growth
- Replit: productgrowth.blog/p/how-replit-hacked-its-growth, sacra.com/research/replit-at-253m-arr, growthunhinged.com/p/replit-growth-journey
- Higgsfield: productgrowth.blog/p/higgsfield-growth-teardown, chiefaiofficer.com, sacra.com/c/higgsfield

**Contexte Verba (repo interne):** EXECUTIVE-SUMMARY.md, 00-context/product-marketing.md (SSOT), gtm-strategy.md, launch-strategy.md, 05-calendar/calendar-90d.md, 04-publishing/daily-engine/verba-daily.ts, project.config.json.

Genere le 3 juil 2026 par la machine marketing OmegaOS (R-MARKETING, R-ARTIFACT, R-PDF). Scope: Verba uniquement. Les paliers et budgets sont des hypotheses a remplacer par la data funnel reelle (L1).
