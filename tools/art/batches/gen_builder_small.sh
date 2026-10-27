#!/bin/bash
# A smaller builder, closer to the size of a real person beside the buildings; run from the project root.
P="timeout 600 python tools/art/pixellab.py"
D=game/assets/sprites/people/builder_small
[ -s $D/east.png ] || $P character "a Roman builder with natural proportions, a short brown beard, a leather apron over a grey tunic, a wooden mallet in hand, a cloth cap" 32x32 --template mannequin --style game/assets/sprites/people/builder/east.png --out-dir $D | tail -1
CID=$(python -c "import json;print(json.load(open('$D/character.json'))['character_id'])")
[ -s $D/walk_east/frame_00.png ] || $P animate $CID "walking calmly at a relaxed pace" --frames 8 --direction east --out-dir $D/walk_east | tail -1
[ -s $D/work_east/frame_00.png ] || $P animate $CID "hammering a wall with a wooden mallet, swinging the arm up and down" --frames 8 --direction east --out-dir $D/work_east | tail -1
[ -s $D/climb_north/frame_00.png ] || $P animate $CID "climbing up a wooden ladder, seen from behind" --frames 8 --direction north --out-dir $D/climb_north | tail -1
echo ALL DONE
