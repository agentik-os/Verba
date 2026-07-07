---
project: Verba
layer: context
produced_by: ads-audience
status: filled
reconciles_with: ../../.agents/product-marketing.md §Personas (SSOT), détaille les 5 archétypes B2C
---
# Audience Personas, Verba

> B2C / prosumer self-serve : archétypes d'audience, pas de rôles d'achat B2B. L'utilisateur **est** l'acheteur (checkout 1 clic).
> Dérivé du SSOT `.agents/product-marketing.md` §Personas + §Switching Dynamics. Ciblage plateforme indicatif (B2C self-serve, pas de procurement).

## P1, Le vibe-coder Mac (BEACHHEAD)
- **Démo/psycho :** dev Mac 25-40 ans, Apple Silicon, vibe-code, a déjà une IA de confiance, vit dans le terminal et les outils IA de code.
- **Pains :** taper des specs/prompts longs est lent ; la dictée qui envoie l'audio à des serveurs expose le contexte code ; aucun outil ne propose une IA vraiment privée.
- **Triggers :** « je pense plus vite que je tape » ; ras-le-bol de payer une marge sur l'IA ; veut rester dans le flow.
- **Objections :** « gérer des clés API » → **pas besoin, ton IA privée existante suffit, sans clé** ; « encore un outil indie ? » → essai sans carte.
- **Ciblage :** **X** (build-in-public, #vibecoding), **Reddit** r/LocalLLaMA r/programming, **HN/Lobsters**, Discords d'outils de coding IA, **Google** « dictate to your coding agent », GEO.

## P2, Le pro privacy-first
- **Démo/psycho :** avocat, médecin, fondateur, journaliste ; haute sensibilité confidentialité/conformité ; Mac pro.
- **Pains :** les outils qui envoient l'audio à leurs serveurs uploadent chaque mot ; Superwhisper écrit l'audio sur le disque ; risque inacceptable.
- **Triggers :** « je ne veux pas ma voix sur le serveur de quelqu'un » ; audit/compliance.
- **Objections :** « c'est vraiment privé ? » → **on-device, audio jamais uploadé (sync texte-only), off-switch + auto-prune, clés Keychain.**
- **Ciblage :** **Google** « private/offline dictation Mac », **LinkedIn** (juristes/santé/fondateurs), Reddit r/privacy, newsletters niche.

## P3, Le knowledge worker multilingue
- **Démo/psycho :** opérateur EU/LatAm, support, comms ; doit sonner natif dans une autre langue, vite.
- **Pains :** changer d'onglet pour traduire ; dictée multilingue maladroite.
- **Triggers :** sonner pro en anglais en parlant sa langue.
- **Objections :** « la traduction est-elle fluide ? » → **Translate mode** (parle ta langue, envoie la leur) + détection auto, 15 cibles.
- **Ciblage :** **LinkedIn** (comms/support EU/LatAm), **Instagram/TikTok** (démos before/after langue), Google multilingue.

## P4, Le penseur long-format
- **Démo/psycho :** écrivain, PM, chercheur, note-taker ; capture et structure de longues pensées.
- **Pains :** les mémos vocaux d'une heure sont de la bouillie inutilisable ; les bots de réunion sont overkill.
- **Triggers :** transformer 40 min de ramble en notes structurées.
- **Objections :** « ça gère le long ? » → **Notes** : parle jusqu'à 1 h, doc structuré (9 formats, classement #hashtag, synced).
- **Ciblage :** **LinkedIn**, **X** (writing/PM), Reddit r/productivity r/ObsidianMD, YouTube (démos workflow).

## P5, L'opérateur voice-first (ouvert par JARVIS)
- **Démo/psycho :** fondateur/PM/exec sans EA, vit dans Gmail/Slack/Linear/Calendar ; veut moins de context-switching.
- **Pains :** chaque intention parlée = ouvrir une app, cliquer ; les « assistants » existants ne touchent pas ses vrais outils.
- **Triggers :** « dis-le une fois et c'est fait ».
- **Objections :** « un agent vocal avec accès à mon Gmail/Slack ? » → **paranoïaque par design : auto-run read-only seulement, chaque écriture montrée et exécutée sur confirm ; plan généré on-device par ton IA ; déconnecte une app quand tu veux.**
- **Ciblage :** **X** (démos JARVIS virales), **Product Hunt**, **LinkedIn** (founders/PM), Reddit r/macapps, Google « Jarvis for Mac / voice agent ».

## Negative audiences (anti-personas, ne pas cibler)
- Utilisateurs **Windows/Android-primary** (Verba est Mac-only ; iOS scaffolded non shippé).
- **Entreprises** exigeant admin centralisé / SSO / BAA *aujourd'hui*.
- Gens qui **ne dictent jamais** et adorent leur clavier.
- Users qui veulent **zéro setup** et refusent d'apporter une IA / de faire confiance à un produit indie.
