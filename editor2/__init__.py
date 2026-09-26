"""editor2 — headless project compiler for the DWM1 editor.

See documentation/PROJECT_COMPILER.md (schema + pipeline reference) and
EDITOR_DESIGN.md (architecture). project.json is the source of truth; the
generated .asm files are build artifacts layered onto patches/.
"""

# Bumped every delivery that changes editor code, and printed in the build log
# when a project opens — so a stale or half-applied checkout is visible at a
# glance (KEY_LESSONS S95 "old data + new code"; S96 round 3: a delivery
# rsync'd without its trailing slash landed in a subfolder).
EDITOR_REVISION = 'S98r3'
