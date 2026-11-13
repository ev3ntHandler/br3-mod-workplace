#!/usr/bin/env bash
## setup_assets.sh
## Populate br3-godot4.8/assets with the original Burnin' Rubber 3 assets
## from ../br3-src/Data.
##
## Godot's project scanner does NOT reliably scan a symlinked directory that
## resolves outside the project root — importing the project would fail
## silently ("valid project found" then the import window just closes). To
## avoid that, `assets` is a real directory populated here with hard links
## (instant, no disk duplication). If hard links are unavailable (e.g. a
## different filesystem), it falls back to a real copy.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/../br3-src/Data"
DEST="$SCRIPT_DIR/assets"

if [ ! -d "$SRC" ]; then
	echo "ERROR: original assets not found at: $SRC"
	echo "Expected the BR3 source tree at ../br3-src/Data relative to this script."
	exit 1
fi

mkdir -p "$DEST"

# Clear any previous contents (hard links only — originals in br3-src are untouched).
find "$DEST" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +

echo "Populating $DEST from $SRC ..."

# Prefer hard links (instant, shares inodes, no extra disk). Fall back to copy.
if cp -al "$SRC/." "$DEST/" 2>/dev/null; then
	echo "Done — assets hard-linked."
else
	echo "Hard links unavailable; copying instead (this may take a moment) ..."
	cp -a "$SRC/." "$DEST/"
	echo "Done — assets copied."
fi

# Keep the placeholder so git tracks the assets/ directory.
touch "$DEST/.gitkeep"

echo ""
echo "Assets are ready. Now import br3-godot4.8 into the Godot project manager."
echo "(On first open Godot will scan and import the FBX/PNG/WAV assets; this"
echo " can take a little while given the size of the original asset tree.)"
