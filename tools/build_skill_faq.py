#!/usr/bin/env python3
"""Generate extracted/skill_faq.json from the categorized community skill FAQ.

This is EXTERNAL ground-truth data (user-provided community FAQ, transcribed), NOT
ROM-derived — hence `_source` rather than `_generator`. It carries the per-skill
EFFECT description + effect CLASS + learn requirements + prereqs that are not present
in extracted/skill_records.json. Two consumers:
  * tools/decode_effect_messages.py --validate  (cross-checks decoded battle messages
    against each skill's FAQ class -> expected message type)
  * S2d (per-id custom-skill records) needs effect/learn/prereq text.

The FAQ rows are embedded below as the single source; edit here and re-run to update.
Row format:  Name | MP | Effect | Class | Type | Range | <learn> [| preq A,B,...]
<learn> tokens: Lnn (level), HPnn, MPnn, ATKnn, DEFnn, AGLnn, INTnn.

Usage: python3 tools/build_skill_faq.py    ->  writes extracted/skill_faq.json
"""
import json, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "extracted", "skill_faq.json")

FAQ = r"""
## Healing Spells
Antidote   | 2 | Cures poison to one ally          | Healing | Spell | 1 Ally     | L5  Int20
CurseOff   | 2 | Cures Curse to one ally           | Healing | Spell | 1 Ally     | L7  Int24
DeChaos    | 2 | Cures confusion to one ally       | Healing | Spell | 1 Ally     | L6  Int22
NumbOff    | 2 | Cures paralysis/wakes all allies  | Healing | Spell | All Allies | L8  Int78
Surge      | 7 | Cures all status + stat decreases | Healing | -     | All Allies | L23 Int170 | preq Antidote,CurseOff,DeChaos,NumbOff

## Recovery Spells
Heal       | 2  | Heals 30-40 HP one ally    | Recovery | Spell | 1 Ally     | L1  Int6
HealMore   | 5  | Heals 75-90 HP one ally    | Recovery | Spell | 1 Ally     | L10 Int48
HealAll    | 7  | Heals all HP one ally      | Recovery | Spell | 1 Ally     | L16 Int80
HealUs     | 18 | Heals 90-120 HP all allies | Recovery | Spell | All Allies | L20 Int120
HealUsAll  | 36 | Heals all HP all allies    | Recovery | Spell | All Allies | L28 Int160

## Revival
Vivify   | 10  | Revive one ally at half HP (50%) | Revive   | Spell | 1 Ally     | L14 Int54
Revive   | 20  | Revive one ally full HP          | Revive   | Spell | 1 Ally     | L27 Int152
Farewell | All | Revive all; caster dies          | Recovery | Spell | All Allies | L32 Int176 | preq Sacrifice,Revive
LifeSong | 20  | Revive all (2 turns, can fail)   | Revive   | -     | All Allies | L27 Int162 | preq Revive,WarCry

## Defense
Upper     | 2  | +50% defence one ally          | Defense | Spell  | 1 Ally     | L2  Int12
Increase  | 3  | +50% defence all allies        | Defense | Spell  | All Allies | L6  Int12
SuckAll   | 2  | Sucks attacks at one ally 1 turn| Defense | Breath | Self       | L13
Cover     | 2  | Takes attack against one ally  | Defense | -      | Self       | L5
Guardian  | 4  | Takes all attacks one turn     | Defense | -      | Self       | L12
BladeD    | 3  | Halve physical dmg + reflect 50%| Defense | -     | Self       | L14
MagicWall | 3  | +resistance vs foes' skills    | Defense | Spell  | All Allies | L19 Int74
MagicBack | 4  | Reflect a skill once to foes   | Defense | Spell  | Self       | L16 Int62
Bounce    | 4  | Reflect spells back            | Defense | Spell  | Self       | L20 Int68
Barrier   | 3  | -50% Fire/Ice breath dmg       | Defense | Spell  | All Allies | L18 Int70
TailWind  | 6  | Reflect breath to one foe      | Defense | -      | Self       | L11
StormWind | 10 | Reflect breath to all foes     | Defense | -      | All Allies | L19
Dodge     | 4  | Redirect a physical attack     | Defense | -      | Self       | L18
Ironize   | 2  | All allies invulnerable 3 turns| Defense | Spell  | All Allies | L15 Int21
StrongD   | 3  | -90% all damage this turn      | Defense | -      | Self       | L14

## Support
BeDragon | 9  | Become dragon (SnowStorm/Scorching/DeMagic) | Support | Spell | Self  | L28 Int160
Chance   | 20 | Random effect (good or bad)                 | Support | Spell | Random| L40 Int236
DeMagic  | 7  | Dispel Upper/Speed/Barrier/MagicWall        | Support | -     | All Foes | L20 Int140 | preq Surge,UltraDown
Focus    | 0  | Two attacks next turn                       | Support | -     | Self  | L18 | preq ChargeUP,SuckAir,Meditate
HighJump | 5  | Jump, attack next turn +atk                 | Support | -     | Self  | L20
Imitate  | 4  | Copy+return every skill cast on you 1 turn  | Support | -     | Self  | L21 | preq Transform,Focus
PsycheUp | 3  | Greater normal-attack dmg next turn         | Support | -     | Self  | L12
Speed    | 2  | +50% agility one ally                       | Support | Spell | 1 Ally| L1  Int8
SpeedUp  | 3  | +50% agility all allies                     | Support | Spell | All Allies | L5 Int20
ThickFog | 8  | Suspend everyone's skills one round         | Support | -     | All Foes | L22 Int160
TwinHits | 2  | +physical attack damage                     | Support | Spell | 1 Ally| L17 Int66

## Dance
DanceShut | 6 | Suspend all foes' Dance attacks       | Dance Trap | Dance | All Foes | L16
SideStep  | 1 | +dodge chance                         | Defense    | Dance | Self     | L9
Hustle    | 12| Heals 70-80 HP all allies             | Recovery   | Dance | Self     | L18 | preq HealAll,SideStep
LifeDance | 1 | Revive all; caster dies               | Recovery   | Dance | All Allies | L30 | preq Hustle,Sacrifice
OddDance  | 0 | Lower one foe MP (level based)        | OddDance   | Dance | 1 Foe    | L10
RobDance  | 2 | Steal foe MP (caster Lvl)             | OddDance   | Dance | 1 Foe    | L12
K.O.Dance | 6 | Instant death all foes                | Beat       | Dance | All Foes | L20
Meditate  | 8 | Heal 500 HP to caster                 | Recovery   | Dance | -        | L26 | preq Guardian,StrongD
PaniDance | 4 | Confuse/paralyze all foes             | Panic      | Dance | All Foes | L13
LureDance | 2 | Stop all foes one turn                | Lose a Turn| Dance | 1 Foe    | L14

## Attack (physical)
BiAttack  | 3  | Attack twice 75% str          | Attack | -  | 1 Foe   | L19
QuadHits  | 6  | Attack 4 times random foes    | Attack | -  | All Foes| L24
SquallHit | 2  | Attack first this turn        | Attack | -  | 1 Foe   | L12
RainSlash | 5  | Physical attack all foes      | Attack | -  | All Foes| L15 | preq BiAttack,SquallHit
ChargeUP  | 0  | Additional damage next turn   | Support| -  | Self    | L14
BoltSlash | 3  | Attack by Lightning resist    | Bolt   | -  | 1 Foe   | L11 | preq ChargeUp,Lightning
FireSlash | 3  | Attack by Fire resist         | Blaze  | -  | 1 Foe   | L11 | preq Blazemore,ChargeUP
VacuSlash | 3  | Attack by Air resist          | Infernos|- | 1 Foe   | L11 | preq ChargeUp,WindBeast
IceSlash  | 3  | Attack by Ice resist          | IceBolt| -  | All Foes| L11 | preq ChargeUP,SnowStorm
GigaSlash | 20 | 350-410 dmg one foe           | GigaSlash|-| 1 Foe   | L33 | preq FireSlash,BoltSlash,VacuSlash,IceSlash
NapAttack | 2  | Attack + sleep                | Sleep  | -  | 1 Foe   | L7
PoisonHit | 2  | Attack + poison               | Poison | -  | 1 Foe   | L5
Paralyze  | 3  | Attack + paralyze             | Paralysis|-| 1 Foe   | L9  | preq PoisonHit,NapAttack
Smashlime | 3  | +50% vs SLIME                 | Attack | -  | 1 Foe   | L12
DrakSlash | 3  | +50% vs DRAGON                | Attack | -  | 1 Foe   | L12
BeastCut  | 3  | +50% vs BEAST                 | Attack | -  | 1 Foe   | L12
BirdBlow  | 3  | +50% vs BIRD                  | Attack | -  | 1 Foe   | L12
Branching | 3  | +50% vs PLANT                 | Attack | -  | 1 Foe   | L12
BugBlow   | 3  | +50% vs BUG                   | Attack | -  | 1 Foe   | L12
DevilCut  | 3  | +50% vs DEVIL                 | Attack | -  | 1 Foe   | L12
CleanCut  | 3  | +50% vs MATERIAL              | Attack | -  | 1 Foe   | L12
MetalCut  | 3  | +50% vs metal monsters        | Attack | -  | 1 Foe   | L12
ZombieCut | 3  | +50% vs ZOMBIE                | Attack | -  | 1 Foe   | L12
MultiCut  | 20 | 180-210 dmg all foes          | Infernos|-| All Foes| L28 | preq ZombieCut,Vacuum
Beserker  | 1  | Attack +dmg, def 0            | Attack | -  | 1 Foe   | L14
EvilSlash | 3  | 95-105% atk, 3/8 prob         | Attack | -  | 1 Foe   | L15
Massacre  | 3  | 95-105% atk random target     | Attack | -  | 1 Foe/Ally | L12
TwinSlash | 2  | Physical dmg + self wound     | Attack | -  | 1 Foe   | L8

## Offensive Spells
StopSpell | 3  | Suspend all foes' magic       | StopSpell| Spell | All Foes | L9  Int38
Blaze     | 2  | 12-15 Fire dmg one foe        | Blaze   | Spell | 1 Foe    | L1  Int20
Blazemore | 4  | 70-90 Fire dmg one foe        | Blaze   | Spell | 1 Foe    | L13 Int64
Blazemost | 10 | 180-200 Fire dmg one foe      | Blaze   | Spell | 1 Foe    | L28 Int146
IceBolt   | 3  | 25-35 Ice dmg all foes        | IceBolt | Spell | All Foes | L5  Int30
SnowStorm | 5  | 42-58 Ice dmg all foes        | IceBolt | Spell | All Foes | L12 Int60
Blizzard  | 12 | 80-104 Ice dmg all foes       | IceBolt | Spell | All Foes | L25 Int110
Bang      | 5  | 20-30 Explosion dmg all foes  | Bang    | Spell | All Foes | L4  Int26
Boom      | 8  | 52-68 Explosion dmg all foes  | Bang    | Spell | All Foes | L14 Int68
Explodet  | 15 | 130-140 Explosion dmg all     | Bang    | Spell | All Foes | L29 Int158
Firebal   | 4  | 16-24 Fire dmg all foes       | Fireball| Spell | All Foes | L3  Int23
Firebane  | 6  | 30-42 Fire dmg all foes       | Fireball| Spell | All Foes | L10 Int52
Firebolt  | 10 | 88-112 Fire dmg all foes      | Fireball| Spell | All Foes | L26 Int122
Infernos  | 2  | 8-24 Air dmg all foes         | Infernos| Spell | All Foes | L2  Int21
Infermore | 4  | 25-55 Air dmg all foes        | Infernos| Spell | All Foes | L11 Int56
Infermost | 8  | 80-180 Air dmg all foes       | Infernos| Spell | All Foes | L27 Int134
MegaMagic | All| Highest dmg all foes          | MegaMagic|-     | 1 Foe    | L38 Int224 | preq Blazemost,Blizzard,Explodet,FireBolt,Infermost
Bolt      | 5  | 35-50 Lightning dmg all foes  | Bolt    | Spell | All Foes | L6  Int35
Zap       | 10 | 70-90 Lightning dmg all foes  | Bolt    | Spell | All Foes | L15 Int72
Thordain  | 15 | 175-225 Lightning dmg all     | Bolt    | Spell | All Foes | L30 Int174
Lightning | 3  | 40-60 Lightning dmg all foes  | Bolt    | -     | All Foes | L10
HellBlast | 25 | 210-290 Lightning dmg all     | Bolt    | -     | All Foes | L34 | preq Thordain,Lightning
Beat      | 4  | Instant death one foe         | Beat    | Spell | 1 Foe    | L16 Int76
Defeat    | 7  | Instant death all foes        | Beat    | Spell | All Foes | L24 Int98
Ramming   | 1  | -50% foe HP, hurts caster     | Sacrifice| Spell| 1 Foe    | L12
Sacrifice | 1  | Instant death all foes+caster | Sacrifice| Spell| All Foes | L1  Int6
WindBeast | 3  | Air dmg one foe (level based) | Infernos| -     | 1 Foe    | L13
Vacuum    | 6  | Air dmg all foes (level based)| Infernos| -     | All Foes | L19

## Breath
MouthShut | 6  | Suspend one foe's breath      | Breath Seal| -    | 1 Foe   | L17
FireAir   | 2  | 14-22 Fire dmg all foes       | Flame   | Breath | All Foes | L3
BlazeAir  | 4  | 32-48 Fire dmg all foes       | Flame   | Breath | All Foes | L10
Scorching | 8  | 75-100 Fire dmg all foes      | Flame   | Breath | All Foes | L20
WhiteFire | 16 | 150-170 Fire dmg all foes     | Flame   | Breath | All Foes | L30
FrigidAir | 2  | 16-24 Ice dmg all foes        | Blizzard| Breath | All Foes | L3
IceAir    | 4  | 42-54 Ice dmg all foes        | Blizzard| Breath | All Foes | L10
IceStorm  | 8  | 82-112 Ice dmg all foes       | Blizzard| Breath | All Foes | L20
WhiteAir  | 16 | 160-180 Ice dmg all foes      | Blizzard| Breath | All Foes | L30
BigBang   | 30 | 300-400 Explosion dmg all     | Blaze   | -      | All Foes | L36 | preq Explodet,WhiteFire,WhiteAir
PoisonGas | 3  | Poison all foes (breath)      | Poison  | Breath | All Foes | L9
PoisonAir | 4  | Poison all foes (breath)      | Poison  | Breath | All Foes | L14
SleepAir  | 3  | Sleep all foes                | Sleep   | Breath | All Foes | L10
PalsyAir  | 4  | Paralyze all foes (breath)    | Paralysis| Breath| All Foes | L16 | preq SleepAir,PoisonAir
SuckAir   | 0  | +breath dmg next turn         | Support | Breath | Self     | L17

## Status Effect
LushLicks | 2 | Stop one foe one turn               | Lose a Turn| -    | 1 Foe   | L7
SickLick  | 4 | Stop + def to 1 one foe one turn    | Sap        | -    | 1 Foe   | L13
LegSweep  | 1 | Trip one foe (flyers immune)        | Lose a Turn| -    | 1 Foe   | L6
BigTrip   | 3 | Trip all foes (flyers immune)       | Lose a Turn| -    | All Foes| L12
WarCry    | 3 | Freeze all foes one turn (roar)     | Lose a Turn| -    | All Foes| L14
Sleep     | 3 | Sleep one foe                       | Sleep      | Spell| 1 Foe   | L4  Int16
SleepAll  | 5 | Sleep all foes                      | Sleep      | Spell| All Foes| L11 Int46
PanicAll  | 5 | Confuse all foes                    | Panic      | Spell| All Foes| L12 Int49
Curse     | 3 | Curse all foes (random)             | Curse      | -    | All Foes| L15
Radiant   | 2 | -physical hit chance all foes       | Surround   | -    | All Foes| L12
EerieLite | 2 | -magic resist all foes              | Beat       | -    | All Foes| L14 | preq Curse,Radiant
RobMagic  | 0 | Steal one foe's MP                  | OddDance   | Spell| 1 Foe   | L7
TakeMagic | 2 | Absorb MP of one spell foe casts    | Support    | Spell| Self    | L13
SandStorm | 2 | -hit chance all foes                | Surround   | -    | All Foes| L10
Surround  | 3 | -hit chance all foes                | Surround   | -    | All Foes| L10 Int41
Slow      | 3 | -50% agility one foe                | Slow       | Spell| 1 Foe   | L3  Int16
SlowAll   | 4 | -50% agility all foes               | Slow       | Spell| All Foes| L7  Int28
UltraDown | 7 | Sap+Slow+Surround one foe           | Beat       | -    | 1 Foe   | L21 | preq Surround,Defence,SlowAll
Sap       | 3 | -50% defense one foe                | Sap        | Spell| 1 Foe   | L4  Int15
Defence   | 4 | -50% defense all foes               | Sap        | Spell| All Foes| L8  Int32

## Misc / Allied / Summon
Ahh       | 1/2| Female foe: stop; Male foe: dmg    | Lose a Turn| -   | 1 Foe | L10
CallHelp  | 4  | Call allies (level dmg)            | Allied  | -      | 1 Foe | L17
YellHelp  | 8  | Call allies (level dmg)            | Allied  | -      | 1 Foe | L23
RockThrow | 5  | 75-100 dmg all foes (rocks)        | Allied  | -      | All Foes | L16
TatsuCall | 20 | Summon Tatsu                       | Summons | -      | -     | L20
DiagoCall | 20 | Summon Diago                       | Summons | -      | -     | L26
SamsiCall | 20 | Summon Samsi                       | Summons | -      | -     | L30
BazooCall | 20 | Summon Bazoo                       | Summons | -      | -     | L35
Transform | 5  | Copy foe's skills+stats            | Support | Spell  | Self  | L21
Kamikaze  | 1  | Foe HP to 1, caster HP to 1        | Sacrifice| -     | 1 Foe | L18 | preq ChargeUP,Ramming

## Map
MapMagic  | 2 | Reveal current gate level map  | Support | Spell | - | L10
StepGuard | 2 | No lava/swamp/barrier dmg 1 lvl| Support | Spell | - | L10
Whistle   | 0 | Summon gate monsters to fight  | Support | -     | - | L4
"""

LEARN_KEYS = {"L": "level", "HP": "hp", "MP": "mp", "ATK": "atk",
              "DEF": "def", "AGL": "agl", "INT": "int"}

def parse_learn(tok_str):
    out = {}
    for m in re.finditer(r"(L|HP|MP|ATK|DEF|AGL|INT)(\d+)", tok_str, re.I):
        out[LEARN_KEYS[m.group(1).upper()]] = int(m.group(2))
    return out

def build():
    skills = {}
    category = None
    for raw in FAQ.splitlines():
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.startswith("## "):
            category = line[3:].strip()
            continue
        if "|" not in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        name = parts[0]
        rec = {"category": category,
               "mp": parts[1] if len(parts) > 1 else "",
               "effect": parts[2] if len(parts) > 2 else "",
               "class": parts[3] if len(parts) > 3 else "",
               "type": parts[4] if len(parts) > 4 else "",
               "range": parts[5] if len(parts) > 5 else ""}
        learn, prereqs = {}, []
        for extra in parts[6:]:
            if extra.lower().startswith("preq"):
                prereqs = [s.strip() for s in extra[4:].strip().split(",") if s.strip()]
            else:
                learn.update(parse_learn(extra))
        rec["learn"] = learn
        rec["prereqs"] = prereqs
        skills[name] = rec
    return {
        "_source": "external community skill FAQ (user-provided 2026-06-28), transcribed",
        "_note": "NOT ROM-derived. Effect/class/learn/prereq reference for S2c validation "
                 "and S2d. Effect CLASS maps to the message selector in "
                 "BATTLE_SKILL_SYSTEM.md S9. Regenerate: python3 tools/build_skill_faq.py",
        "n_skills": len(skills),
        "skills": skills,
    }

if __name__ == "__main__":
    data = build()
    json.dump(data, open(OUT, "w"), indent=2)
    print(f"wrote {OUT}  ({data['n_skills']} skills)")
