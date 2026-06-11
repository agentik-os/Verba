/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as account from "../account.js";
import type * as auth from "../auth.js";
import type * as feedback from "../feedback.js";
import type * as history from "../history.js";
import type * as leaderboard from "../leaderboard.js";
import type * as notes from "../notes.js";
import type * as profiles from "../profiles.js";
import type * as ratelimit from "../ratelimit.js";
import type * as settings from "../settings.js";
import type * as stats from "../stats.js";
import type * as wishlist from "../wishlist.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  account: typeof account;
  auth: typeof auth;
  feedback: typeof feedback;
  history: typeof history;
  leaderboard: typeof leaderboard;
  notes: typeof notes;
  profiles: typeof profiles;
  ratelimit: typeof ratelimit;
  settings: typeof settings;
  stats: typeof stats;
  wishlist: typeof wishlist;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
