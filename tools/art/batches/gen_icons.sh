#!/bin/bash
# Item icons at 32 by 32, which the generator draws far more clearly than 16 by 16; run from the project root.
P="timeout 600 python tools/art/pixellab.py"
O=game/assets/sprites/icons32
mkdir -p $O
[ -s $O/lavender.png ] || $P pixen "a tied bundle of purple lavender stems, a single game item icon, centered, side view" 32x32 --transparent --out $O/lavender.png | tail -1
[ -s $O/white_lavender.png ] || $P pixen "a tied bundle of white lavender stems, a single game item icon, centered, side view" 32x32 --transparent --out $O/white_lavender.png | tail -1
[ -s $O/wheat.png ] || $P pixen "a golden sheaf of wheat, a single game item icon, centered, side view" 32x32 --transparent --out $O/wheat.png | tail -1
[ -s $O/olives.png ] || $P pixen "a small pile of dark purple olives with a leaf, a single game item icon, centered, side view" 32x32 --transparent --out $O/olives.png | tail -1
[ -s $O/grapes.png ] || $P pixen "a bunch of purple grapes, a single game item icon, centered, side view" 32x32 --transparent --out $O/grapes.png | tail -1
[ -s $O/herbs.png ] || $P pixen "a bundle of green rosemary sprigs, a single game item icon, centered, side view" 32x32 --transparent --out $O/herbs.png | tail -1
[ -s $O/dried_lavender.png ] || $P pixen "a bundle of dried pale lavender, a single game item icon, centered, side view" 32x32 --transparent --out $O/dried_lavender.png | tail -1
[ -s $O/flour.png ] || $P pixen "a small cloth sack of white flour, a single game item icon, centered, side view" 32x32 --transparent --out $O/flour.png | tail -1
[ -s $O/straw.png ] || $P pixen "a small bale of straw, a single game item icon, centered, side view" 32x32 --transparent --out $O/straw.png | tail -1
[ -s $O/bread.png ] || $P pixen "a round loaf of crusty Roman bread, a single game item icon, centered, side view" 32x32 --transparent --out $O/bread.png | tail -1
[ -s $O/herb_bread.png ] || $P pixen "a round loaf of bread with green herbs on top, a single game item icon, centered, side view" 32x32 --transparent --out $O/herb_bread.png | tail -1
[ -s $O/olive_oil.png ] || $P pixen "a small clay amphora of olive oil, a single game item icon, centered, side view" 32x32 --transparent --out $O/olive_oil.png | tail -1
[ -s $O/honey.png ] || $P pixen "a clay pot of golden honey, a single game item icon, centered, side view" 32x32 --transparent --out $O/honey.png | tail -1
[ -s $O/lavender_honey.png ] || $P pixen "a clay pot of honey with a lavender sprig, a single game item icon, centered, side view" 32x32 --transparent --out $O/lavender_honey.png | tail -1
[ -s $O/wax.png ] || $P pixen "a yellow block of beeswax, a single game item icon, centered, side view" 32x32 --transparent --out $O/wax.png | tail -1
[ -s $O/lavender_oil.png ] || $P pixen "a small glass bottle of purple lavender oil, a single game item icon, centered, side view" 32x32 --transparent --out $O/lavender_oil.png | tail -1
[ -s $O/bath_oil.png ] || $P pixen "an ornate glass flask of violet bath oil, a single game item icon, centered, side view" 32x32 --transparent --out $O/bath_oil.png | tail -1
[ -s $O/young_wine.png ] || $P pixen "a clay jug of red wine, a single game item icon, centered, side view" 32x32 --transparent --out $O/young_wine.png | tail -1
[ -s $O/aged_wine.png ] || $P pixen "a sealed old amphora of fine wine with a red seal, a single game item icon, centered, side view" 32x32 --transparent --out $O/aged_wine.png | tail -1
[ -s $O/eggs.png ] || $P pixen "three brown eggs in straw, a single game item icon, centered, side view" 32x32 --transparent --out $O/eggs.png | tail -1
[ -s $O/milk.png ] || $P pixen "a wooden pail of milk, a single game item icon, centered, side view" 32x32 --transparent --out $O/milk.png | tail -1
[ -s $O/cheese.png ] || $P pixen "a round yellow cheese wheel, a single game item icon, centered, side view" 32x32 --transparent --out $O/cheese.png | tail -1
[ -s $O/manure.png ] || $P pixen "a small dark pile of manure, a single game item icon, centered, side view" 32x32 --transparent --out $O/manure.png | tail -1
[ -s $O/stone.png ] || $P pixen "a stack of grey cut stone blocks, a single game item icon, centered, side view" 32x32 --transparent --out $O/stone.png | tail -1
[ -s $O/timber.png ] || $P pixen "a few stacked wooden planks, a single game item icon, centered, side view" 32x32 --transparent --out $O/timber.png | tail -1
[ -s $O/tiles.png ] || $P pixen "a stack of terracotta roof tiles, a single game item icon, centered, side view" 32x32 --transparent --out $O/tiles.png | tail -1
[ -s $O/truffle.png ] || $P pixen "a dark knobbly black truffle, a single game item icon, centered, side view" 32x32 --transparent --out $O/truffle.png | tail -1
[ -s $O/sestertius.png ] || $P pixen "a bronze Roman coin, a single game item icon, centered, side view" 32x32 --transparent --out $O/sestertius.png | tail -1
[ -s $O/aureus.png ] || $P pixen "a shining gold Roman coin, a single game item icon, centered, side view" 32x32 --transparent --out $O/aureus.png | tail -1
echo ALL DONE
