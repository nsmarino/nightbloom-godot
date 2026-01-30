# Combat Gameplay Summary

This document contains a message I sent to my collaborator, summarizing what I envision for the combat system we are developing. It does not reference implementation details but instead provides an overview of what I want the system to include, along with my hopes and concerns. It should be used as an aid when implementing gameplay features.

# Message

"OK, here is an overview of the combat prototype I am building. I’m not too attached to it and in fact I’m very skeptical it will come together, but this endeavor is much more about seeing it through to completion both in terms of technical execution and mental discipline.

- Combat is initialized by bumping into an enemy character in the overworld; typical JRPG trope of getting a slight advantage if you bump into their back instead of their front
- When you transition to the arena, the enemy group (between 1 and 5 enemies) spawns in front of you
- One party member (the one you were navigating overworld with) stands in the arena, while the other party members stand on the sidelines
- Player and enemy group now take turns. There’s a timer that counts down during each turn, let’s say each turn is about 15 seconds for now

- PLAYER TURN STARTS
Active party member can walk toward any enemy (enemies are moving to and fro in slow motion) and perform a melee attack. This isn’t a hack and slash thing, it’s a more slow, stylized THWAP with fun particle and sound effects, maybe some camera movement. 
Melee attacks build up an Action Bar that can be used for Spells and Items. 
During the player turn, they can also swap out to a different party member who has a different movespeed, a different weapon, and different Spells (I have not yet decided/determined if swapping should cost action points)

- ENEMY TURN STARTS
Now it is the player who moves in slow motion, you can still move around but at an extremely slow pace, mostly just to feel a little dynamic
During the enemy turn, the enemies can attack one by one by running up to you and doing a melee attack
I have a lot of other ideas for what enemies can do during their turn but keeping it simple for now
[Possible feature] Player can press or hold a button to GUARD during enemy turn, which drains Action Points

- HOW DAMAGE WORKS
One of the core ideas of this combat system, i.e. one of the possibly-forced-feeling novelties, is that both the enemy group and the player party share a single health bar. 
This makes sense for the player side, since you’re constantly switching between party members, but it is surprising at first when applied to the enemy side, since it’s unusual to not be able to pick off enemies one by one.
Along with HEALTH POINTS, MANA POINTS (for spells) and ACTION POINTS (earned through melee to use spells and items) there is another resource, STAGGER POINTS (yes, sorry, there’s a stagger system, this is why I wanted you to play FF7 Rebirth bc as you’re now seeing this is unfortunately a riff on that)
Each individual enemy and individual party member has their own stagger bar, which is raised when receiving damage (melee or spells) and when casting spells. 
Also, if you attack too late in your turn and your attack animation is still going when the attack ends, you become OFF BALANCE! and receive more stagger damage during the enemy turn
Different elemental spells (Fire, Water, etc.) or different actions (leaving vague) can put an individual party member or enemy into a PRESSURED! state where their stagger bar fills more rapidly and drains more slowly (if at all)
When an individual is STAGGERED! they are stunned and unable to attack or move. There’s no damage multiplier for staggered individuals at this time.
If a party member is staggered, you can switch party members but that party member can’t do anything until they leave the staggered state
If you’re able to stagger all the enemies on the field, a MASSIVE damage multiplier is applied and you can wail on any enemy to do big numbers

- GAMEPLAY NOTES
There’s absolutely no EVASION or DODGE ROLLING or PARRYING
Im excited about being able to guard during enemy turns but haven’t implemented it yet


Current party loadout (no idea if this should be fixed the entire game or what degree of customization would be possible):
- Elena - Big hammer that does chunks of HP damage, Earth elemental spells
- Asa - staff that does AOE attacks with balanced HP and stagger damage, Fire elemental spells
- Granley - demolition kit, plants attractor mines that draw different enemies toward them to keep them clumped and explode for modest amounts of damage, Water elemental spells (so also the healer since his weapon is the silliest)
- June - whip (i know, it’s scary) that has a longer range than Elena’s hammer but pretty much just does stagger damage, moves slowest?, Air elemental spells"
