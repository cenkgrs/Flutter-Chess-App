import { createClient } from '@supabase/supabase-js';

// Every database call the dashboard makes lives here. Swapping Supabase for a
// backend of your own means rewriting this file and nothing else.
//
// The anon key is the only credential this app ever holds. It is published by
// Supabase for client use and grants nothing by itself: the reporting
// functions raise `admin required` unless the signed-in account is listed in
// `analytics_admins`. A service-role key would bypass that check, which is
// exactly why it must never reach a browser.

const url = import.meta.env.VITE_SUPABASE_URL;
// Supabase renamed the public client key from "anon" to "publishable";
// accept either so an older .env keeps working.
const anonKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ??
  import.meta.env.VITE_SUPABASE_ANON_KEY;

export const configured = Boolean(url && anonKey);

export const supabase = configured
  ? createClient(url, anonKey, { auth: { persistSession: true } })
  : null;

export async function currentSession() {
  if (!supabase) return null;
  const { data } = await supabase.auth.getSession();
  return data.session ?? null;
}

export async function signIn(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
}

export async function signOut() {
  await supabase?.auth.signOut();
}

/** Thrown when the account is signed in but not an analytics admin. */
export class NotAdminError extends Error {}

async function rpc(name, params) {
  const { data, error } = await supabase.rpc(name, params);
  if (error) {
    if (/admin required/i.test(error.message)) {
      throw new NotAdminError('Bu hesap analitik yöneticisi değil.');
    }
    throw new Error(error.message);
  }
  return data;
}

const iso = (d) => new Date(d).toISOString();

export const overview = (from, to) =>
  rpc('analytics_overview', { p_from: iso(from), p_to: iso(to) });

export const daily = (from, to) =>
  rpc('analytics_daily', { p_from: iso(from), p_to: iso(to) });

export const users = (from, to, limit = 100, offset = 0) =>
  rpc('analytics_users', {
    p_from: iso(from),
    p_to: iso(to),
    p_limit: limit,
    p_offset: offset,
  });

export const eventLog = (from, to, event = null, limit = 200, offset = 0) =>
  rpc('analytics_event_log', {
    p_from: iso(from),
    p_to: iso(to),
    p_event: event,
    p_limit: limit,
    p_offset: offset,
  });

export const EVENT_NAMES = [
  'app_opened',
  'user_signed_up',
  'user_logged_in',
  'game_started',
  'game_finished',
  'assistant_used',
  'analysis_used',
  'subscription_started',
  'subscription_restored',
  'theme_changed',
  'piece_set_changed',
];
