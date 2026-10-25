#!/bin/bash
# Generates each building as working, ruined and under construction; run from the project root.
STYLE="design/Art tests/estate/style_building64.png"
OUT=game/assets/sprites/buildings
gen() {
  local id=$1 size=$2 desc=$3 ruin=$4
  timeout 400 python tools/art/pixellab.py proflash "$desc" $size --style "$STYLE" --transparent --out $OUT/${id}_working.png | tail -1
  timeout 400 python tools/art/pixellab.py edit $OUT/${id}_working.png "$ruin" --out $OUT/${id}_ruin.png | tail -1
  timeout 400 python tools/art/pixellab.py edit $OUT/${id}_ruin.png "the same ruined building under repair: wooden scaffolding with poles, planks and a ladder in front of it, a few new stones and roof tiles stacked beside it, same size and same position" --out $OUT/${id}_scaffold.png | tail -1
}
RUIN="turn it into the same building as an abandoned ruin: crumbling cracked walls, collapsed roof with many missing terracotta tiles, broken wood, overgrown with weeds and ivy, same size and same position"
gen drying_shed 96x80 "Roman countryside drying shed: an open-sided wooden shed with a terracotta tile roof on stone pillars, bundles of purple lavender hanging upside down from the beams, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney" "$RUIN"
gen mill 96x80 "small Roman stone mill house with a terracotta roof and an open front showing a large round grey millstone, sacks of flour by the door, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney" "$RUIN"
gen bakery 96x80 "small Roman bakery: cream stone building with a terracotta roof, a large domed brick bread oven at the front with a dark arched opening, a wooden table with round loaves of bread, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney" "$RUIN"
gen olive_press 96x80 "Roman olive press: a large round stone basin and a wooden screw press with a long beam under an open shelter with a terracotta roof on wooden posts, clay amphorae beside it, side view, flat 2D, entire structure visible, no ground" "$RUIN"
gen unguent 96x80 "small Roman perfume and oil workshop: cream stone walls, a terracotta roof, an open counter with rows of small glass bottles and clay jars of lavender oil, baskets of purple flowers, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney" "$RUIN"
gen beehives 64x48 "a row of three traditional woven golden straw beehive skeps on a low wooden bench, a few bees, side view, flat 2D, no ground" "turn it into the same bench with old broken empty straw beehive skeps, faded and falling apart, overgrown with weeds, same size and same position"
TREE="design/Art tests/estate/style_tree48.png"
t() { timeout 400 python tools/art/pixellab.py proflash "$1" 48x48 --style "$TREE" --transparent --seed 3 --out game/assets/sprites/olive/raw/$2.png | tail -1; }
t "a small young olive sapling with a thin trunk and a few silvery green leaves, side view, no pot, no ground" stage0
t "a young olive tree with a slim twisted trunk and a small rounded crown of silvery green leaves, side view, no pot, no ground" stage1
t "a mature olive tree with a gnarled twisted trunk and a wide rounded crown of silvery green leaves, no fruit, side view, no pot, no ground" stage2
t "a mature olive tree with a gnarled twisted trunk and a wide silvery green crown heavy with many small dark purple-black olives, side view, no pot, no ground" bloom
echo ALL DONE
