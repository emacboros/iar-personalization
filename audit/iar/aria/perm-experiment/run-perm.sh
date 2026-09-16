#!/usr/bin/env bash
# run-perm.sh -- birth the permanent child inside its container.
# EXPERIMENT FILE -- server-local only.
set -u
IMAGE="localhost/iar-emacboros"
NAME="perm-child"
REPO="$HOME/perm-child/i.ar"
PERS="$HOME/perm-child/personalization-mnt"
GPTEL="$HOME/perm-child/gptel"
TRANSCRIPT="$HOME/perm-child/transcript"
mkdir -p "$TRANSCRIPT"

# Remove stale container from a previous life
podman rm -f "$NAME" >/dev/null 2>&1 || true

podman run \
  --name "$NAME" \
  --read-only \
  --memory=32g \
  --security-opt no-new-privileges \
  --cap-drop=all \
  --network=host \
  -e EMACBOROS_OLLAMA_HOST=localhost:11434 \
  -e EMACBOROS_OLLAMA_MODEL=ornith:35b \
  -e EMACBOROS_OLLAMA_CTX=262144 \
  -e PERM_TRANSCRIPT=/root/transcript/life.org \
  -e PERM_STATE=/root/transcript/state.txt \
  -e GIT_AUTHOR_NAME=perm-child \
  -e GIT_AUTHOR_EMAIL=perm-child@experiment.local \
  -e GIT_COMMITTER_NAME=perm-child \
  -e GIT_COMMITTER_EMAIL=perm-child@experiment.local \
  -e GIT_PAGER=cat \
  -e LANG=C.utf8 \
  --tmpfs /tmp:rw,size=512m \
  --tmpfs /run:rw,size=64m \
  --tmpfs /var/tmp:rw,size=64m \
  -v "$REPO/emacs.d:/root/.emacs.d:z" \
  -v "$REPO/metaconfig:/root/.emacs.d/metaconfig:z" \
  -v "$REPO/prompts:/root/.emacs.d/agents.d:z" \
  -v "$REPO:/root/i.ar:z" \
  -v "$PERS:/root/personalization:z" \
  -v "$GPTEL:/root/.emacs.d/gptel-fork:z" \
  -e EMACBOROS_GPTEL_FORK_PATH=/root/.emacs.d/gptel-fork \
  -v "$TRANSCRIPT:/root/transcript:z" \
  -v "$HOME/perm-child/permanent-cycle.el:/root/permanent-cycle.el:ro,z" \
  --entrypoint /bin/bash \
  "$IMAGE" \
  -c "preflight.sh && emacs --batch -l /root/.emacs.d/init.el -l /root/permanent-cycle.el --eval '(perm-run)'"