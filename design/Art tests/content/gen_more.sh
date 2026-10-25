#!/bin/bash
# The market town, the builder who works on repairs, and test icons at a larger size; run from the project root.
P="timeout 600 python tools/art/pixellab.py"
S=game/assets/sprites
[ -s game/assets/backgrounds/market/painting.png ] || $P pixen "side view of a small sunny Roman market town forum at golden hour: cream stone colonnade with terracotta roofs, market stalls with red and cream striped cloth awnings and baskets of produce, a round stone fountain in the middle, a temple with columns in the background, cypress trees, blue hills far away, warm sky with soft clouds, flat cobblestone ground along the bottom, no people, no text" 480x272 --seed 21 --out game/assets/backgrounds/market/painting.png | tail -1
D=$S/people/builder
[ -s $D/east.png ] || $P character "a Roman builder with natural proportions, a short brown beard, a leather apron over a grey tunic, a wooden mallet in hand, a cloth cap" 48x48 --template mannequin --style game/assets/sprites/dog/east.png --out-dir $D | tail -1
CID=$(python -c "import json;print(json.load(open('$D/character.json'))['character_id'])")
[ -s $D/walk_east/frame_00.png ] || $P animate $CID "walking calmly at a relaxed pace" --frames 8 --direction east --out-dir $D/walk_east | tail -1
[ -s $D/work_east/frame_00.png ] || $P animate $CID "hammering a wall with a wooden mallet, swinging the arm up and down" --frames 8 --direction east --out-dir $D/work_east | tail -1
mkdir -p "design/Art tests/icons32"
for i in "olive_oil|a small clay amphora of golden olive oil" "dried_lavender|a tied bundle of dried pale purple lavender stems"; do
  id=${i%%|*}; desc=${i#*|}
  [ -s "design/Art tests/icons32/$id.png" ] || $P pixen "$desc, a single game item icon, centered, side view" 32x32 --transparent --out "design/Art tests/icons32/$id.png" | tail -1
done
echo ALL DONE
