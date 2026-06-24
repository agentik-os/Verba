// Generated honest comparison matrix (features as rows, brands as columns). Sources verified
// mid-2026 from each vendor + reviews; see the competitor records for citations.
export type Cmp = "yes" | "no" | "partial" | "?" | string;
export const COMPARE = {
 "columns": [
  "verba",
  "wispr-flow",
  "superwhisper",
  "aqua-voice",
  "macwhisper",
  "willow-voice",
  "voiceink",
  "talktastic",
  "apple-dictation",
  "otter-ai"
 ],
 "names": {
  "verba": "Verba",
  "wispr-flow": "Wispr Flow",
  "superwhisper": "superwhisper",
  "aqua-voice": "Aqua Voice",
  "macwhisper": "MacWhisper",
  "willow-voice": "Willow Voice",
  "voiceink": "VoiceInk",
  "talktastic": "TalkTastic",
  "apple-dictation": "Apple Dictation",
  "otter-ai": "Otter.ai"
 },
 "prices": {
  "verba": "$9.99/mo",
  "wispr-flow": "$15/mo (monthly); $12/mo billed annually",
  "superwhisper": "$8.49 to $8.99/mo (Pro; ~$84.99/yr; $249.99 lifetime)",
  "aqua-voice": "$8/mo (annual) / $10/mo (monthly)",
  "macwhisper": "No monthly plan on Gumroad (one-time €59/~$69 lifetime); App Store \"Whisper Transcription\" subscription ~$6.99/mo (or $29.99/yr); optional Assistant add-on $9.99/mo",
  "willow-voice": "$15/mo (monthly) or $12/mo billed annually (Individual); free plan 2,000 words/week",
  "voiceink": "$0/mo (no subscription; one-time lifetime $25-$49)",
  "talktastic": "Free during beta (no public paid monthly price verified)",
  "apple-dictation": "$0 (free, built into macOS/iOS)",
  "otter-ai": "$16.99/mo (Pro monthly; free Basic tier, $8.33/mo billed annually)"
 },
 "rows": [
  {
   "feature": "On-device/offline transcription",
   "cells": {
    "verba": "yes",
    "wispr-flow": "no",
    "superwhisper": "yes",
    "aqua-voice": "no",
    "macwhisper": "yes",
    "willow-voice": "partial",
    "voiceink": "yes",
    "talktastic": "yes:device Whisper; audio ",
    "apple-dictation": "yes",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Cloud transcription",
   "cells": {
    "verba": "yes:optional, BYOK OpenAI",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "partial",
    "willow-voice": "yes:cloud-first AI dictati",
    "voiceink": "partial",
    "talktastic": "partial",
    "apple-dictation": "partial",
    "otter-ai": "yes"
   }
  },
  {
   "feature": "Type-anywhere (auto-paste at cursor)",
   "cells": {
    "verba": "yes",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "yes",
    "willow-voice": "yes:works in any text fiel",
    "voiceink": "yes",
    "talktastic": "yes:pastes appropriate tra",
    "apple-dictation": "yes",
    "otter-ai": "no"
   }
  },
  {
   "feature": "AI rewriting/cleanup of the transcript",
   "cells": {
    "verba": "yes",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "yes",
    "willow-voice": "yes:auto fixes grammar/pun",
    "voiceink": "yes",
    "talktastic": "yes",
    "apple-dictation": "no",
    "otter-ai": "partial"
   }
  },
  {
   "feature": "Multiple editable rewrite modes/prompts",
   "cells": {
    "verba": "yes:6 built-in dictation m",
    "wispr-flow": "partial",
    "superwhisper": "yes",
    "aqua-voice": "partial",
    "macwhisper": "yes",
    "willow-voice": "?",
    "voiceink": "yes",
    "talktastic": "partial",
    "apple-dictation": "no",
    "otter-ai": "partial"
   }
  },
  {
   "feature": "Reads your screen (vision/context)",
   "cells": {
    "verba": "yes:Context mode",
    "wispr-flow": "partial",
    "superwhisper": "?",
    "aqua-voice": "yes",
    "macwhisper": "no",
    "willow-voice": "no",
    "voiceink": "partial",
    "talktastic": "yes:time screenshot of the",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Live translation to a target language",
   "cells": {
    "verba": "yes:Translate mode",
    "wispr-flow": "partial",
    "superwhisper": "partial",
    "aqua-voice": "no",
    "macwhisper": "partial",
    "willow-voice": "?",
    "voiceink": "?",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "partial"
   }
  },
  {
   "feature": "Bring-your-own AI key (BYOK)",
   "cells": {
    "verba": "yes:API key or OpenRouter",
    "wispr-flow": "no",
    "superwhisper": "yes",
    "aqua-voice": "no",
    "macwhisper": "yes",
    "willow-voice": "no",
    "voiceink": "yes",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Use your Claude subscription with no API key",
   "cells": {
    "verba": "yes:Claude Code (Max/Pro) ",
    "wispr-flow": "no",
    "superwhisper": "?",
    "aqua-voice": "no",
    "macwhisper": "no",
    "willow-voice": "no",
    "voiceink": "no",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Local LLM (Ollama) for rewriting",
   "cells": {
    "verba": "yes:fully offline, can aut",
    "wispr-flow": "no",
    "superwhisper": "yes",
    "aqua-voice": "no",
    "macwhisper": "yes",
    "willow-voice": "no",
    "voiceink": "yes",
    "talktastic": "no/unknown (only on-devi",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Voice agent that ACTS on connected apps",
   "cells": {
    "verba": "yes:speak an intent, serve",
    "wispr-flow": "no",
    "superwhisper": "partial",
    "aqua-voice": "no",
    "macwhisper": "no",
    "willow-voice": "no",
    "voiceink": "partial",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "partial"
   }
  },
  {
   "feature": "Number of connected third-party apps",
   "cells": {
    "verba": "989 in catalog (site mar",
    "wispr-flow": "0 (works in any app, but",
    "superwhisper": "30+",
    "aqua-voice": "0 (no app-action integra",
    "macwhisper": "none (no app-action inte",
    "willow-voice": "?",
    "voiceink": "?",
    "talktastic": "~8 named integrations (A",
    "apple-dictation": "0 (no app integrations)",
    "otter-ai": "~12 native (Zoom, Meet, "
   }
  },
  {
   "feature": "Voice task manager / to-dos",
   "cells": {
    "verba": "yes:to-dos with deadline r",
    "wispr-flow": "no",
    "superwhisper": "no/unknown",
    "aqua-voice": "no",
    "macwhisper": "no",
    "willow-voice": "no",
    "voiceink": "no",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "partial"
   }
  },
  {
   "feature": "Long structured notes",
   "cells": {
    "verba": "yes:10 note formats (Clean",
    "wispr-flow": "partial",
    "superwhisper": "?",
    "aqua-voice": "?",
    "macwhisper": "partial",
    "willow-voice": "partial",
    "voiceink": "?",
    "talktastic": "partial",
    "apple-dictation": "no",
    "otter-ai": "yes"
   }
  },
  {
   "feature": "Per-app tone/mode auto-matching",
   "cells": {
    "verba": "yes:modes auto-select when",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "no",
    "willow-voice": "yes:smart writing-style me",
    "voiceink": "yes",
    "talktastic": "yes",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Custom vocabulary/dictionary",
   "cells": {
    "verba": "yes:persisted DictTerm lis",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "yes",
    "willow-voice": "yes:user-editable dictiona",
    "voiceink": "yes",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "yes"
   }
  },
  {
   "feature": "Mac native menu-bar app",
   "cells": {
    "verba": "yes:native Swift, Apple Si",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "yes",
    "willow-voice": "yes:native Mac app (hotkey",
    "voiceink": "yes",
    "talktastic": "yes:bar app; requires macO",
    "apple-dictation": "partial",
    "otter-ai": "partial"
   }
  },
  {
   "feature": "Windows app",
   "cells": {
    "verba": "no",
    "wispr-flow": "yes",
    "superwhisper": "yes",
    "aqua-voice": "yes",
    "macwhisper": "no",
    "willow-voice": "yes",
    "voiceink": "no",
    "talktastic": "no",
    "apple-dictation": "no",
    "otter-ai": "yes"
   }
  },
  {
   "feature": "iOS/Android app",
   "cells": {
    "verba": "no",
    "wispr-flow": "yes",
    "superwhisper": "iOS yes, Android no",
    "aqua-voice": "partial",
    "macwhisper": "partial",
    "willow-voice": "yes:iOS (App Store 'Willow",
    "voiceink": "partial",
    "talktastic": "no",
    "apple-dictation": "partial",
    "otter-ai": "yes"
   }
  },
  {
   "feature": "Gamification/achievements",
   "cells": {
    "verba": "yes:XP/levels, daily goal,",
    "wispr-flow": "no",
    "superwhisper": "no/unknown",
    "aqua-voice": "no",
    "macwhisper": "no",
    "willow-voice": "no",
    "voiceink": "?",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Number of UI languages",
   "cells": {
    "verba": "15",
    "wispr-flow": "?",
    "superwhisper": "?",
    "aqua-voice": "?",
    "macwhisper": "?",
    "willow-voice": "?",
    "voiceink": "?",
    "talktastic": "?",
    "apple-dictation": "40+ dictation languages/",
    "otter-ai": "?"
   }
  },
  {
   "feature": "One-time purchase option",
   "cells": {
    "verba": "no",
    "wispr-flow": "no",
    "superwhisper": "yes",
    "aqua-voice": "no",
    "macwhisper": "yes",
    "willow-voice": "no",
    "voiceink": "yes",
    "talktastic": "?",
    "apple-dictation": "no",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Privacy: audio never uploaded by default",
   "cells": {
    "verba": "yes:on-device (Parakeet/Wh",
    "wispr-flow": "no",
    "superwhisper": "partial",
    "aqua-voice": "no",
    "macwhisper": "yes",
    "willow-voice": "no",
    "voiceink": "yes",
    "talktastic": "yes:device Whisper; 'the a",
    "apple-dictation": "partial",
    "otter-ai": "no"
   }
  },
  {
   "feature": "Price per month",
   "cells": {
    "verba": "$9.99/mo (or $84/year; 3",
    "wispr-flow": "$15/mo (Pro monthly); $1",
    "superwhisper": "$8.49 to $8.99/mo (Pro)",
    "aqua-voice": "$8/mo billed annually ($",
    "macwhisper": "no",
    "willow-voice": "$15/mo monthly, or $12/m",
    "voiceink": "$0/mo, one-time lifetim",
    "talktastic": "Free during beta; no ver",
    "apple-dictation": "$0 (free, included with ",
    "otter-ai": "$0 Basic (free), $16.99 "
   }
  }
 ],
 "verbaEdge": 8
} as const;
