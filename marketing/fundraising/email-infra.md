# Verba — Infrastructure email (état réel & prérequis avant envoi)

> Document d'infrastructure. **Aucun email n'a été envoyé.** Les 100 emails sont des **drafts** dans `emails/`.
> État vérifié le **2026-06-28** (runtime, `dig`). À relire avant tout GO opérateur.

## 1. ESP configuré

- **Resend** est le fournisseur d'envoi disponible : clé `RESEND_API_KEY` présente dans `~/.omega/secrets/integrations.env` (hors repo, jamais committée).
- Aucun autre ESP transactionnel (SendGrid/Postmark/Mailgun) n'est configuré pour ce projet.

## 2. État d'authentification du domaine — **BLOQUANT** (vérifié 2026-06-28)

`dig` sur `verba.run` au 2026-06-28 :

| Enregistrement | État réel | Conséquence |
|---|---|---|
| A | `216.198.79.1` (le domaine résout) | OK (site web) |
| **SPF** (TXT) | **ABSENT** (zéro TXT à la racine) | ❌ envoi non authentifié |
| **DKIM** (`resend._domainkey`) | **ABSENT** | ❌ pas de signature |
| **DMARC** (`_dmarc.verba.run`) | **ABSENT** | ❌ pas de politique |
| MX | **ABSENT** | pas de réception mail |

**Conclusion : `verba.run` n'est aujourd'hui PAS authentifié pour l'email.** Envoyer du cold-email d'un domaine sans SPF/DKIM/DMARC = spam quasi garanti + dégradation de la réputation du domaine racine (celui du produit). **C'est un prérequis dur, non négociable, avant le moindre envoi.**

## 3. Prérequis à exécuter avant l'envoi (par l'opérateur)

1. **Domaine d'envoi dédié.** Ne PAS envoyer le cold-email depuis `verba.run` (le domaine produit). Utiliser un **sous-domaine ou domaine séparé** dédié à l'outbound — ex. `mail.verba.run`, `get.verba.run`, ou un domaine cousin (`getverba.com`) — pour isoler la réputation. Le domaine racine reste propre.
2. **Ajouter le domaine d'envoi dans Resend** → Resend fournit les enregistrements à publier :
   - **SPF** : TXT `v=spf1 include:_spf.resend.com ~all` (ou l'include exact fourni par Resend).
   - **DKIM** : le CNAME/TXT `resend._domainkey` fourni par Resend.
   - **DMARC** : TXT `_dmarc` → démarrer en `p=none` (monitoring), puis passer à `p=quarantine` une fois SPF+DKIM alignés et stables.
   - **MX / Return-Path** : l'enregistrement de bounce fourni par Resend.
3. **Vérifier le statut « Verified » (vert) dans le dashboard Resend** avant tout envoi. Tant que ce n'est pas vert : NO-GO.
4. **Warm-up du domaine.** Domaine neuf = réputation à construire : démarrer en très petit volume et monter progressivement. Les **lots de 10-15/jour** du plan d'envoi sont compatibles avec un warm-up.

## 4. Hygiène & conformité (cold-email investisseurs, faible volume)

- **Réponse réelle** : `Reply-To` = boîte réellement relevée par le fondateur (les réponses investisseurs sont le but).
- **Contenu** : texte épuré, personnalisé (déjà le cas), pas de raccourcisseurs de liens, lien direct `verba.run`. Une ligne d'opt-out claire en pied.
- **Adresses** : 75/100 contacts sont en `à vérifier` (email non public). **Ne jamais envoyer à une adresse devinée** — sourcer l'adresse réelle (intro chaude, formulaire public, ou pattern vérifié) d'abord. Voir `sending-plan.md`.
- **GDPR / B2B** : destinataires pro, base « intérêt légitime », message pertinent + opt-out → conforme pour de l'outbound B2B ciblé et à faible volume. Tenir un registre des opt-outs.
- **Volume** : ~100 emails étalés en lots de 10-15/jour = profil faible-volume, peu risqué **une fois le domaine authentifié**.

## 5. Statut

**Tout est en draft. Rien n'est envoyé. L'envoi reste `pending` (cf. `done.json`) en attente du GO/NO-GO opérateur via Atlas, ET de l'authentification du domaine d'envoi (§2-3).**
