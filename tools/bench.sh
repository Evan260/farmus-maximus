#!/usr/bin/env bash
# Runs the game windowed in each heavy scene and appends one line of JSON per scene to OUT (bench.jsonl by default).
# Usage: tools/bench.sh [OUT] [SECONDS] [SCENE...]
set -u
cd "$(dirname "$0")/../game"
GODOT="${GODOT:-/c/Users/evand/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
OUT="${1:-$PWD/../bench.jsonl}"
SECONDS_EACH="${2:-20}"
shift 2 2>/dev/null || shift $#
SCENES=("$@")
[ ${#SCENES[@]} -eq 0 ] && SCENES=(estate night rain town inside journal strip)
for scene in "${SCENES[@]}"; do
	case "$scene" in
		estate) flags="--hour=10 --weather=sun" ;;
		night) flags="--hour=23 --aurora --weather=sun" ;;
		rain) flags="--hour=21 --weather=rain" ;;
		town) flags="--hour=10 --weather=sun --town" ;;
		inside) flags="--hour=20 --weather=sun --inside --furnish=all" ;;
		journal) flags="--hour=10 --weather=sun --panel=journal" ;;
		strip) flags="--hour=10 --weather=sun --strip" ;;
		windows|minimised) flags="--hour=10 --weather=sun" ;;
		*) echo "unknown scene $scene"; continue ;;
	esac
	timeout $((SECONDS_EACH + 60)) "$GODOT" --path . --quit-after 100000 -- --max-state --no-save --window=1440x810 $flags \
		--bench="$scene" --bench-seconds="$SECONDS_EACH" --bench-out="$OUT" 2>&1 | grep -E "^bench|ERROR|SCRIPT" | head -20
done
