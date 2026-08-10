"""DWM1 combat simulator package (S78+).

damage.py          exact damage model (traced + differentially validated)
validate_damage.py replay captured emulator events through the model
measure_rig.py     PyBoy capture rig for generating new event corpora
s78_master_events.json  the S78 validation corpus (698 checks, 0 mismatch)

Turn order, AI move selection, and status-effect application are the next
arc (S79+); see documentation/ROADMAP.md.
"""
