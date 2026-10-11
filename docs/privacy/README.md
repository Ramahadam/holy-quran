# Holy Quran privacy policy — #149

The policy is a **draft awaiting owner details and approval**. Its single source
is `assets/privacy/privacy_policy.json`, shared by the offline Flutter screen and
Cloudflare's HTML endpoint. Settings → Privacy policy opens the bundled text
without network access. Public paths are `/privacy` (English) and `/privacy/ar`
(Arabic). No extra app dependency, browser tracking, cookies, or script is added.

The developer name, privacy email, and retention decision are still pending.
`OWNER_CONTACT_REQUIRED` deliberately identifies unresolved text. Do not deploy
or release this draft. Read [Data Safety worksheet](data-safety.md) for the
implementation evidence, proposed declarations, and remaining owner/Console work.

After editing the shared policy, rebuild both the app and Worker so each uses
the approved text. Preview locally with `npx wrangler dev --local --port 8787`
from `cloudflare/worker`, then open `http://127.0.0.1:8787/privacy`.

#149 is not closed by the preparation PR: the public URL, owner approval, and
Play Console policy URL/Data Safety declarations still need completion.
