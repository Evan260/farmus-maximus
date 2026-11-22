FARMUS MAXIMUS: APP STORE PICTURES

The pictures the App Store listing needs. Screenshots are uploaded in App Store Connect (appstoreconnect.apple.com):
Apps, the game, the version being prepared, then Previews and Screenshots, with one tab per display size.

The pictures are made by python tools/phone/make_store_art.py, which has the game render each scene with its phone
interface (--phone) at the store's exact size, so they always match the game. Run it again after the art or the
interface changes, then look at every picture: people and animals walk about, so one can land in front of another.
Like the Steam screenshots, they carry no captions. The estate is drawn at a whole number of screen pixels to the game
pixel in every picture (4 on the iPhone, 7 on the iPad), and nothing is resized with smoothing.


APP ICON

icon_1024.png   1024x1024 PNG, no alpha channel, square corners.
                The farmhouse with the stork on its roof, the dog on the path and the lavender beds at golden hour:
                tools/art/icon_square.png enlarged four times, nearest neighbour. Apple rounds the corners itself.
                Meets: the App Store icon, 1024x1024, no transparency and no alpha channel, no rounded corners.
                App Store Connect takes this icon from the build rather than from an upload, so it goes into Godot's
                iOS export preset, in its Icons section (the 1024x1024 App Store icon).


IPHONE SCREENSHOTS (iphone_6.9_inch_screenshots/, all 2868x1320 landscape, PNG without alpha)

01_estate_golden_hour.png        The restored estate at golden hour: the farmhouse, the lavender beds, the dog, the
                                 stork, the trader's cart, and the phone interface.
02_grape_harvest.png             The vineyard in autumn, the vines heavy with grapes, the wine press, the cellar and
                                 the unguent workshop.
03_market_town.png               The market town: the temple, the fountain, the stalls, a shopper at the fruit stall,
                                 and the market's place buttons.
04_farmhouse_by_night.png        Inside the furnished farmhouse at night: the fire, the lamps, the loom, the cat on the
                                 table and the dog asleep on the rug. The room fades into shadow at the sides, as it
                                 does on a screen this wide.
05_northern_lights.png           The estate at night under the northern lights, its windows lit. The one picture
                                 without the interface, which would sit over the lights.
06_rainbow_over_the_pasture.png  A rainbow after rain over the pasture, the goats and chickens out, the barn and the
                                 dairy behind them.

The journal is left out here: at the iPhone's interface size its window covers the words of the money panel.

Meets: the 6.9-inch iPhone display size, which takes 2868x1320 in landscape (or 2796x1290 or 2736x1260); 1 to 10
screenshots, PNG or JPEG without alpha. Apple scales these down for the smaller iPhones, so this one size covers them.


IPAD SCREENSHOTS (ipad_13_inch_screenshots/, all 2752x2064 landscape, PNG without alpha)

01_estate_golden_hour.png   The restored estate at golden hour, framed on the farmhouse.
02_grape_harvest.png        The vineyard in autumn, the vines heavy with grapes.
03_market_town.png          The market town with its townsfolk by the fountain and the place buttons along the bottom.
04_farmhouse_by_night.png   Inside the furnished farmhouse at night, the fire and the sleeping dog close up.
05_northern_lights.png      The farmhouse at night under the northern lights, without the interface.
06_journal.png              The farmer's journal open at the animals, on the honeybees.

An iPad's squarer screen shows the estate larger and crops its sides, as the game does for any window near 4:3, so
the estate and the northern lights are framed on the farmhouse by the trailer's villa shot. That shot also hides the
gold coins from the money panel, which is why the first picture shows only the sestertii.

Meets: the 13-inch iPad display size, which takes 2752x2064 in landscape (or 2732x2048); required when the game runs
on iPad; 1 to 10 screenshots, PNG or JPEG without alpha. Apple scales these down for the smaller iPads.


NOT MADE HERE

- App previews, the optional videos of 15 to 30 seconds for each display size.
- The listing's text: name (30 characters), subtitle (30), promotional text (170), description (4,000) and keywords
  (100). store/steam_page/about_this_game.txt is a starting point, without its Steam formatting.
- A support link and a privacy policy link, and the age rating questionnaire, which are forms in App Store Connect.
