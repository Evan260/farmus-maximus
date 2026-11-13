# Farmus Maximus: Website Plan

The game's website: what it is for, how it looks, every section on the page, and the assets it needs.

## Not in the plan anymore

The game will not have its own website for now. The Steam page is the home of the game, and a site is only built if the game sells very well (see "Only if it sells very well" in `Business-plan.md`). Why:

- **Wishlists are what count.** Steam shows a game to more people the more wishlists it has, and every clip and post can link straight to the Steam page. An email signup on a site does not add a wishlist, so the site would sit in the way of the one number that matters.
- **The audience is on Steam and short-form video.** People find cozy games through TikTok, YouTube Shorts, Reddit and Steam itself, not by visiting a game's website.
- **Time is better spent on the game and the clips.** The site planned below is a project of its own: an animated hero scene, scroll effects, a shared pet counter, a devlog and a press kit, all to build and keep up to date.
- **It costs money for little return:** a domain, hosting and an email service, before the game has earned anything.

What the site would have done is covered elsewhere: the Steam page carries the screenshots, trailer and description, Discord gathers the players who want to follow along, and a press kit can be a shared folder.

The rest of this document stays as the design to start from if a website is ever built.

---

## Look and feel

### The big idea: a day on the farm

**The page is one day at the villa.** The top of the page is dawn. As you scroll down, the sky warms to midday, then golden hour, then dusk, and the footer is night: fireflies over the lavender, glowing villa windows, stars. The scroll position drives the sky colour and the lighting tint on every section.

This is the site's signature. It shows off the game's day cycle without saying a word, and it is the kind of detail people screen-record and share.

### Palette

Taken from the game's palette, so the site and game feel like one thing.

| Name | Use |
|---|---|
| Lavender (3 to 4 shades) | Main accent, buttons, links, highlights |
| Terracotta | Secondary accent, roof tiles, badges |
| Cream stone | Page backgrounds, cards |
| Cypress green | Text on light backgrounds, borders |
| Olive green | Section dividers, foliage accents |
| Golden hour | Glows, hover states, sunlight |
| Sky blue to night indigo | The scroll-driven sky |

The **Wishlist button is always lavender**, so it is the same colour everywhere on the page and on every social post.

### Typography

| Role | Style | Example fonts (free on Google Fonts) |
|---|---|---|
| Logo and big headings | Roman inscription capitals | Cinzel |
| Small labels, buttons, game UI accents | Pixel font | Pixelify Sans, Silkscreen |
| Body text | Warm and very readable | Lora or Nunito |

Use the pixel font sparingly. Long text in a pixel font is hard to read.

### Pixel art on the web

- Display pixel art at whole-number scales (2x, 3x, 4x) only, never at odd sizes, or pixels go blurry and uneven.
- Use `image-rendering: pixelated` in CSS for every pixel art image.
- Use short looping **MP4 or WebM videos** for animated clips, not GIFs. They are 10 times smaller and look sharper.

---

## Page layout (home page)

### 0. Navigation bar

- Left: the Farmus Maximus logo (small).
- Right: Features, Devlog, Press, Discord, and the **lavender main button** (changes per stage, see above).
- Becomes a slim sticky bar after scrolling past the hero, so the main button is always one click away.
- On phones: logo plus main button, with the other links in a menu.

### 1. Hero (full screen, dawn)

The most important part of the site. Visitors decide in about three seconds.

- **An animated, layered scene of the home farm** built from the game's own parallax layers: sky, mountains, hills with the aqueduct, cypresses, the villa, and a foreground of swaying lavender rows.
- **Alive from the first second:** lavender sways in waves, butterflies drift, a bee or two, the dog asleep in the sun, smoke curling from the bread oven, aqueduct water glinting.
- **Mouse parallax** on desktop: layers shift slightly as the mouse moves, which makes the scene feel deep.
- **Centred over the sky:** the Farmus Maximus logo, a one-line tagline, the main button, and a small "Coming to Steam" line with the Steam and Steam Deck icons.
- **Ambient sound toggle** in a corner (cicadas, breeze, a distant bell). **Off by default**; browsers block autoplaying sound anyway, and surprise audio drives people away.
- A small bobbing arrow or a butterfly that flutters downward, inviting a scroll.

**Tagline options:**
- "Grow lavender. Restore a villa. Let the afternoon pass."
- "A slow, sunlit life in the Roman countryside."
- "Your Roman villa, quietly growing on your desktop."

### 2. The pitch (morning)

- Two or three sentences: what the game is, in plain words.
- One short looping clip (15 to 30 seconds, silent, autoplaying) of the best gameplay moment: harvesting a field of lavender, coins popping, the cart heading to town.
- Under it, three small icons with one line each: **Relaxing**, **Plays on your desktop**, **A villa that grows with you**.

### 3. Feature sections (midday)

Alternating layout: clip on the left and text on the right, then swapped. Each feature has one heading, two or three sentences, and one looping clip or interactive element.

**3a. Fields of lavender**
- Heading: "Purple as far as the eye can see."
- A wide clip of wind rolling through lavender rows, bees and butterflies over the blooms.

**3b. Restore the villa** (the showpiece section)
- Heading: "From ruin to grand estate."
- **Scroll-driven:** the section sticks in place while you scroll, and the villa upgrades through all seven stages, from a crumbling farmhouse to a grand estate with storks nesting on the roof. Each stage swaps in with a puff of dust.
- On phones: a **before/after slider** you drag instead.

**3c. Plays on your desktop**
- Heading: "Let it grow while you work."
- A mock computer desktop (a plain wallpaper, a few icons, a taskbar) with the idle strip docked along the bottom, crops growing and the dog trotting along.
- A toggle switch: **Full window / Idle strip**, which animates between the two views.

**3d. A living world**
- Heading: "Always something to watch."
- A scene with creatures scattered through it: the dog, the cat on the wall, goats on a rock, a lizard, a hoopoe, dragonflies over a fountain.
- **Hover (or tap) a creature** to see a small journal card with its name and a one-line note, like the game's journal. A few are hidden; finding them is a tiny game in itself.

**3e. Seasons and festivals**
- Heading: "Four seasons, and a festival for each."
- Four buttons: **Spring, Summer, Autumn, Winter**. Clicking one changes the scene: blossom petals, full purple bloom, golden vines at harvest, frost on the roofs.
- Short lines about Floralia, Vinalia and Saturnalia.

**3f. Roman life**
- Heading: "Olive oil, wine and the household gods."
- A row of four small cards with pixel art icons: pressing olives, ageing wine in amphorae, offerings at the lararium, sending the cart to market.

### 4. Meet the dog (golden hour)

A small, warm section that is pure charm and a great marketing hook.

- The dog in a larger size, idle-animated.
- **Click to pet:** the dog wags, little hearts float up, a soft happy sound plays if sound is on. A counter shows how many times visitors have petted the dog in total.
- **"Help name the dog"** poll: visitors vote between a few Roman names (Lupus, Felix, Ceres, Fido, Brutus) by entering their email. It makes people feel part of the game, gets signups, and gives you a content post when the winner is announced.

### 5. Screenshot gallery (late afternoon)

- 6 to 8 of the best screenshots in a grid. Click to open full size.
- Each with a short caption.
- Updated as the game improves.

### 6. Devlog (dusk)

- The latest three posts as cards: a thumbnail, a title, a date, one line.
- "Building in public" is a marketing strategy in itself. Every post doubles as a social post and a reason to email the list.
- Link to the full devlog page.

### 7. Join us (dusk into night)

- Email signup: one field, one lavender button, one line on what they get ("Occasional updates and first access to the demo. No spam.").
- Discord invite button.
- Social icons: TikTok, YouTube, Instagram, Reddit, Bluesky or X.

### 8. FAQ (night)

Short, honest answers.

- When does it come out?
- What platforms? (Windows on Steam; Steam Deck support planned.)
- How much will it cost?
- Is it idle or do I play actively? (Both.)
- Does it run in the background while I work?
- Will there be a demo?

### 9. Footer (night)

- The night version of the farm: dark indigo sky, stars, fireflies drifting over the lavender, warm light in the villa windows, an owl on a cypress.
- Once in a while, a shooting star crosses the sky.
- Links: Press kit, Contact, Privacy policy, Steam page.
- A small "Made by Slow Sunday Games" line.

---

## Other pages

| Page | Contents |
|---|---|
| **Devlog** | All development posts, newest first. Each post: text, screenshots, clips. |
| **Press kit** | Fact sheet (developer and publisher Slow Sunday Games, release date, platforms, price, website), short and long description, feature list, logo downloads (light, dark, transparent), key art, a screenshots zip, the trailer, contact email. Journalists and streamers expect this. |
| **Privacy policy** | Required once you collect emails. Covers the email list, analytics and cookies. |
| **Links page** (`/links`) | A simple page for social media bios: Wishlist, Discord, TikTok, YouTube, newsletter. |

---

## Interactions and polish

### Do

- **Cursor trail (desktop):** a few lavender petals drift from the cursor when it moves over the hero. Subtle and short.
- **Hover states:** buttons glow golden, cards lift slightly.
- **Small sounds** on the dog, the season buttons and the toggle, only when sound is turned on.
- **Easter eggs:** clicking the sun makes it set early; clicking the cat makes it ignore you.
- **Fast loading:** the hero scene shows instantly from a still image, then comes alive once the animation loads.

### Do not

- No sound until the visitor turns it on.
- No pop-ups asking for email the moment someone arrives.
- No scroll hijacking beyond the one sticky villa section.
- No animation for visitors who have "reduce motion" switched on in their system settings: show still images instead.

---

## Phones and tablets

Most visitors from TikTok and Shorts arrive on a phone, so the phone layout matters as much as the desktop one.

- The hero uses a taller crop of the scene, with the logo and button near the top and lavender filling the bottom.
- Mouse parallax becomes a gentle tilt effect, or is off.
- Feature sections stack: clip on top, text below.
- The villa section uses the before/after slider.
- The main button stays visible in the slim top bar.
- 16 pixel side margins, no sideways scrolling, large tap targets.

---

## Technology

| Need | Recommendation |
|---|---|
| Building the site | A static site: plain HTML, CSS and JavaScript, or Astro if you want reusable pages and a devlog written in Markdown |
| Hero scene animation | Layered images and small JavaScript, or an HTML canvas drawing the game's own sprites. A later option: export the actual Godot hero scene for the web |
| Hosting | Cloudflare Pages or Netlify (free, fast, automatic from GitHub) |
| Domain | Something short such as `farmusmaximus.com`. Check availability and trademarks first |
| Email list | Kit (formerly ConvertKit), Buttondown or Mailchimp; all have free tiers |
| Shared pet counter and dog name poll | A small server-side function (Cloudflare Workers with its free key-value storage), since a static page cannot store a shared count by itself |
| Analytics | Plausible (privacy friendly, no cookie banner needed) or Google Analytics |
| Tracking where visitors come from | Tagged links (UTM parameters) for every platform: TikTok, YouTube, Reddit, each devlog post |
| Steam | A Steam wishlist button and Steam's embeddable widget once the page exists |
| Social previews | An Open Graph image (1200 x 630) so links look good when shared |

**Performance budget:** the home page should load its first view in under 2 seconds on a phone. Compress clips (under 2 MB each), load sections below the first screen only when scrolled to, and serve images in WebP or AVIF.

---

## Website assets needed

| Asset | Notes |
|---|---|
| Hero scene layers | The home farm parallax layers (shared with the game) |
| Hero animated elements | Lavender sway frames, butterflies, bees, the sleeping dog, oven smoke, water glints |
| Sky colour stops | Dawn, morning, midday, golden hour, dusk, night |
| Night footer scene | The same farm at night, with lit windows, fireflies, stars, an owl |
| Logo | Full colour, light, dark and transparent versions |
| Favicon and app icons | 16, 32, 180 and 512 pixel sizes |
| Open Graph image | 1200 x 630 |
| Pitch clip | 15 to 30 seconds, looping |
| Feature clips | Lavender fields, desktop idle strip, the living world, seasons (4 short loops) |
| Villa stages | All 7 stages, plus a dust puff transition |
| Mock desktop | Wallpaper, taskbar and icons for the idle strip demo |
| Creature sprites and journal cards | 8 to 12 creatures with names and one-line notes |
| Season scene variants | Spring, summer, autumn, winter |
| Dog | Idle, wag and happy animations, hearts effect |
| Roman life icons | Olive press, amphora, lararium, cart |
| Screenshots | 6 to 8, updated over time |
| Social icons | TikTok, YouTube, Instagram, Reddit, Discord, Bluesky or X, Steam |
| Ambient audio loop | Cicadas, breeze, distant bell (optional, off by default) |
| UI sounds | Pet the dog, button clicks, season change |
| Press kit downloads | Logo pack, key art, screenshots zip |

---

## Writing for the site

- Short sentences, warm and calm, like the game. Nothing shouty.
- Show more than you tell: a clip beats a paragraph.
- Use "you": "You restore the villa", not "Players can restore the villa".
- Never promise features that are not decided yet. List only what you are confident will ship.
