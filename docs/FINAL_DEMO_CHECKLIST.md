# RoomStay final demo checklist

Status: **final APK rehearsal pending; core approval/security steps have user-reported live evidence**. Automated tests use mocks and do not establish live Supabase behavior. Run this checklist using the exact APK and source snapshot intended for submission. Record date, APK/source identifier, device, tester, and pass/fail evidence without passwords or tokens.

The project owner reported successful manager approval → renter Approved display and cross-account property/viewing/Storage checks on 22 November 2026. Preserve those working policies; finish the final-device flow and Reject case without treating earlier verified checks as failed.

## Preparation

- [ ] Confirm internet, Supabase project availability, and charged device.
- [ ] Keep credentials privately for one renter and a provisioned Property Manager (database role `partner`). Registration creates renters through the trusted database trigger.
- [ ] Have one manager-owned property with a valid image, whole-baht rent, facilities, readable contact details, and availability enabled.
- [ ] Prepare a future Pending request for Approve and a separate request for Reject. Remove duplicates/temporary records only after inspecting them and confirming they are disposable.
- [ ] Verify public property/image reads, related profile reads, manager viewing policies, and ownership with [the security checklist](SECURITY_LIVE_TEST_CHECKLIST.md).
- [ ] Confirm app uses live records: an empty Favorites response must display the empty state, not fixtures.
- [ ] Rehearse at normal and 2× system text size; open the contact sheet and reach Copy Email.

## Presentation sequence

| Step | Action | Expected evidence | Result |
|---|---|---|---|
| 1 | Launch RoomStay | Branded splash → Login | [ ] |
| 2 | Renter Login | Renter five-tab navigation; correct profile | [ ] |
| 3 | Home | Real property cards and image load | [ ] |
| 4 | Search | Keyword and actual filter narrow results; numeric price sort works | [ ] |
| 5 | Property Detail | Image, price, facilities, availability and Property Manager info | [ ] |
| 6 | Favorite property | Heart changes after successful save; Favorites shows same room | [ ] |
| 7 | Contact Property Manager | Sheet scrolls if needed; Copy Email copies full value | [ ] |
| 8 | Request Viewing | Future date/time, optional message, successful request visible as Pending | [ ] |
| 9 | Logout | Old session cleared; Login shown | [ ] |
| 10 | Property Manager Login | Properties / Viewing Requests / Profile tabs | [ ] |
| 11 | Properties | Only this manager's management records | [ ] |
| 12 | Add Property | Choose type/bedrooms, whole-baht rent, facilities, gallery photo; upload/save succeeds; new record visible | [ ] |
| 13 | Edit Property | Change rent/facility/availability; save and reopen to verify | [ ] |
| 14 | Viewing Requests | Find the renter's request for this manager's property; Approve once | [ ] |
| 15 | Logout | Login shown; manager session cleared | [ ] |
| 16 | Renter Login | Renter identity restored | [ ] |
| 17 | My Viewings | Refresh/reopen: Approved visible, no Edit or Cancel for that row | [ ] |
| 18 | Final Profile / Logout | Correct name/email/role; successful logout | [ ] |

Separately rehearse Reject, pending edit/cancel, Favorites remove/empty/error, gallery cancel, upload failure, and safe property deletion. Approved and Rejected rows must have no renter Edit/Cancel. Cancellation deletes a Pending row; it is not a booking or payment action. Check restrictive/cascading FK behavior before any delete demonstration.

## Short failure plan

- Slow upload: stop retrying repeatedly; use an already-created **real** property with its existing image, and use a real existing Pending viewing for approval.
- Stale or expired session: log out and log in again. No automatic token refresh is implemented.
- Status not refreshed: reopen/refresh My Viewings after the manager decision; status is not realtime.
- Network unavailable: state the outage honestly; use clearly labelled prerecorded evidence/screenshots from a successful live rehearsal. Do not describe screenshots as a current successful operation.
- Permission/RLS error: retain the failure, check the ordinary account/ownership and recorded policies later. Do not disable RLS or use a privileged key to rescue a demo.
- Repeated submit uncertainty: inspect the actual list before trying again to avoid duplicate rows.

No fake runtime data, offline success branch, or automated live mutation is part of this plan.

## Sign-off

- Source commit/archive identifier: __________
- APK checksum/version: __________
- Device / Android / text size: __________
- Date / tester: __________
- Steps failed and recovery used: __________
- Approve and Reject evidence recorded: __________
