"""compiler.py — orchestrator: project.json → generated files + spliced regions.

Pipeline (PROJECT_COMPILER.md §pipeline):
  1. Project.load → schema resolution (hard-errors on unimplemented layers)
  2. validators.validate → errors abort, warnings reported
  3. every REGISTRY emitter runs → {target: text}
  4. region targets are spliced into copies of their base patch files
     between `; @BUILD_PROJECT BEGIN <name>` / `; @BUILD_PROJECT END <name>`
     marker lines (markers stay in the output so re-runs are idempotent)
  5. determinism check: the whole emit runs twice; byte-diff must be empty
  6. outputs written under <out>/patches/…

The compiler only ever ADDS to the existing patch overlay: whole-file
targets are the two content banks it owns ($60/$71); everything else is a
marked region inside a file that otherwise stays exactly as hand-authored.
Hand-authoring remains fully available (design commitment S53).
"""

import hashlib
import json
import os
import re

from . import emitters
from .project import Project
from . import validators

MARK_BEGIN = "; @BUILD_PROJECT BEGIN {name}"
MARK_END = "; @BUILD_PROJECT END {name}"


class CompileError(RuntimeError):
    pass


def _emit_all(prj):
    warnings = []
    out = {}
    for name, section, target, fn, banks in emitters.REGISTRY:
        out[target] = fn(prj, warnings)
    return out, warnings


def splice(base_text, name, new_content):
    b = MARK_BEGIN.format(name=name)
    e = MARK_END.format(name=name)
    lines = base_text.splitlines()
    try:
        bi = lines.index(b)
        ei = lines.index(e)
    except ValueError:
        raise CompileError(
            f"marker pair for region '{name}' not found in base file — "
            "the @BUILD_PROJECT markers are byte-neutral comments added "
            "S53; restore them (PROJECT_COMPILER.md §regions)")
    if ei < bi:
        raise CompileError(f"region '{name}': END before BEGIN")
    if b in lines[bi + 1:] or e in lines[ei + 1:]:
        raise CompileError(f"region '{name}': duplicate markers")
    new_lines = new_content.rstrip('\n').split('\n') if new_content else []
    return "\n".join(lines[:bi + 1] + new_lines + lines[ei:]) + "\n"


def compile_project(project_path, repo_root):
    """Returns (outputs {relpath: text}, prj, warnings)."""
    prj = Project.load(project_path)

    # content validation BEFORE emit: schema errors surface as validation
    errors, warnings = validators.validate(prj)
    if errors:
        raise CompileError(
            "validation failed:\n  - " + "\n  - ".join(errors))

    gen1, w1 = _emit_all(prj)
    gen2, _ = _emit_all(prj)
    if gen1 != gen2:
        bad = [t for t in gen1 if gen1[t] != gen2.get(t)]
        raise CompileError(
            f"NON-DETERMINISTIC emit for {bad} — same project must produce "
            "identical bytes (EDITOR_DESIGN §6: determinism is what makes "
            "bisection meaningful)")

    # post-emit: bank-space accounting on the generated text
    aerr, awarn = validators.validate(prj, generated=gen1)
    warnings = warnings + w1 + awarn
    if aerr:
        raise CompileError(
            "validation failed:\n  - " + "\n  - ".join(aerr))

    outputs = {}
    region_bases = {}
    for target, text in gen1.items():
        kind, rest = target.split(':', 1)
        if kind == 'file':
            outputs[rest] = text
        else:
            fname, region = rest.split('#', 1)
            region_bases.setdefault(fname, []).append((region, text))
    for fname, regions in region_bases.items():
        base = open(os.path.join(repo_root, fname)).read()
        for region, text in sorted(regions):
            base = splice(base, region, text)
        outputs[fname] = base

    return outputs, prj, warnings


def content_hash(project_path):
    if os.path.isdir(project_path):
        project_path = os.path.join(project_path, 'project.json')
    return hashlib.sha256(open(project_path, 'rb').read()).hexdigest()


def write_outputs(outputs, out_dir):
    written = []
    for rel, text in sorted(outputs.items()):
        dst = os.path.join(out_dir, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'w') as f:
            f.write(text)
        written.append(dst)
    return written


def pin_templates():
    """Record sha256 of the engine template heads (run after the first
    successful regression build; refuses silently-drifted engine code)."""
    import glob
    lines = []
    for p in sorted(glob.glob(os.path.join(emitters.TEMPLATES, '*.asm'))):
        h = hashlib.sha256(open(p, 'rb').read()).hexdigest()
        lines.append(f"{h}  {os.path.basename(p)}")
    with open(emitters.TEMPLATE_SHA_FILE, 'w') as f:
        f.write("\n".join(lines) + "\n")
    return lines
