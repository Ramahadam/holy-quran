# Holy Quran privacy policy — #149

The policy is a **draft awaiting final owner approval**. Its single source
is `assets/privacy/privacy_policy.json`, shared by the offline Flutter screen and
Cloudflare's HTML endpoint. Settings → Privacy policy opens the bundled text
without network access. Public paths are `/privacy` (English) and `/privacy/ar`
(Arabic). No extra app dependency, browser tracking, cookies, or script is added.

The owner confirmed Mohamed Adam and mohamedadam.tech@gmail.com as the
developer name and privacy contact, and approved 90-day feedback retention.
Daily expiry is implemented in the Worker; it becomes active only after deployment.
Final policy approval remains pending. Do not deploy
or release this draft. Read [Data Safety worksheet](data-safety.md) for the
implementation evidence, proposed declarations, and remaining owner/Console work.
See [security review](security-review.md) for disclosure decisions and open findings.

After editing the shared policy, rebuild both the app and Worker so each uses
the approved text. Preview locally with `npx wrangler dev --local --port 8787`
from `cloudflare/worker`, then open `http://127.0.0.1:8787/privacy`.

#149 is not closed by the preparation PR: the public URL, owner approval, and
Play Console policy URL/Data Safety declarations still need completion.

## Feedback expiry

The scheduled handler deletes active feedback records at least 90 days old once
a day at 03:00 UTC (07:00 Dubai). It uses the indexed, UTC `created_at` column
and a bound cutoff; feedback newer than the cutoff is preserved. The first run
also removes existing expired feedback. Failures propagate to the scheduler;
check Cron Events after deployment and investigate missed or failed runs.
The next successful run also removes any backlog.

Verify the trigger is active and a cleanup succeeds before publishing the policy.
After restoring a database backup, run cleanup before resuming use so expired
records are not reintroduced. Provider recovery copies have separate lifetimes;
confirm those settings during the remaining account review.

Implementation follows Cloudflare's [scheduled handler documentation](https://developers.cloudflare.com/workers/runtime-apis/handlers/scheduled/)
and [UTC cron configuration](https://developers.cloudflare.com/workers/configuration/cron-triggers/).
