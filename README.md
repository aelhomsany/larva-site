# Larva — corporate static site

A five-page marketing and company site for **Larva**, the parent company that owns and
operates **Leaveo** (the leave/vacation product previously built under the working name
*Ibiza*).

There is **no backend**. No Node, no PHP, no database, no build step, no runtime of any
kind. It is HTML, one stylesheet, one small script, and two SVG marks. Any web server
that can return a file can host it.

---

## 1. What is in here

```
larva-site/
├── index.html            Home — who Larva is, what we do, Leaveo, how we work
├── capabilities.html     The detailed capability statement (8 areas)
├── leaveo.html           The product page for Leaveo
├── contact.html          Registered office address + email routes
├── 404.html              Not-found page
├── favicon.svg
├── robots.txt
├── sitemap.xml
├── assets/
│   ├── css/site.css      The entire design system, one file
│   ├── js/site.js        Mobile nav toggle + footer year. That is all it does.
│   └── img/              larva-mark.svg, leaveo-mark.svg
│                         og-card.png, larva-logo.png  (generated — see § 5)
├── scripts/
│   ├── set-contact.sh    Replaces the placeholder address/emails/domain everywhere
│   ├── make-images.sh    Rasterises the two PNGs above, using headless Chrome
│   ├── og-card.html      Source of og-card.png (the social share card)
│   └── logo-card.html    Source of larva-logo.png (the schema.org logo)
└── deploy/
    ├── nginx.conf        Static server block, hardened, with caching
    ├── Caddyfile         Same thing with automatic HTTPS, if you prefer Caddy
    └── deploy.sh         rsync publish from this machine to the server
```

**Weight (gzipped, first visit of the heaviest page): about 11 KB** — 5.6 KB of HTML,
4.9 KB of CSS, 0.7 KB of JS. The whole site is 152 KB on disk. There are zero
third-party requests — no fonts, no CDN, no analytics, no trackers, and the logo is
inline SVG rather than an image request — which is why the Content-Security-Policy in
the server config can be as strict as it is.

`og-card.png` (377 KB) does not count against that. Nothing on the site references it;
it exists only for link-preview scrapers, which fetch it out of band.

### Verified, not assumed

Before hand-off this was served through real nginx using `deploy/nginx.conf` and checked:

- `nginx -t` passes; all five pages, the stylesheet and the script return `200`.
- Security headers arrive on **both** HTML and asset responses. (nginx does not merge
  `add_header` across levels — a `location` block with its own `add_header` silently
  drops every inherited one. The config avoids nested `add_header` entirely for this
  reason; see the note at the top of the file.)
- `Cache-Control` differs correctly by type: `must-revalidate` for HTML, 7 days for CSS
  and JS, 30 days for images.
- `/capabilities` (no extension) resolves; an unknown path returns the styled 404 page
  with a real `404` status; `/.git/...` returns `403`; gzip is negotiated.
- Under that strict CSP the stylesheet applies and the script runs with **no console
  errors and no CSP violations** — which is why there are no inline `style=""`
  attributes anywhere in the HTML. If you add one, the page still works but the CSP
  will block it; use a utility class in `site.css` instead.
- No horizontal overflow at 375 px, 900 px or 1280 px; the mobile menu opens, closes on
  Escape, and returns focus.
- nginx memory at rest with the site loaded: **9.6 MB**.

Design notes: the palette is the same "Coastal Clarity" foundation Leaveo uses, so
parent and product read as one family. The Larva caterpillar mark is redrawn as SVG
from the supplied logo and is **inlined** into the header and footer of every page —
each copy needs its own gradient `id` (`larva-g-h` in the header, `larva-g-f` in the
footer), because two elements sharing an `id` on one page would make the second one
inherit the first's gradient. `assets/img/larva-mark.svg` is the standalone copy for
decks and email signatures; `favicon.svg` is the same mark on a navy tile so it still
reads at 16 px. Dark mode follows the visitor's system setting.
Layout is responsive at 860 px, text meets WCAG AA contrast, and every page works with
JavaScript disabled.

---

## 2. Before you publish — fill in the real details

The pages ship with obvious placeholders. **The canonical domain is the one still outstanding** — the office address and both
email addresses are already real.

Open `scripts/set-contact.sh`, edit the block at the top, and run it:

```bash
./scripts/set-contact.sh
```

It rewrites every page in place. The values it replaces:

| Placeholder | What it is |
|---|---|
| `https://leaveo.net` | Canonical domain — apex; `www` 301s to it — **set** |
| `sales@leaveo.net` | Leaveo sales / assisted rollouts — **set** |
| `support@leaveo.net` | Support, general enquiries, security reports — **set** |
| `Larva LLC<br>Cairo<br>Egypt` | The registered office, footer form (every page) — **set** |
| `<strong>Larva LLC</strong>Cairo<br>Egypt` | The registered office, full form (contact page) — **set** |

Every placeholder is now filled in, so `set-contact.sh` re-runs as a no-op. It stays
in the repo because the office address or a mailbox will eventually change and you want
that done in one place rather than by hand across five pages.

Then confirm the canonical domain reads the way you expect:

```bash
grep -h 'rel="canonical"' ./*.html
```

Also worth a look before launch:

- There are **no outbound links at all**. `app.leaveo.net` was NXDOMAIN on 2026-09-04, so
  the seven "Customer log in" links were removed rather than shipped broken. When that
  host exists, put them back: one `<li>` in the footer of all five pages, and the outline
  button in the `leaveo.html` hero (currently "Talk to Larva").

  ```html
  <li><a href="https://app.leaveo.net/login">Customer log in</a></li>
  ```

  Nothing else on the site points off it, so until then a broken external link is
  impossible by construction.
- The contact page states Sunday–Thursday, 09:00–17:00 EET. Correct it if that is wrong.
- The plans section on `leaveo.html` deliberately names the tiers but not the prices.
  Keep it that way unless you want to maintain two price lists that can disagree.

### When the product site launches

This site currently occupies the `leaveo.net` apex on its own, so links that used to go
out to the product site were turned inward. When the `ibiza-web` public site
(`src/features/public-site/publicRoutes.ts` — `/`, `/product`, `/pricing`, `/security`,
`/contact-sales`, `/register`, …) is ready to take the apex, these are the exact places
to repoint, and nothing else:

| Where | Currently | Point it back to |
|---|---|---|
| Footer "Leaveo" column, all 5 pages | `/leaveo.html` | `https://www.leaveo.net/` |
| Footer "Leaveo" column, all 5 pages | `/leaveo.html#plans` | `https://www.leaveo.net/pricing` |
| `leaveo.html` hero button | `#plans` ("See the plans") | `https://www.leaveo.net/` |
| `leaveo.html` plans buttons | `/contact.html`, `mailto:sales@` | `https://www.leaveo.net/pricing` |
| `leaveo.html` note under the plans | "the pricing page … is not live yet" | restore "the live pricing page is the authority" |
| `contact.html` sales row | email only | mention Contact Sales on the product site |

At that point this site needs its own hostname — `larva.leaveo.net`, or a Larva domain —
and the canonical tags, `sitemap.xml`, `robots.txt`, `deploy/nginx.conf` and
`deploy/Caddyfile` all move with it. `set-contact.sh` does the first three:

```bash
# edit DOMAIN at the top of the script, then
./scripts/set-contact.sh
```

---

## 3. Minimum server

This is the answer to "how small can the box be": **very**.

### The floor that actually works

| Resource | Minimum | Why |
|---|---|---|
| CPU | 1 vCPU (shared / burstable is fine) | nginx serving small static files is I/O, not CPU. One core handles thousands of requests per second here. |
| RAM | **256 MB** | Measured: nginx serving this exact site uses **9.9 MB** total. A minimal Debian install with systemd uses roughly 80–120 MB on top of that. |
| Disk | **5 GB** | The site is 152 KB. The operating system is the whole cost. |
| Transfer | Anything | ~11 KB per first page view. Even a 500 GB/month allowance is tens of millions of views. |
| OS | Debian 12/13, Ubuntu 22.04/24.04, Alpine, Rocky — any 64-bit Linux | |

That maps to the cheapest tier at essentially every provider (Hetzner CX22 / DigitalOcean
or Vultr or Linode $4–6 basic droplet / Oracle Cloud always-free ARM / AWS Lightsail $3.50).

### What we would actually pick

**1 vCPU · 1 GB RAM · 10–25 GB SSD.** Not because the site needs it, but because 1 GB
leaves room for `certbot` renewals, unattended security upgrades, and the occasional
`apt upgrade` without the OOM killer getting involved. The price difference is a couple
of dollars a month.

### If you insist on 256 MB

It works. Do two things:

1. Add a swap file, so package upgrades cannot OOM:
   ```bash
   sudo fallocate -l 512M /swapfile && sudo chmod 600 /swapfile
   sudo mkswap /swapfile && sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```
2. Use **nginx**, not Caddy. Caddy is a single Go binary that typically holds ~40–60 MB
   resident — fine at 512 MB, tight at 256 MB.

### Not a Linux server at all

If you do not want to run a box: this directory drops unchanged onto Cloudflare Pages,
Netlify, GitHub Pages, or an S3 bucket behind CloudFront. Nothing in the site depends on
the server. The only thing you lose is the custom `try_files` extensionless-URL rule,
and every page already links with the `.html` extension, so nothing breaks.

---

## 4. Publishing to a fresh Linux server

### Step 0 — the droplet and the DNS

**DigitalOcean droplet.** Create → **Ubuntu 24.04 LTS** → Basic → Regular SSD. The
$6/month size (1 GB / 1 vCPU / 25 GB) is the comfortable pick; the $4 size
(512 MB / 10 GB) also clears the measured floor in section 3 with room to spare. Add
your SSH key during creation rather than choosing a root password — the droplet is
reachable from the whole internet the moment it boots. The public IPv4 it gets is
static, so it is safe to put in DNS.

**DNS, at Squarespace.** `leaveo.net` is on Squarespace nameservers
(`nsb1–nsb4.squarespacedns.com`), which is both where the "Coming Soon" page comes from
and where these records live. As of 2026-09-04 the apex had **no A record** and `www`
was a CNAME to `ext-sq.squarespace.com`. You need:

| Type | Host | Value | Note |
|---|---|---|---|
| `A` | `@` | *droplet IPv4* | new — the apex is what every canonical tag names |
| `A` | `www` | *droplet IPv4* | **replaces** the `ext-sq.squarespace.com` CNAME |
| `AAAA` | `@`, `www` | *droplet IPv6* | only if you enabled IPv6; the config already listens on it |

Delete the Squarespace parking records for `@` and `www` — while that CNAME survives,
`www` keeps resolving to Squarespace and never reaches the redirect in `nginx.conf`.

> **Do not delete the `MX` records.** `leaveo.net` mail is on Google Workspace
> (`MX → smtp.google.com`), and `sales@leaveo.net` and `support@leaveo.net` — both
> printed on the contact page — depend on them. Clearing "all the old Squarespace
> records" in one go is the easy way to silently take down your own inbox.

Wait for the records to resolve before running certbot; it validates over HTTP and will
fail against a stale answer:

```bash
dig +short leaveo.net A
dig +short www.leaveo.net A
```

Both must return the droplet's IP and nothing else.

### Option A — nginx + certbot (the conventional route)

**On the server:**

```bash
sudo apt update && sudo apt install -y nginx rsync
sudo mkdir -p /var/www/larva
sudo chown -R "$USER":"$USER" /var/www/larva

# firewall
sudo apt install -y ufw
sudo ufw allow OpenSSH && sudo ufw allow 'Nginx Full' && sudo ufw --force enable

# stay patched without thinking about it
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

**From this machine:**

```bash
./deploy/deploy.sh user@your-server
```

**From this machine**, send the server block across:

```bash
scp deploy/nginx.conf user@your-server:/tmp/larva.conf
```

**Back on the server** — install it and get a certificate:

```bash
sudo install -m 644 /tmp/larva.conf /etc/nginx/sites-available/larva
sudo ln -sf /etc/nginx/sites-available/larva /etc/nginx/sites-enabled/larva
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d leaveo.net -d www.leaveo.net
```

`certbot` edits the server block to add TLS and the HTTP→HTTPS redirect, and installs
its own renewal timer. Once HTTPS is confirmed working, uncomment the
`Strict-Transport-Security` line in `/etc/nginx/sites-enabled/larva` and reload.

> `deploy.sh` deliberately does **not** copy `deploy/`, `scripts/` or `README.md` to the
> server — the web root should contain the site and nothing else. That is why the server
> block is copied across separately, and only once.

### Option B — Caddy (fewer moving parts)

```bash
# on the server
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy rsync

sudo mkdir -p /var/www/larva && sudo chown -R "$USER":"$USER" /var/www/larva
```

Publish the site from this machine, and send the Caddyfile across:

```bash
./deploy/deploy.sh user@your-server
scp deploy/Caddyfile user@your-server:/tmp/Caddyfile
```

Then, back on the server:

```bash
sudo install -m 644 /tmp/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Caddy obtains and renews the certificate itself. There is no certbot, no timer, no
renewal to forget.

---

## 5. Updating the site later

Edit the HTML directly — there is no build step and no template layer, so what you see
in the file is what ships.

```bash
# preview locally, exactly as the server will serve it
python3 -m http.server 8080
# then open http://localhost:8080

# publish
./deploy/deploy.sh user@your-server
```

`deploy.sh` uses `rsync --delete`, so a file removed here is removed on the server.

**Asset caching.** nginx serves `site.css` and `site.js` with `max-age=604800` — seven
days — and the filenames never change. Without help, a returning visitor would keep the
old stylesheet for a week after you change it. So `deploy.sh` stamps each asset URL with
the first eight characters of its content hash before publishing:

```html
<link rel="stylesheet" href="/assets/css/site.css?v=ded0203e">
```

It rewrites in place, only changes when the file's contents change, and re-running is a
no-op. If you preview locally and a CSS edit does not appear, that is this cache and not
your edit — hard-reload, or run the stamping step by hand.

The header and footer are duplicated across the five pages, which is the trade for
having no build step. If you change navigation, change it in all five — `grep -l
'site-nav' *.html` lists them.

HTML is served with `must-revalidate`, so a deploy is visible immediately. Assets under
`/assets/` are cached for seven days; if you change `site.css` and need it instantly,
either rename the file and update the five `<link>` tags, or lower that `expires` value
in the server config.

**The two PNGs are not fingerprinted.** `deploy.sh` stamps only `site.css` and
`site.js`. `og-card.png` and `larva-logo.png` keep stable URLs on purpose, because those
URLs are quoted verbatim inside `og:image` and the JSON-LD, and scrapers cache them
hard. Regenerate with:

```bash
./scripts/make-images.sh
```

Editing `scripts/og-card.html` and re-running is enough — but because the URL does not
change, LinkedIn, Slack and Facebook will keep serving the old card from their own
caches for days. Re-scrape it deliberately in the LinkedIn Post Inspector or Facebook
Sharing Debugger, or give the new file a new name and update the four `og:image` tags.

---

## 6. SEO

There is no plugin and no build step, because there is nothing for one to do: the
markup *is* the source. Everything a plugin like Yoast would generate is a hand-edited
tag in these files.

In place on every page: a unique `<title>` and `<meta name="description">` (all under
155 characters, so nothing is truncated in the results page), `<link rel="canonical">`,
the full Open Graph set including `og:image`, `twitter:card`, `<html lang="en">`, one
`<h1>`, and a clean heading hierarchy. `sitemap.xml` carries `lastmod`; `robots.txt`
points at it. `404.html` is `noindex, follow` and carries no canonical — an error page
must not compete with a real one.

**Structured data.** Every page carries a schema.org `Organization` block for Larva
LLC; `leaveo.html` adds a `SoftwareApplication` block whose `publisher` points back at
that Organization by `@id`. Neither declares `offers` or `aggregateRating`. That is
deliberate — the site quotes no prices (§ 7 explains why) and inventing a rating would
be a lie — so Google's Rich Results Test will report those two as *recommended missing
fields*. That warning is expected. Do not satisfy it with made-up numbers.

**The CSP does not block the JSON-LD, and it does not need a hash.** A `<script>`
element whose `type` is not JavaScript is a data block: it is never executed, so
`script-src` never applies to it. This was checked against the real policy — the JSON-LD
parsed out of the DOM cleanly while a genuine inline script on the same page was
blocked with a console error. If someone later tells you the structured data needs
`'unsafe-inline'`, they are wrong, and the cost of believing them is the whole
Content-Security-Policy.

**What is left is not markup.** The domain has served a parking page until now, so it
has no index history and no inbound links. Expect indexing within days of going live,
and expect to win searches for *Leaveo* — a distinctive term with no competition. Do
not expect to win *Larva*, which belongs to the insect and to a Korean cartoon, and
which no amount of on-page work will take from them.

**The one thing worth doing after launch** is Google Search Console — not a plugin: a
DNS TXT record or an HTML verification file, then submit `sitemap.xml`. It reports the
queries people actually used, with nothing added to the page. Bing Webmaster Tools is
the same shape. Resist analytics scripts; GA4 would break the CSP, add third-party
requests to a site that currently has none, and cost the privacy claim on the contact
page for data Search Console largely gives you free.

---

## 7. What the site claims, and why

The copy is drawn from the actual state of the platform repositories, not from
aspiration. Two rules were applied while writing it:

- **Capabilities describe work we have done**, not technologies we have heard of. The
  eight areas on `capabilities.html` each map to shipped code — tenancy, billing,
  Arabic/RTL, calendar and chat integrations, test architecture, release and recovery.
- **Anything not yet released is labelled as such.** Reporting, calendar sync and
  Slack/Teams delivery are built but feature-controlled, so both the home page and the
  Leaveo page say they are enabled per plan as they pass their gates rather than
  implying they are live today. The pricing section names the tiers and points at the
  live Leaveo pricing page instead of restating amounts that could drift.

If either becomes untrue, the fix is in `index.html` (the `.note` block near the
statistics) and `leaveo.html` (the `.note` block above the plans).
