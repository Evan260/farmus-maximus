FARMUS MAXIMUS: GOOGLE PLAY STORE LISTING PICTURES

The pictures the Google Play store listing needs, ready to upload in Play Console (play.google.com/console). Open the
app, then Store presence > Main store listing > Graphics.

The pictures are made by python tools/phone/make_store_art.py, which has the game render each scene with its phone
interface (--phone) at the store's exact size, so they always match the game. Run it again after the art or the
interface changes, then look at every picture: people and animals walk about, so one can land in front of another.
Like the Steam screenshots, they carry no captions. The estate is drawn at a whole number of screen pixels to the game
pixel in every picture (4 on the phone and the 7-inch tablet, 5 on the 10-inch tablet), and nothing is resized with
smoothing.


APP ICON

icon_512.png   512x512, 32-bit PNG, every pixel opaque.
               The farmhouse with the stork on its roof, the dog on the path and the lavender beds at golden hour:
               tools/art/icon_square.png enlarged twice, nearest neighbour. It fills the whole square, because Google
               rounds the corners and adds the shadow itself.
               Meets: 512x512 32-bit PNG, at most 1024 KB (this one is 120 KB).


FEATURE GRAPHIC

feature_graphic_1024x500.png   1024x500, 24-bit PNG, no alpha.
               The restored estate at golden hour, the farmhouse in the middle, with the game's logo over the sky. The
               estate is rendered at one screen pixel to the game pixel and enlarged twice, and the logo is enlarged by
               the same two, so the two share one pixel size. No badges and no text but the logo.
               Meets: 1024x500, JPEG or 24-bit PNG without alpha.


PHONE SCREENSHOTS (phone_screenshots/, all 1920x1080 landscape, 24-bit PNG)

Upload them in this order; the first three show first on the listing.

01_estate_golden_hour.png        The restored estate at golden hour: the farmhouse, the lavender beds, the dog, the
                                 stork, and the phone interface (money panel, zone buttons, side buttons, tool button).
02_grape_harvest.png             The vineyard in autumn, the vines heavy with grapes, the wine press, the cellar and
                                 the unguent workshop.
03_market_town.png               The market town: the temple, the fountain, the stalls and the townsfolk.
04_farmhouse_by_night.png        Inside the furnished farmhouse at night: the fire, the lamps, the loom, the cat on the
                                 table and the dog asleep on the rug.
05_northern_lights.png           The estate at night under the northern lights, its windows lit. The one picture
                                 without the interface, which would sit over the lights.
06_rainbow_over_the_pasture.png  A rainbow after rain over the pasture, the goats and chickens out, the barn and the
                                 dairy behind them.
07_bakery_window.png             A workshop's window on the workshop yard: the bakery turning flour into bread.
08_journal.png                   The farmer's journal open at the animals, all sixteen found, on the honeybees.

Meets: 2 to 8 phone screenshots, JPEG or 24-bit PNG without alpha, each side 320 to 3,840 px, 16:9. A game needs at
least three 16:9 landscape screenshots of at least 1920x1080 to be shown in Google Play's game recommendations; all
eight qualify.


TABLET SCREENSHOTS

tablet_7_inch_screenshots/    1920x1200 landscape (16:10), 24-bit PNG
tablet_10_inch_screenshots/   2560x1600 landscape (16:10), 24-bit PNG

Each folder holds the same four scenes, taken at that window size with the phone interface, so the layout is the one a
tablet of that shape gets:

01_estate_golden_hour.png
02_market_town.png             On a 16:10 screen the market's place buttons show along the bottom.
03_farmhouse_by_night.png
04_northern_lights.png

Meets: up to 8 screenshots for each tablet size, JPEG or 24-bit PNG without alpha, each side 320 to 3,840 px, the long
side at most 2.3 times the short one. Google's large-screen guidance asks for at least 4 tablet screenshots at 16:9 to
be featured on tablets; if Play Console asks for 16:9 there, upload the 1920x1080 phone screenshots in these slots.


NOT MADE HERE

- The listing's text: app name (30 characters), short description (80) and full description (4,000).
  store/steam_page/about_this_game.txt is a starting point, without its Steam formatting.
- A promo video, optional, given as a YouTube link.
- Chromebook and Android XR screenshots, optional.
- The content rating questionnaire, the data safety form and a privacy policy link, which are forms in Play Console.
