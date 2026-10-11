# #149 — Data Safety review worksheet

Status: **draft, not submitted**. The shared policy in
`assets/privacy/privacy_policy.json` still needs the owner's developer name,
monitored privacy email, retention decision, and policy approval. Do not deploy
or ship the draft contact placeholders.

## Verified release data flows

| Data | Destination and use | Storage |
| --- | --- | --- |
| Feedback text, platform, app-version metadata | Cloudflare Worker → D1; voluntary suggestions and problem reports | Feedback text, platform, app version, generated ID, server timestamp only. No automatic expiry currently. |
| Random installation ID | Worker request header; security rate limiting | Local preferences and Cloudflare rate-limit counters; excluded from D1 and Tafsir cache keys. |
| Connecting IP | Cloudflare infrastructure and Worker rate limiter; security | Excluded from D1 and Tafsir cache keys. Counter window is 60 seconds. Provider infrastructure processing needs deployment/account review. |
| Requested verse key and Tafsir resource ID; source-list request | Worker → Quran Foundation Content API; provide selected content | Shared content responses cached for one hour; no installation or network identity in cache keys. |
| Bookmarks, last-read position, reminder settings, theme/language, prompt preferences | Local storage | Not sent to the Worker. OS backup settings may copy local data. |
| Exported backup and passphrase | On-device encryption; user-selected file destination or share recipient | No app-server upload. Recipient/storage provider is chosen by the user. |

Evidence: `lib/data/feedback/anonymous_feedback_service.dart`,
`lib/data/tafsir/tafsir_transport.dart`,
`lib/data/tafsir/quran_foundation_tafsir_repository.dart`,
`lib/data/backend/cloudflare_client_id_store.dart`,
`lib/data/backup/quran_backup_service.dart`,
`cloudflare/worker/src/index.ts`, and `migrations/0001_anonymous_feedback.sql`.
The feedback identity-exclusion test also submits extra identifiers and verifies
that they are not written to the database.

## Proposed form answers

These are review inputs, not a claim that Play Console has been completed.

| Question/type | Proposed answer | Basis or remaining check |
| --- | --- | --- |
| Collect any user data? | Yes | Feedback and online API requests leave the device. “Anonymous feedback” does not mean “no collection.” |
| Other user-generated content | Collected, optional, not ephemeral; app functionality and analytics | Feedback text is retained and used to improve the app and diagnose reports. Do not interpret “analytics” as an analytics SDK. |
| Diagnostics | Collected, optional, not ephemeral; analytics | Platform/app-version metadata accompanies retained feedback for reported-problem diagnosis. Confirm category against the Console's current prompts. |
| Device or other IDs | Collected; security/fraud prevention; conservatively not ephemeral | Installation ID and IP rate-limit keys. They are optional by avoiding online features. If Console treats required online-feature metadata as required, select required and explain that offline reading remains available. Do not equate a 60-second counter with real-time-only ephemeral processing. |
| App interactions | Collected when using online Tafsir; app functionality; conservatively not ephemeral | Requests reveal the chosen verse/source. Quran Foundation receives content identifiers without the user's installation ID or IP. |
| Sharing | Review provider roles first | Cloudflare hosting/processing may qualify for the service-provider exception if it acts only on our behalf. Verify account contracts and configuration. Treat Tafsir interactions sent to Quran Foundation as shared for app functionality unless its role supports that exception. Do not assume all third parties are exempt. |
| Encrypted in transit | Yes for the intended production configuration | Default Worker and upstream URLs use HTTPS. Recheck the final release defines; local HTTP overrides are development only. |
| Data deletion requests | Yes only after contact/process approval | A monitored email must accept a message's approximate time/text to locate it. No account, IP, or installation-ID lookup is possible in D1. Owner must confirm how requests and backup copies are handled. |
| Account creation/deletion | No in-app account creation | No sign-in or Quran Foundation user-account integration. |
| Independent security review badge | No | No qualifying independent certification is recorded. Code review is not certification. |

Names, email addresses, contacts, precise location, ad identifiers, purchase
history, audio, photos and local reading records are not deliberately collected
by the current app. Do not add these categories merely because a user might
include private information in feedback. Reassess if the feature begins soliciting
such information. Do not select “no approximate location” until provider/log
configuration review confirms there is no IP-derived location retention relevant
to the app's disclosures.

User-initiated encrypted backup export is distinct from app-server collection;
verify any sharing exception against the actual destination flow. No crash or
advertising SDK is present in the app dependency inventory.

## Publication and Console completion

1. Confirm developer identity/contact and feedback retention; if a finite limit
   is chosen, implement and verify expiry before promising it in the policy.
2. Owner reviews the English and Arabic policy, deletion handling, and worksheet.
3. Deploy the reviewed Worker and verify the new invocation-logging setting,
   existing endpoint behavior, and public HTTPS policy pages:
   `https://holy-quran-api.mohamedadam-tech.workers.dev/privacy` and `/privacy/ar`.
   The URLs are planned endpoints until deployment has been verified.
4. Check Cloudflare account logging/Logpush/Tail/security settings, historical
   logs, D1 recovery/backups, and Quran Foundation processing terms. Do not
   promise immediate removal from provider backups without checking retention.
5. Enter the same verified policy URL in Play Console, review the current form
   against this worksheet, save its preview/export, and obtain owner approval
   before production submission. #149 remains open until those steps are done.

The code disables Worker invocation logs for this release and contains no explicit
request-body/header/identifier logging. The live deployment may still have the
previous configuration until deployed. Cloudflare infrastructure processing is
not disabled by this setting. Avoid live feedback submissions as test data.

## Sources checked 2026-10-11

- [Google Play Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Cloudflare invocation logging controls](https://developers.cloudflare.com/workers/observability/logs/workers-logs/)
- [Cloudflare privacy policy](https://www.cloudflare.com/policies/privacy/)
- [Quran Foundation developer privacy requirements](https://api-docs.quran.foundation/legal/developer-privacy/)

The classifications above are engineering inferences from the implementation and
provider documentation. Final answers require the owner to confirm the live
services and the Console preview.
