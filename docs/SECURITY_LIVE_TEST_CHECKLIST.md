# RoomStay manual live security verification

**PARTIALLY LIVE VERIFIED — project-owner report, 22 November 2026.** Mocked Flutter tests verify client behavior, request predicates and rejection paths. Only ordinary-user requests against the deployed policies can verify server authorization. No live requests were executed by this audit. The evidence table distinguishes supplied live results from remaining checks; empty checkboxes below remain a reusable test procedure, not a statement that every check is untested.

## Live evidence supplied by the project owner

No raw response files or deployed policy export were independently inspected here. Treat this as attributed live test evidence, not a new automated verification.

| Check | Reported live result |
|---|---|
| B management list vs A properties | A properties absent |
| B direct PATCH A property | Empty returned rows; unauthorized update blocked |
| B direct DELETE A property | A property retained |
| A deletes own temporary property | Succeeded |
| B PATCH A viewing | Blocked |
| A reads/approves own viewing | Succeeded; renter saw Approved |
| Approved renter UI | Edit/Cancel absent |
| Renter modifies Approved viewing | Direct API attempt blocked |
| Renter self-approves Pending | HTTP 403; database remained Pending |
| B uploads to A folder | Blocked |
| Renter uploads property image | Blocked |
| Forbidden Storage object check | No forbidden test objects in storage.objects |

Remaining evidence: explicit live Reject, renter-owned Pending DELETE isolation, favorite pair/isolation checks, immutable profile-role/client profile-write grants, signup trigger/confirmation, FK actions on linked records, and final APK/device rehearsal. Do not weaken policies that already passed.

## Accounts and disposable records

Prepare Manager A, Manager B and Renter A (plus Renter B for renter isolation). Confirm actual profile roles: the actual database constraint allows `renter` and `partner`; both manager accounts use `partner`. Client alias compatibility does not change that constraint. Use each account's ordinary access token from normal Auth login. Never use a privileged dashboard/SQL/service credential for API authorization tests.

Create disposable properties P_A and P_B owned by their corresponding managers, with independent Pending viewings V_A and V_B. Use separate disposable records for DELETE and each decision; once decided, a viewing is no longer Pending. Record baseline row values as the owner. Stop after any unauthorized mutation and document it; do not continue against valuable records.

Every REST request uses these headers, entered in a private API client:

```text
apikey: <project publishable key>
Authorization: Bearer <token for the actor being tested>
Content-Type: application/json
Prefer: return=representation
```

Base URL: `<project URL>/rest/v1`. Replace `<...>` placeholders with disposable IDs; do not put real credentials in this repository or screenshots.

**Expected denial:** a permission error or an empty returned set with no changed row. A 200/204 status alone is not proof of permission or denial. After each negative mutation, read the row using its owner and compare it with the baseline. For Storage, confirm the unauthorized object does not exist. Record status, sanitized response, actor and resulting state.

## Manager A positive controls

| Check | Manual request/action | Expected result |
|---|---|---|
| [ ] Own management list | GET `/properties?partner_id=eq.<A_ID>&select=id,partner_id,name` | A-owned rows only |
| [ ] Own edit | PATCH `/properties?id=eq.<P_A>&partner_id=eq.<A_ID>` with `{"monthly_rent":9000}` | Nonempty changed representation; value persists |
| [ ] Own delete where allowed | DELETE `/properties?id=eq.<DISPOSABLE_P_A>&partner_id=eq.<A_ID>` | Row removed, or documented FK rejection with row retained |
| [ ] Own viewing list | GET `/viewings?property_id=eq.<P_A>&select=id,property_id,status,renter_id` | Requests belonging to A's property |
| [ ] Approve | PATCH `/viewings?id=eq.<PENDING_V_A>&property_id=eq.<P_A>&status=eq.Pending` with `{"status":"Approved"}` | Returned status Approved; renter sees it after refresh |
| [ ] Reject separately | Same request on another Pending A viewing with `{"status":"Rejected"}` | Returned status Rejected; renter sees it after refresh |
| [ ] Own photo upload | Storage request below with A token and A folder | Success; public URL loads; property stores that URL |

## Manager B negative controls

Use B's token and **A's record IDs**. These deliberately omit the client owner filter so they test server policy rather than a harmless nonmatching query.

| Check | Manual request/action | Expected result |
|---|---|---|
| [ ] Cannot access A private management data | GET `/viewings?property_id=eq.<P_A>&select=*` | No A viewing/renter/message data |
| [ ] Cannot PATCH A property | PATCH `/properties?id=eq.<P_A>` with `{"monthly_rent":9100}` | Denied/no changed row; A reread unchanged |
| [ ] Cannot DELETE A property | DELETE `/properties?id=eq.<DISPOSABLE_P_A>` | Denied/no changed row; A confirms row remains |
| [ ] Cannot approve A viewing | PATCH `/viewings?id=eq.<PENDING_V_A>` with `{"status":"Approved"}` | Denied/no changed row; A confirms Pending |
| [ ] Cannot reject A viewing | Same request with `{"status":"Rejected"}` | Denied/no changed row; A confirms Pending |
| [ ] Cannot upload into A folder | Storage POST with B token and A folder | Denied; no object created |
| [ ] Cannot transfer ownership | PATCH own disposable P_B with `{"partner_id":"<A_ID>"}` | Denied under intended owner WITH CHECK policy |

Property catalogue rows and photo URLs are intentionally public. B seeing A's **public listing** is not a security failure. B must not manage that property or see A's private viewing/renter data. The Flutter management list should still contain only B's owned records.

Also attempt an unauthorized INSERT of a property naming A as owner with B's token and otherwise valid required fields. Expect denial and no new row. Test valid fields to avoid mistaking validation failure for ownership enforcement.

## Storage exact check

Use a tiny valid PNG and a fresh filename for each case:

```text
POST <project URL>/storage/v1/object/property-images/<FOLDER_USER_ID>/<unique-test-name>.png
apikey: <publishable key>
Authorization: Bearer <actor token>
Content-Type: image/png
x-upsert: false
Body: raw PNG bytes
```

- [ ] A → A folder succeeds.
- [ ] B → B folder succeeds (positive control).
- [ ] B → A folder fails with no object.
- [ ] Renter → renter folder fails.
- [ ] Renter → A folder fails.
- [ ] Existing object is not overwritten with `x-upsert:false`.
- [ ] Public download works for intentional property photos, without permitting listing/update/delete.

Do not bulk-delete Storage objects. Clean only explicitly created test objects after checking references, using an authorized administrative process.

## Renter checks

- [ ] With renter token, attempt valid property INSERT using own owner ID; expect denial/no new row.
- [ ] PATCH and DELETE a disposable manager property by ID; expect denial and owner-confirmed unchanged state.
- [ ] Attempt manager-style status PATCH to Approved/Rejected on a viewing; expect denial. A renter must not self-approve their own request either.
- [ ] Attempt photo uploads as above; expect denial.
- [ ] Renter A can GET/POST/DELETE own favorites using their actual ID.
- [ ] Renter B GET `/favorites?user_id=eq.<RENTER_A_ID>&select=*` exposes no A favorites; DELETE a disposable A favorite by ID does not remove it.
- [ ] B cannot POST a favorite with `user_id` set to A. Use an otherwise valid property ID; verify no insertion.
- [ ] A can create/edit/cancel own Pending viewing with a future time.
- [ ] B cannot read, PATCH, or DELETE A's viewing by its ID; owner reread remains unchanged.
- [ ] A cannot PATCH/DELETE their Approved or Rejected viewing, even by forging a raw REST request without the Pending predicate. Confirm the actual server policy implements this rule.
- [ ] Decision/edit race: with disposable data, decide a Pending viewing then submit a stale renter edit with `status=eq.Pending`; expect no changed row. Also verify forbidden decided edit without that predicate.

## Profiles and grants

- [ ] Register disposable renter via Auth signup; database trigger creates profile safely; first login reads it.
- [ ] Ordinary authenticated SELECT of own profile works; required related contact reads work at intended visibility.
- [ ] Direct PATCH of own profile role to `property_manager` fails; role remains unchanged.
- [ ] Direct INSERT/UPDATE of profiles is denied under the intended SELECT-only client grants. Test with otherwise valid data so constraint failures do not mask broad privileges.
- [ ] Inspect actual policies/grants/constraints and trigger definitions read-only. Confirm RLS enabled and no broad permissive policies defeat scoped policies.
- [ ] Review manager UPDATE column privileges: permission to decide status must not imply arbitrary renter/date/property/ownership changes unless explicitly intended.
- [ ] Check favorite pair uniqueness and FK deletion rules. A `23503` FK rejection is a data constraint, not proof that cross-account authorization works.
- [ ] Invalid/expired JWT cannot perform protected operations; no fake success appears in Flutter.

Use the read-only inspection queries in [property_manager_supabase.md](property_manager_supabase.md) and review [Storage setup assumptions](property_images_storage_setup.sql). Do not apply proposed policies or modify schema automatically during verification.

## Evidence log

| Date / build | Actor and role | Check | Sanitized status/result | Owner-confirmed state | PASS/FAIL |
|---|---|---|---|---|---|
| 22 Nov 2026 | A/B/renter | Checks in supplied-evidence table | Project-owner live report | As described above | REPORTED PASS |
| Pending | — | Remaining checks listed above | Not performed in this audit | — | NOT TESTED |
