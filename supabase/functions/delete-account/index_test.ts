import { handleDelete } from './index.ts';

function fixture(valid = true, deletionFails = false) {
  const removed: string[] = [];
  return { removed, admin: { auth: {
    getUser: async (_token: string) => ({ data: { user: valid ? {id: 'verified-user'} : null }, error: valid ? null : new Error('invalid') }),
    admin: {deleteUser: async (id: string, soft: boolean) => {
      if (soft) throw new Error('must hard-delete');
      removed.push(id); return {error: deletionFails ? new Error('database') : null};
    }},
  }}};
}
const request = (body: object, token = 'test-token') => new Request('https://example.test/delete-account', {
  method: 'POST', headers: token ? {Authorization: `Bearer ${token}`} : {}, body: JSON.stringify(body),
});
function assert(value: boolean) { if (!value) throw new Error('assertion failed'); }

Deno.test('only server-verified user is deleted', async () => {
  const f = fixture();
  const r = await handleDelete(request({confirmation: 'DELETE_MY_ACCOUNT'}), f.admin);
  assert(r.status === 200 && (await r.json()).deleted === true);
  assert(f.removed.join() === 'verified-user');
});
Deno.test('rejects missing and invalid authentication', async () => {
  const f = fixture(false);
  for (const token of ['', 'invalid']) {
    assert((await handleDelete(request({confirmation: 'DELETE_MY_ACCOUNT'}, token), f.admin)).status === 401);
  }
  assert(f.removed.length === 0);
});
Deno.test('rejects unconfirmed deletion and caller-supplied target', async () => {
  const f = fixture();
  for (const body of [{}, {confirmation: 'DELETE_MY_ACCOUNT', user_id: 'victim'}]) {
    assert((await handleDelete(request(body), f.admin)).status === 400);
  }
  assert(f.removed.length === 0);
});
Deno.test('database failure never returns success or sensitive details', async () => {
  const f = fixture(true, true);
  const r = await handleDelete(request({confirmation: 'DELETE_MY_ACCOUNT'}), f.admin);
  assert(r.status === 500 && (await r.json()).error === 'deletion_failed');
});
