#!/bin/bash
# Generates the art for the full game's content; run from the project root. Finished files are skipped, so it can be rerun after a failure.
P="timeout 600 python tools/art/pixellab.py"
BUILDING="design/Art tests/estate/style_building64.png"
TREE="design/Art tests/estate/style_tree48.png"
CROP="design/Art tests/phase1/style_lavender_ref.png"
CREATURE="game/assets/sprites/dog/east.png"
S=game/assets/sprites
RUIN="turn it into the same building as an abandoned ruin: crumbling cracked walls, collapsed roof with many missing terracotta tiles, broken wood, overgrown with weeds and ivy, same size and same position"
SCAFFOLD="the same ruined building under repair: wooden scaffolding with poles, planks and a ladder in front of it, a few new stones and roof tiles stacked beside it, same size and same position"

has() { [ -s "$1" ]; }
pf() { has "$4" || $P proflash "$1" "$2" --style "$3" --transparent --out "$4" ${5:+--seed $5} | tail -1; }
ed() { has "$3" || $P edit "$1" "$2" --out "$3" | tail -1; }

building() {
  local id=$1 size=$2 desc=$3 ruin=${4:-$RUIN}
  pf "$desc" $size "$BUILDING" $S/buildings/${id}_working.png
  ed $S/buildings/${id}_working.png "$ruin" $S/buildings/${id}_ruin.png
  ed $S/buildings/${id}_ruin.png "$SCAFFOLD" $S/buildings/${id}_scaffold.png
}

person() {
  local id=$1 desc=$2 work=$3
  local dir=$S/people/$id
  if ! has $dir/east.png; then
    $P character "$desc" 48x48 --template mannequin --style "$CREATURE" --out-dir $dir | tail -1
  fi
  local cid=$(python -c "import json;print(json.load(open('$dir/character.json'))['character_id'])")
  has $dir/walk_east/frame_00.png || $P animate $cid "walking calmly at a relaxed pace" --frames 8 --direction east --out-dir $dir/walk_east | tail -1
  if [ -n "$work" ]; then
    has $dir/work_east/frame_00.png || $P animate $cid "$work" --frames 8 --direction east --out-dir $dir/work_east | tail -1
  fi
}

creature() {
  local id=$1 template=$2 desc=$3 size=$4; shift 4
  local dir=$S/animals/$id
  if ! has $dir/east.png; then
    $P character "$desc" $size --template $template --style "$CREATURE" --out-dir $dir | tail -1
  fi
  local cid=$(python -c "import json;print(json.load(open('$dir/character.json'))['character_id'])")
  while [ $# -gt 0 ]; do
    has $dir/$1_east/frame_00.png || $P animate $cid "$2" --frames 8 --direction east --out-dir $dir/$1_east | tail -1
    shift 2
  done
}

# Buildings ---------------------------------------------------------------
building wine_press 96x80 "Roman wine press: a large wooden treading vat full of purple grapes, a heavy wooden beam press with a stone counterweight and clay amphorae, under an open shelter with a terracotta tile roof on wooden posts, side view facing the viewer, flat 2D, entire structure visible, no ground"
building cellar 96x80 "Roman wine cellar: a low half-sunken cream stone building with a thick arched wooden door, a terracotta roof, oak wine barrels and large clay dolia jars stacked beside it, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney"
building barn 112x84 "Roman farm barn: a long cream stone and timber barn with a terracotta tile roof, a wide open wooden door showing golden hay inside, a hay loft window, a wooden water trough in front, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney"
building dairy 80x72 "small Roman dairy hut: whitewashed stone walls, a terracotta roof, an open front with wooden shelves of round yellow cheeses, milk pails and a butter churn by the door, side view facing the viewer, flat 2D, entire building visible, no ground, no chimney"
building lararium 48x64 "a small Roman household shrine (lararium): a miniature stone temple front on a plinth with two little columns and a triangular pediment, painted dark red and cream, a small altar with offerings of fruit and a lit oil lamp, side view, flat 2D, no ground" "turn it into the same small shrine as an old neglected ruin: cracked faded paint, a broken column, moss and weeds, no offerings, same size and same position"

# Villa stages, made from the grand villa backwards so every stage shares its footprint.
ed $S/villa/stage7.png "the same villa without the marble statues, mosaics and decorative urns; keep the bath wing, the portico and the garden; same size and same position" $S/villa/stage6.png
ed $S/villa/stage6.png "the same villa without the bathhouse wing: the side wing becomes a plain low garden wall; keep the portico; same size and same position" $S/villa/stage5.png
ed $S/villa/stage5.png "the same villa without the peristyle garden and its columns behind the house: only the main house with its front portico; same size and same position" $S/villa/stage4.png
ed $S/villa/stage4.png "the same farmhouse without the columned front portico: a plain restored two storey Roman villa rustica with cream walls, terracotta roof and wooden shutters; same size and same position" $S/villa/stage3.png

# Crops -------------------------------------------------------------------
pf "a young grapevine cutting tied to a short wooden stake, a few small green leaves, side view, no pot, no ground" 32x48 "$TREE" $S/grapes/raw/stage0.png 5
pf "a small leafy grapevine climbing a wooden stake, green vine leaves, no grapes, side view, no pot, no ground" 32x48 "$TREE" $S/grapes/raw/stage1.png 5
pf "a full leafy grapevine trained on a T-shaped wooden trellis post, lush green vine leaves, no grapes, side view, no pot, no ground" 32x48 "$TREE" $S/grapes/raw/stage2.png 5
pf "a full leafy grapevine trained on a T-shaped wooden trellis post, lush green vine leaves, heavy hanging bunches of ripe purple grapes, side view, no pot, no ground" 32x48 "$TREE" $S/grapes/raw/bloom.png 5
pf "tiny green rosemary seedlings sprouting from soil, side view, no pot" 32x32 "$CROP" $S/herbs/raw/stage0.png 4
pf "a small young rosemary and thyme herb clump, needle-like grey-green leaves, side view, no pot" 32x32 "$CROP" $S/herbs/raw/stage1.png 4
pf "a full bushy rosemary herb plant with needle-like grey-green leaves, side view, no pot" 32x32 "$CROP" $S/herbs/raw/stage2.png 4
pf "a full bushy rosemary herb plant with needle-like grey-green leaves covered in tiny pale blue flowers, side view, no pot" 32x32 "$CROP" $S/herbs/raw/bloom.png 4

# People ------------------------------------------------------------------
person farmhand "a young Roman farmhand with natural proportions, short brown hair, a simple undyed wool tunic with a rope belt, leather sandals, a woven basket on his hip" "bending down to pick plants and putting them in a basket"
person miller "a sturdy Roman miller woman with natural proportions, hair tied up in a cloth, a flour-dusted cream tunic and a brown apron, leather sandals" "carrying a heavy sack of flour on the shoulder"
person beekeeper "an old Roman beekeeper with natural proportions, a grey beard, a wide straw hat with a veil pushed back, a pale green tunic, holding a small smoker" ""
person perfumer "a Roman perfumer woman with natural proportions, dark braided hair, a lavender purple tunic and a cream shawl, holding a small glass bottle" ""
person presser "a strong Roman wine and olive presser with natural proportions, short curly black hair, a sleeveless brown tunic, bare purple-stained feet and sandals" "pushing a heavy wooden lever with both hands"
person stablehand "a cheerful young Roman stable hand girl with natural proportions, red hair in a braid, a blue tunic, carrying a wooden pail" ""
person trader "a Roman travelling trader with natural proportions, a short beard, a russet hooded cloak over a green tunic, a leather satchel" ""
person shepherd "an old Roman shepherd with natural proportions, a white beard, a brown wool cloak, a long wooden crook staff" ""
person traveller "a Roman traveller with natural proportions, a wide brimmed petasos hat, a dusty travelling cloak, a bundle on a stick over the shoulder" ""
person townsman "a Roman townsman with natural proportions, short dark hair, a white toga over a cream tunic" ""
person townswoman "a Roman townswoman with natural proportions, hair in a bun, a long rose colored stola and a pale palla shawl, carrying a basket of bread" ""

# Animals -----------------------------------------------------------------
creature goat horse "a small white and brown farm goat with short horns, a little beard and natural proportions, standing calmly" 48x48 walk "walking calmly" graze "lowering its head to graze on grass"
creature cat cat "a slim tabby farm cat with natural proportions, orange and cream stripes, standing calmly" 48x48 walk "walking calmly" sleep "curling up and falling asleep"
creature fox dog "a slender red fox with a bushy white-tipped tail, natural proportions, standing calmly" 48x48 walk "trotting lightly"
pf "a plump brown farm hen standing, side view facing right, natural proportions, no ground" 24x24 "$CREATURE" $S/animals/chicken/stand.png 2
pf "a plump brown farm hen pecking at the ground with its head down, side view facing right, natural proportions, no ground" 24x24 "$CREATURE" $S/animals/chicken/peck.png 2
pf "a small wild brown rabbit sitting upright with long ears, side view facing right, no ground" 24x24 "$CREATURE" $S/animals/rabbit/sit.png 2
pf "a small wild brown rabbit mid hop with legs stretched, side view facing right, no ground" 24x24 "$CREATURE" $S/animals/rabbit/hop.png 2
pf "a hoopoe bird with an orange crest, black and white striped wings, standing on the ground, side view facing right, no ground" 24x24 "$CREATURE" $S/animals/hoopoe/stand.png 2
pf "a white stork with black wing tips standing in a large round twig nest, side view facing right" 40x40 "$CREATURE" $S/animals/stork/nest.png 2

# Decorations -------------------------------------------------------------
deco() { pf "$2" $3 "$BUILDING" $S/decorations/$1.png 7; }
deco lanterns "a Roman bronze oil lantern hanging from a tall wooden post, side view, flat 2D, no ground" 16x40
deco planters "a pair of large terracotta pots overflowing with red geraniums and purple lavender, side view, flat 2D, no ground" 40x28
deco statue "a marble statue of the Roman goddess Ceres holding a sheaf of wheat on a stone plinth, side view, flat 2D, no ground" 32x64
deco fountain "a round Roman stone fountain with a carved basin and a small central spout, side view, flat 2D, no ground" 56x40
deco bench "a carved white marble garden bench with lion feet, side view, flat 2D, no ground" 40x24
deco sundial "a Roman stone sundial on a short fluted pedestal, side view, flat 2D, no ground" 24x36
deco column "a single tall white marble Corinthian column with ivy, side view, flat 2D, no ground" 20x60
deco birdbath "a stone birdbath on a pedestal with a small sparrow on its rim, side view, flat 2D, no ground" 24x32
deco dovecote "a tall Roman stone dovecote tower with a terracotta roof and small arched holes, white doves on the ledge, side view, flat 2D, no ground" 32x60
deco pergola "a wooden garden pergola covered in green grapevine leaves and hanging purple grapes, side view, flat 2D, no ground" 64x56
deco golden_statue "a gilded golden statue of a Roman emperor on a marble plinth, gleaming, side view, flat 2D, no ground" 32x64
deco garland_arch "a festive arch of flower garlands with roses and laurel on two wooden poles, side view, flat 2D, no ground" 48x56
deco saturnalia_lanterns "a string of small glowing clay oil lamps hanging between two wooden poles with green laurel, side view, flat 2D, no ground" 64x36
deco mosaic "a square Roman floor mosaic panel showing a dolphin in blue and cream tiles, framed in terracotta, seen from the front, flat 2D" 40x24

# Item icons --------------------------------------------------------------
icon() { has $S/icons/$1.png || $P pixen "$2, a single small game item icon, centered, side view" 16x16 --transparent --out $S/icons/$1.png | tail -1; }
icon lavender "a tied bundle of purple lavender stems"
icon white_lavender "a tied bundle of white lavender stems"
icon wheat "a golden sheaf of wheat"
icon olives "a small pile of dark purple olives with a leaf"
icon grapes "a bunch of purple grapes"
icon herbs "a bundle of green rosemary sprigs"
icon dried_lavender "a bundle of dried pale lavender"
icon flour "a small cloth sack of white flour"
icon straw "a small bale of straw"
icon bread "a round loaf of crusty Roman bread"
icon herb_bread "a round loaf of bread with green herbs on top"
icon olive_oil "a small clay amphora of olive oil"
icon honey "a clay pot of golden honey"
icon lavender_honey "a clay pot of honey with a lavender sprig"
icon wax "a yellow block of beeswax"
icon lavender_oil "a small glass bottle of purple lavender oil"
icon bath_oil "an ornate glass flask of violet bath oil"
icon young_wine "a clay jug of red wine"
icon aged_wine "a sealed old amphora of fine wine with a red seal"
icon eggs "three brown eggs in straw"
icon milk "a wooden pail of milk"
icon cheese "a round yellow cheese wheel"
icon manure "a small dark pile of manure"
icon stone "a stack of grey cut stone blocks"
icon timber "a few stacked wooden planks"
icon tiles "a stack of terracotta roof tiles"
icon truffle "a dark knobbly black truffle"
icon sestertius "a bronze Roman coin"
icon aureus "a shining gold Roman coin"

# Market town -------------------------------------------------------------
has game/assets/backgrounds/market/painting.png || $P pixen "side view of a small sunny Roman market town forum at golden hour: cream stone colonnade with terracotta roofs, market stalls with red and cream striped cloth awnings and baskets of produce, a round stone fountain in the middle, a temple with columns in the background, cypress trees, blue hills far away, warm sky with soft clouds, flat cobblestone ground along the bottom, no people, no text" 480x272 --seed 21 --out game/assets/backgrounds/market/painting.png | tail -1

echo ALL DONE
