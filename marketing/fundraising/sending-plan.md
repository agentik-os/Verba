# Verba, Plan d'envoi (séquencé, lots de 10-15/jour), DRAFTS, RIEN ENVOYÉ

> 100 emails personnalisés prêts dans `emails/`. **Aucun n'a été envoyé.**
> L'envoi attend (1) l'authentification du domaine d'envoi (`email-infra.md`) et (2) le **GO/NO-GO opérateur via Atlas**.
> Date : 2026-06-28.

## Principe

Investisseurs ≠ blast marketing. On envoie **peu, ciblé, personnalisé**, en **lots de 10-15/jour**, en commençant par les canaux **réellement actionnables** (formulaires publics) puis les **intros chaudes**. Chaque email est déjà personnalisé sur la thèse + le portfolio de l'investisseur.

## Vagues de priorisation

**Vague 1, Canaux publics actionnables tout de suite (25 contacts `contact_status=verified`).**
Ce sont les investisseurs avec un **formulaire de candidature ou un email de pitch public**, pas besoin d'intro chaude. À traiter en premier. Exemples (voir colonne `contact_channel` dans `investors-100.csv`) :
- Accélérateurs / programmes à candidature ouverte : **Y Combinator** (apply.ycombinator.com), **AI Grant** (aigrant.org), **Entrepreneur First**, **Betaworks Camp**, **South Park Commons**, **Boost VC**, **Neo**, **Village Global Velocity**, **Conviction Embed**, **Heavybit**.
- Fonds avec pitch public : **Speedinvest** (speedinvest.com/pitch-us), **Hustle Fund** (typeform), **Precursor / Charles Hudson** (precursorvc.com/startup), **Menlo Ventures Anthology Fund**, **Liquid 2** (info@liquid2.vc), **Frst** (pierre@frst.vc), **Weekend Fund / Ryan Hoover** (team@weekend.fund), **Long Journey** (hi@longjourney.vc), **Calm Fund / Tyler Tringas** (apply.calmfund.com), **Todd & Rahul's Angel Fund**.

**Vague 2, Cibles « warm intro » à plus forte conviction (top des `à vérifier`).**
Existence + thèse vérifiées, mais **email non public** → nécessite de sourcer une **intro chaude** (LinkedIn 2ᵉ degré, réseau fondateur, AngelList) ou l'adresse réelle avant envoi. Ex. : **Sequoia** (anchor Linear), **Accel** (Raycast), **a16z** (Mem/Rewind), **Spark** (Granola), **Notable Capital / Hans Tung** (Wispr), **Naval Ravikant** (Notion), **Guillermo Rauch**, **Lenny Rachitsky**, **Dylan Field**, **Atomico / Coatue / WiL** (Raycast).

**Vague 3, Le reste de la liste**, au fil du sourcing des adresses/intros.

## Cadence

- **10-15 emails/jour**, idéalement **mar-jeu**.
- **1 relance** à J+5-7 si pas de réponse ; **2 relances max**, puis stop.
- Suivi dans un simple tracker (statut : `drafted → intro/adresse sourcée → sent → replied → meeting`).
- Étaler les 100 sur **~8-10 jours ouvrés** (cohérent avec le warm-up du domaine neuf).

## Checklist de pré-envoi (GATING, tout doit être vert)

1. ✅ **Domaine d'envoi authentifié** : SPF + DKIM + DMARC verts dans Resend (cf. `email-infra.md` §2-3). **Aujourd'hui : NON (bloquant).**
2. ✅ **Personnalisation finalisée** : remplacer `[Prénom]` (partenaire ciblé) et `[Fondateur]` (signature réelle) dans chaque draft.
3. ✅ **Adresse destinataire confirmée** : pour les 75 `à vérifier`, sourcer l'adresse réelle, **jamais d'adresse devinée**.
4. ✅ **GO/NO-GO opérateur via Atlas**.
5. ▶ Envoi par lots de 10-15/jour depuis le domaine warmé.

## Statut d'envoi

**`pending`**, voir `done.json`. Aucun email envoyé ; l'étape d'envoi est explicitement en attente du GO opérateur et de l'authentification du domaine.
