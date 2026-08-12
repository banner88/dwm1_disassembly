#!/usr/bin/env python3
"""Differential validator for simulator/turn_order.py (S79).

Replays measure_order.py captures: for each round, takes the per-combatant
'key_roll' pre-RNG states, computes each key with turn_order.agl_key + the
action tweaks, compares against the engine's unsorted key array
('order_keys' event), then runs the literal sort and compares the final
$DB79 list ('order_out'). Exit 1 on any mismatch."""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from simulator.turn_order import (agl_key, ACT_FIRST, SQUALLHIT, PSYCHEUP,
                                  sort_order)

def finalize(key, action):
    if action == SQUALLHIT:
        key = (key + 0x0200) & 0xFFFF
    elif action == PSYCHEUP:
        key = 0
    if key < 2:
        key = 2
    if action in ACT_FIRST:
        key = (key + 0x0600) & 0xFFFF
    elif action == SQUALLHIT:
        key = (key + 0x0200) & 0xFFFF
    elif action == PSYCHEUP:
        key = 0x0001
    return key

def main(path):
    ev = json.load(open(path))
    # group into rounds: order_in, key_roll*, order_keys, order_out
    rounds, cur = [], None
    for e in ev:
        if e['tag'] == 'order_in':
            cur = {'in': e, 'rolls': []}
        elif cur is not None and e['tag'] == 'key_roll':
            cur['rolls'].append(e)
        elif cur is not None and e['tag'] == 'order_keys':
            cur['keys'] = e
        elif cur is not None and e['tag'] == 'order_out':
            cur['out'] = e
            rounds.append(cur)
            cur = None
    checks = fails = 0
    for n, r in enumerate(rounds):
        inn = r['in']
        ready = [s for s in range(8)
                 if r['in']['dd13'][s] == 2 and r['in']['pres'][s] != 1]
        # engine insertion order = slot order over ready combatants;
        # key_roll events fire once per ready combatant in that order
        if len(r['rolls']) != len(ready):
            print(f"round {n} ({inn['sc']}): {len(r['rolls'])} key_rolls "
                  f"vs {len(ready)} ready slots {ready} — grouping mismatch")
            fails += 1
            continue
        model_entries = []
        for slot, roll in zip(ready, r['rolls']):
            state = (roll['rng1'] << 8) | roll['rng2']
            agl16 = roll['agl'][slot]
            action = roll['q'][slot * 2]
            key, _ = agl_key(agl16, state)
            key = finalize(key, action)
            model_entries.append((slot, key))
        eng_keys = r['keys']['keys'][:len(ready)]
        eng_ids = r['keys']['ids'][:len(ready)]
        for i, (slot, key) in enumerate(model_entries):
            checks += 1
            if eng_ids[i] != slot or eng_keys[i] != key:
                print(f"round {n} ({inn['sc']}) entry {i}: model "
                      f"(slot {slot}, key {key:#06x}) vs engine "
                      f"(slot {eng_ids[i]}, key {eng_keys[i]:#06x}) "
                      f"agl={r['rolls'][i]['agl'][slot]} "
                      f"act={r['rolls'][i]['q'][slot*2]:#04x} "
                      f"rng={r['rolls'][i]['rng1']:#04x}"
                      f"{r['rolls'][i]['rng2']:02x}")
                fails += 1
        # the 9th pair: engine's pre-sort $DB71/$DB72 key + $DB54 id
        ninth_key = r['keys']['keys'][8]
        ninth_id = r['keys']['ids'][8]
        model_order, _ = sort_order(model_entries, ninth_key, ninth_id)
        eng_order = [x for x in r['out']['order'] if x != 0xFF]
        checks += 1
        if model_order != eng_order:
            print(f"round {n} ({inn['sc']}): order model {model_order} vs "
                  f"engine {eng_order} keys={[hex(k) for _,k in model_entries]}")
            fails += 1
    print(f"{checks} comparisons, {fails} mismatches over {len(rounds)} rounds")
    return 1 if fails else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1
                  else os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                    's79_order_events.json')))
