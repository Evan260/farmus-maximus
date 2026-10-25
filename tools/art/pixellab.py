"""Generate and clean up game art with the PixelLab API.

Usage examples (run from the Otium folder):
  python tools/art/pixellab.py balance
  python tools/art/pixellab.py pixen "lavender bush in bloom" 32x32 --out game/assets/sprites/lavender/bloom.png --transparent
  python tools/art/pixellab.py character "small farm dog" 48x48 --template dog --out-dir game/assets/sprites/dog
  python tools/art/pixellab.py animate CHARACTER_ID "walking calmly" --frames 8 --direction east --out-dir game/assets/sprites/dog/walk
  python tools/art/pixellab.py slice sheet.png 32x32 --out-dir game/assets/sprites/lavender/variants
  python tools/art/pixellab.py clean sprite.png --min-area 40
"""

import argparse
import base64
import csv
import datetime
import io
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
API = "https://api.pixellab.ai/v2"
LEDGER = Path(__file__).with_name("ledger.csv")
STYLE = ("cozy pixel art game art, warm golden hour light from the upper left, "
         "earthy Mediterranean colors, lavender purple accents")


def token():
    for line in (ROOT / ".env").read_text().splitlines():
        if line.startswith("PIXELLAB_TOKEN="):
            return line.split("=", 1)[1].strip()
    sys.exit("PIXELLAB_TOKEN missing from .env")


def call(method, path, body=None):
    req = urllib.request.Request(
        API + path, method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()[:1500]}")


def balance():
    b = call("GET", "/balance")
    return b["credits"]["usd"], b["subscription"].get("generations", 0)


def record(kind, name, before, after):
    # The ledger shows what each asset really cost, since PixelLab's listed prices are only estimates.
    new = not LEDGER.exists()
    usd = before[0] - after[0]
    gens = before[1] - after[1]
    with LEDGER.open("a", newline="") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["time", "kind", "name", "cost_usd", "cost_generations", "usd_left"])
        w.writerow([datetime.datetime.now().isoformat(timespec="seconds"), kind, name,
                    f"{usd:.4f}", f"{gens:g}", f"{after[0]:.4f}"])
    print(f"cost: ${usd:.4f} and {gens:g} generations  (balance ${after[0]:.2f})")


def wait(job_id, every=8, limit=1500):
    start = time.time()
    while time.time() - start < limit:
        job = call("GET", f"/background-jobs/{job_id}")
        if job.get("status") != "processing":
            return job
        time.sleep(every)
    sys.exit(f"job {job_id} timed out")


def download(url, path):
    # The file host rejects Python's default user agent, so curl does the download.
    subprocess.run(["curl", "-s", "-f", "-o", str(path), url], check=True)


def size(text):
    w, h = text.lower().split("x")
    return {"width": int(w), "height": int(h)}


def save_b64(data, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA").save(path)
    print("saved", path)


def cmd_balance(a):
    usd, gens = balance()
    print(f"credits: ${usd:.4f}   subscription generations: {gens}")


def cmd_pixen(a):
    before = balance()
    body = {"description": a.description if a.raw else f"{a.description}, {STYLE}",
            "image_size": size(a.size), "no_background": a.transparent,
            "view": a.view, "outline": a.outline, "detail": a.detail}
    if a.direction:
        body["direction"] = a.direction
    if a.seed is not None:
        body["seed"] = a.seed
    r = call("POST", "/create-image-pixen", body)
    save_b64(r["image"]["base64"], ROOT / a.out)
    record("pixen", a.out, before, balance())


def cmd_character(a):
    before = balance()
    r = call("POST", "/create-character-v3", {
        "description": a.description, "image_size": size(a.size), "template_id": a.template,
        "view": a.view, "outline": a.outline, "detail": a.detail})
    job = wait(r["background_job_id"])
    if job.get("status") != "completed":
        sys.exit(json.dumps(job)[:1500])
    out = ROOT / a.out_dir
    out.mkdir(parents=True, exist_ok=True)
    for direction, url in job["last_response"]["storage_urls"].items():
        download(url, out / f"{direction}.png")
    (out / "character.json").write_text(json.dumps({"character_id": r["character_id"]}, indent=2))
    print("character_id:", r["character_id"])
    record("character", a.out_dir, before, balance())


def cmd_animate(a):
    before = balance()
    r = call("POST", "/animate-character", {
        "character_id": a.character_id, "mode": "pixminimax", "action_description": a.action,
        "frame_count": a.frames, "directions": [a.direction]})
    out = ROOT / a.out_dir
    for job_id in r.get("background_job_ids", []):
        job = wait(job_id, every=10)
        if job.get("status") != "completed":
            sys.exit(json.dumps(job)[:1500])
        for i, img in enumerate(job["last_response"]["images"]):
            save_b64(img["base64"], out / f"frame_{i:02d}.png")
    record("animate", a.out_dir, before, balance())


def cmd_slice(a):
    sheet = Image.open(ROOT / a.sheet).convert("RGBA")
    cw, ch = size(a.cell).values()
    out = ROOT / a.out_dir
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    for y in range(0, sheet.height - ch + 1, ch):
        for x in range(0, sheet.width - cw + 1, cw):
            cell = sheet.crop((x, y, x + cw, y + ch))
            if cell.getchannel("A").getbbox():
                cell.save(out / f"{a.prefix}_{n:02d}.png")
                n += 1
    print(f"saved {n} cells to {out}")


def cmd_clean(a):
    path = ROOT / a.image
    arr = np.asarray(Image.open(path).convert("RGBA")).copy()
    n, labels, stats, _ = cv2.connectedComponentsWithStats((arr[:, :, 3] > 0).astype(np.uint8), 8)
    removed = 0
    for i in range(1, n):
        if stats[i][4] < a.min_area:
            arr[labels == i, 3] = 0
            removed += 1
    Image.fromarray(arr, "RGBA").save(path)
    print(f"removed {removed} stray fragments from {path}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("balance").set_defaults(fn=cmd_balance)

    s = sub.add_parser("pixen")
    s.add_argument("description")
    s.add_argument("size", help="WIDTHxHEIGHT, multiples of 4")
    s.add_argument("--out", required=True, help="path relative to the Otium folder")
    s.add_argument("--transparent", action="store_true")
    s.add_argument("--view", default="side", choices=["side", "low top-down", "high top-down"])
    s.add_argument("--direction")
    s.add_argument("--outline", default="lineless")
    s.add_argument("--detail", default="medium detail")
    s.add_argument("--seed", type=int)
    s.add_argument("--raw", action="store_true", help="do not append the shared style ending")
    s.set_defaults(fn=cmd_pixen)

    s = sub.add_parser("character")
    s.add_argument("description")
    s.add_argument("size")
    s.add_argument("--out-dir", required=True)
    s.add_argument("--template", default="mannequin")
    s.add_argument("--view", default="side")
    s.add_argument("--outline", default="lineless")
    s.add_argument("--detail", default="medium detail")
    s.set_defaults(fn=cmd_character)

    s = sub.add_parser("animate")
    s.add_argument("character_id")
    s.add_argument("action")
    s.add_argument("--frames", type=int, default=8)
    s.add_argument("--direction", default="east")
    s.add_argument("--out-dir", required=True)
    s.set_defaults(fn=cmd_animate)

    s = sub.add_parser("slice")
    s.add_argument("sheet")
    s.add_argument("cell", help="WIDTHxHEIGHT")
    s.add_argument("--out-dir", required=True)
    s.add_argument("--prefix", default="cell")
    s.set_defaults(fn=cmd_slice)

    s = sub.add_parser("clean")
    s.add_argument("image")
    s.add_argument("--min-area", type=int, default=40)
    s.set_defaults(fn=cmd_clean)

    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
