// Uses the built-in Auth Admin API; never ship the service-role key in Flutter.
import { createClient } from "npm:@supabase/supabase-js@2.99.1";

const json = (status: number, value: object) => new Response(JSON.stringify(value), {
  status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
});

type AuthAdmin = {
  auth: {
    getUser(token: string): Promise<{ data: { user: { id: string } | null }; error: unknown }>;
    admin: { deleteUser(id: string, soft: boolean): Promise<{ error: unknown }> };
  };
};

export async function handleDelete(request: Request, admin: AuthAdmin) {
  if (request.method !== "POST") return json(405, { error: "method_not_allowed" });
  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return json(401, { error: "unauthorized" });
  try {
    // Server lookup rejects deleted/revoked users even if their JWT hasn't expired.
    const { data, error } = await admin.auth.getUser(authorization.slice(7));
    if (error || !data.user) return json(401, { error: "unauthorized" });
    const body = await request.json().catch(() => null);
    if (body?.confirmation !== "DELETE_MY_ACCOUNT" || Object.keys(body).length !== 1) {
      return json(400, { error: "confirmation_required" });
    }
    const { error: deletionError } = await admin.auth.admin.deleteUser(data.user.id, false);
    if (deletionError) return json(500, { error: "deletion_failed" });
    return json(200, { deleted: true });
  } catch {
    // Do not expose credentials, user data or database errors to the client.
    return json(503, { error: "unavailable" });
  }
}

if (import.meta.main) Deno.serve((request: Request) => {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return json(503, { error: "unavailable" });
  const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  return handleDelete(request, admin);
});
