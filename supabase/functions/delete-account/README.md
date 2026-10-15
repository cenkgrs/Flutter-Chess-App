# Deploy account deletion

1. Apply `supabase/migrations/20261015110000_account_deletion.sql` to the **ROK** project, after existing migrations. This only installs a trigger; it does not delete any current account.
2. Deploy from the repository root with the Supabase CLI:

   `supabase functions deploy delete-account --project-ref YOUR_ROK_PROJECT_REF --no-verify-jwt`

   Gateway legacy JWT verification is bypassed because the handler itself validates the bearer token using Auth `getUser`. It never trusts a caller-supplied user ID. Do not remove this server validation. Supabase provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to hosted functions. Never put the service-role key in Flutter, Git or `supabase.env.json`.
3. Verify on a **disposable test account**, not the owner's real account: cancellation, confirmation, failed request, deletion, sign-out, inability to sign in again, and removal from friend/rating lists.

Deletion is a hard Auth Admin deletion. The Auth transaction invokes a restricted trigger to clean up non-cascading app references; a failure rolls the transaction back. It also removes the user's shared match/duel histories (including active games), not opponents' accounts or existing ratings. The UI discloses this. No Storage buckets or social-login providers are currently used; add cleanup/token revocation if introduced later.

An already issued JWT can remain cryptographically valid until expiration; account deletion is not a replacement for RLS and current-user existence checks. Refresh/sign-in cease after Auth deletion. Test against the actual hosted Auth service before App Store submission; local SQL tests use a minimal auth schema, not GoTrue internals.

Tests: `deno test supabase/functions/delete-account/index_test.ts`; `flutter test test/delete_account_test.dart`; `tools/account_deletion_test.sql` after `tools/test_bootstrap.sql` and all migrations in a **disposable local PostgreSQL database only**.

Support website copy should be updated after the function and app release are live. The current email request route remains available; do not claim the new UI is already deployed to users.
