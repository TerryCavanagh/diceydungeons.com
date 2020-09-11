# Dicey Dungeons Mod API v1.0 migration guide

Hello Modders! v1.9 of Dicey Dungeons has increased the modding API number to v1.0. 
This will mean that if your mods are still at API v0.13.0, the game will warn players 
that the mod needs to be updated, and your mods might not work as expected.

This document is a comprehensive guide on everything you need to know to upgrade your mods from 
API v0.13.0 to API v1.0. This guide covers the complete list of changes to know about, including all of
the many new features - but don't worry! If all you're trying to do is make your old mod
compatible with the latest version, there are only a few small changes you need to make.
See the [migration wizard](https://diceydungeons.com/moddingupdate/) for a simple step by step guide!

## What does this all mean?

Now that the game is at modding api version v1.0, it means you can expect the game to
maintain compatiblity with mods from now on - even if you never update your mod again,
Dicey Dungeons should be able to load your mod in and understand how it works. Anything
that works in v1.0 will always work from now on.

However, this doesn't mean that there won't be any more updates, fixes and new features! It just means
that new features won't break any old features. (this will probably mean that there are multiple
ways to do things in future - the "old" way and the "new" way - but both will work.)

## How can I find out about future additions to the modding API?

DM me on the dicecord and ask for the "modders" role. I'll notify everyone with the role
about new modding features from time to time.

## Updating the modding API number of your mod

First up, before you do anything else: you need to update the API number of your mod. In your
mod folder, look for the `_polymod_meta.json` file. Change the `api_version` field to `1.0`.

## Changes to equipment.csv

The column `Parallel Universe` has been deleted. (See the `Expect the Unexpected` section below.)

The columns `Error Immune`, `Show Gold`, `Appears For Parts` and `Hide Reuseable` have all been deleted. A new column, Tags, replaces all four of these. (See the `Equipment Tags` section below.)

The column `Special?` has been removed. This was previously used to exclude certain items from various lists in the game, but is no longer needed as you can now exclude equipment by equipment tag instead. (the quick way to do this: just give it the tag `excludefromrandomlists`).

There is a new script column, `Script: On Dodge`. This script runs instead of the `Script: On Execute` if the enemy dodged your attack.

The column `Category` has been removed! The game mostly hasn't cared about equipment categories since the early alphas. A couple of systems use this Category for other purposes, but they have been updated on a case by case basis:
 - Finale cards for Jester used the Category `FINAL`: now they instead use the equipment tag `finale`.
 - Jester cards with the category `BACKUP` used to signify character cards with special abilities: now they instead use the equipment tag `powercard`.
 - For the final episode, the `MONSTERCARD` category signified the special cards for the episodes: now they use the equipment tag `monstercard`.
 - The game used to use Category to set the default colours for equipment. Now, if an equipment colour is not specified, it will just default to gray.
 - Val's trades used to suggest categories for trades (`weapon`, `shield`, etc). This has been simplified - the generators have changed so that she just picks random equipment instead of looking for matching categories. For example, `robot_normal.hx` used to be: `trade(["Heat Sink", "Increment", "weapon"], ["Fixed Payout", "Spatula", "Juggling Ball", "Headbutt"])` - now it's `trade(["Heat Sink", "Increment", "any"], ["Fixed Payout", "Spatula", "Juggling Ball", "Headbutt"])`.
 
## Changes to fighters.csv

There is a new column, `BossScreenPosition`, which takes two numbers in the format x|y (after `VfxOffset` and before `Dice`). This is the enemy's position if it appears as a boss. (These values used to be hardcoded, but with the addition of the Frog remix rule in v1.9, they're needed for every enemy.)

In the `Voice` column, I've moved the reference up a folder - instead of `slime`, for example, you would now write `voiceovers/slime`. This change fixes a bug with the Jester enemy, and also means it's possible to use player voices for enemies without having to duplicate the entire player chat folder (e.g. `sfx\chat\witch`). (Hi TheMysticSword!)

I've removed the `Elemental Type` column. This was never used or read in by the game. (It was part of a different elemental system I wanted to try during development, but I never got around to it.)

I've also removed the `Levelpack` column.

## Changes to statuseffects.csv

The column `External Scripts` has been deleted.

There is a new column, `Blocked by Reduce?`, which checks if a status effect should be blocked by the parallel universe version of the Reduce By status. In general, you probably want negative statuses that you inflict on the enemy to be blocked (e.g. Fire, Shock, Curse), and positive statuses that you inflict on yourself not to be blocked (e.g. Dodge, Fury, Shield), but this column lets you override that as needed.

There are several new columns for Status Effect scripts that trigger at different times when that status effect is inflicted. These scripts are:

 - When inflicted: immediately once the status effect is inflicted
 - On any status infliction: called when any other status effect is applied
 - Before start turn: At the start of a turn, before equipment is animated
 - On start turn: At the start of a turn, once equipment has been animated and everything is ready
 - On any equipment use: When any piece of equipment is used
 - On any countdown reduce: When the countdown on any piece of equipment is reduced
 - End Turn: At the end of the fighter's turn. (Includes when you win the fight!)
 - After Combat: Runs after combat (whether you win or flee). Only runs if you're inflicted when the fight ends!
 - On damage inflicted: Runs when you deal damage. `dmg` contains the amount of damage inflicted.
 - On damage taken: Runs when you take damage. `dmg` contains the amount of damage inflicted.
 - On status remove: called when the status effect is removed.
 
As well as the usual scripting variables, Status Effect scripts have access to the following:
 - self - The fighter that the status is inflicted on.
 - target - The other fighter.
 - inflicted_type - Only during `when inflicted` and `On any status infliction`, a String containing the type of the status points inflicted just now.
 - inflicted_value - Only during `when inflicted` and `On any status infliction`, an Integer containing how many points were added just now.
 - e - The piece of equipment for `any equipment use` and `any countdown reduce`. In other scripts, e is null.
 - status - The status effect object. The most important variable here is `status.value`. You shouldn't need to mess with these, but for completeness, the full list of public variables in v1.9 is:
 - flee - In After Combat scripts, true if you've fled the combat.
 - dmg - The amount of damage inflicted or taken in the On Damage scripts.

## Changes to items.csv

`items.csv` is no more! It has been renamed `skills.csv`. I've also removed the column `requirements`. For v1.9, the Inventor Steal `spacetosteal` requirement is hardcorded, but the plan is to eventually remove that completely by implementing the Steal gadget differently.

## Changes to other CSV files.

In `remix.csv`, I've removed the `Implemented` column.

I've removed the `Levelpack` column from characters.csv, dungeonstyles.csv, episodes.csv and fighters.csv. (Levelpacks were something I wanted to try for Halloween Special as a way to have mods enabled and selectively turned off without needing to reload the game, but it ended up being too big a structural change, and I think it's too late at this point to go ahead with it. It's obviously very confusing to new modders since it's an incomplete feature, so I'm just removing the column for v1.9.)
 
## Changes in behavior to be aware of

 - Fighters now have a new variable, `usecpuinsteadofdice`. Each Robot episode sets this `true` in the start script - you will also have to do this in your custom Robot episodes! (I used to do a name check for `Robot` to enable CPU instead of Dice, but this change makes it so that you can have Robot episodes without a CPU, or even have a custom character that uses a CPU that isn't named `Robot`.)

 - Fighter and Equipment `End Turn` scripts are now called if you win the battle. Previously they were only called when you actually clicked the End Turn button! If you use the End Turn scripts anywhere, you should check for unexpected behaviour that this change might cause.
 
 - There was a bug in `Rules.addextrascript("","endturn");` scripts where self and target were the wrong way around. If you worked around this by e.g. using target instead of self in one of these endturn scripts, you should check to make sure they still work correctly.
 
 - `On Start Turn` scripts now run *after* equipment status effects like weaken, shock and silence are implemented, instead of before.
 
 - In equipment scripts, `d` is set as the the total value of dice inserted. For equipment with countdowns, d is now set as the maximum value of the countdown (previously, it was zero). This also means that using `<d6>` in an equipment string will display as the max value of the countdown on countdown equipment.
 
 - The important `remixrules.hx` script has been refactored in v1.9. If you have custom remix rules, you might want to take a look at the new file and get familar with how it works now. The big changes are that most logic has now been moved into functions to make it easier to work with and follow, and some lists are trimmed when there's a match for conditional remix rules (e.g. Banshee, Marshmallow) so that they are more likely to show up.
 
 - The functions `getequipment` and `getparticularequipment` have both been removed. There is a single new function, `getequipmentlist`, that is now used instead. It takes the arguments `getequipmentlist(target:Fighter, conditions:Array<String>, excludetags:Array<String>)`. 
    - `target` can be either fighter, or null if you want to consider all equipment. 
    - `conditions` is a list of tags to match list critera - you might for example just want to get a list of `appearsforparts` to get all the scrap equipment. (A useful thing to know here is that all equipment is automatically tagged as either `large` or `small` when loaded.)
    - excludetags is a list of tags to exclude from the list - most in game functions that use this exclude `excludefromrandomlists` and `skillcard` tagged equipment, but you can exclude anything you like.

## Equipment Tags

A new column in equipment.csv, `Tags`, replaces lots of old columns and makes it possible to tag equipment as having certain properties. This is intended as a future-proof way to add features to the modding api without breaking backwards compatibility.

The columns `Error Immune`, `Show Gold`, `Appears For Parts` and `Hide Reuseable` have been removed. The new tags for these variables are:

- `Error Immune` -> `errorimmune`
- `Show Gold` -> `showgold`
- `Appears For Parts` -> `appearsforparts`
- `Hide Reuseable` -> `hidereuseable`
 
You can do combinations too, e.g. `showgold|appearsforparts`.

Equipment objects have new functions to let you check, add or remove tags: hastag(t), addtag(t), and removetag(t). You can tag things whatever you like, feel free to make up your own.

Because of this change, equipment objects no longer have the related variables `showgold`, `immunetoerrors` or `appearsforparts`. If any of your scripts change these variables, make sure you update them! e.g. `if(e.immunetoerrors)` would become `if(e.hastag(`errorimmune`))`

There are also some new possible tags:
 - `skillcard`: Marks a piece of equipment as a skillcard (e.skillcard == ~~ still works too)
 - `cannotsteal`: Marks a piece of equipment as unstealable
 - `excludefromrandomlists`: This means this equipment won't be randomly selected with skills like Slot Machine
 - `robotonly`: Only useable by the Robot (or custom characters with CPU)
 - `witchonly`: Only useable by the Witch (or custom characters with a Spellbook)
 - `finale`: Finale card for Jester
 - `shockimmune`: Immune to Shock
 - `weakenimmune`: Immune to Weaken
 - `shockattract`: Prefer to choose this equipment to shock before considering other equipment
 - `weakenattract`: Prefer to choose this equipment to weaken before considering other equipment
 - `altpoisonimmune`: Immune to Alternate Poison
 - `shockavoid`: Do not consider this card for Shock
 - `weakenavoid`: Do not consider this card for Weaken
 - `altpoisonavoid`: Do not consider this card for Alternate Poison
 - `curseavoid`: This card never triggers curse, even if the odds are set to 100%
 - `curseattract`: This card always triggers curse if inflicted, even if the odds are set to 0% (Other cards will still trigger it if they're used first, though! It's not a lightning rod.)
 - `cannotreuse`: This card cannot be reused with Re-Equip Next or Recycle (it just ignores the status effect). Fury still works - use the `On Fury` script if you want to change Fury behavior.
 
Finally, some tags are automatically applied when the game starts. This can be useful for checking certain properties with the getequipmentlist() function:
 - `large`: Size 2 equipment
 - `small`: Size 1 equipment
 - `onceperbattle`: Once per battle equipment
 - `reuseable`: Reuseable (including multi-use equipment)
 - `spell`: Witch spell

## Robot Jackpot Rewards

Robot Jackpot skills from Robot episodes 5 and 6 are now loaded from the file `scripts/diceydungeons/jackpotskills.csv`, rather than in the episodes.csv file.

## `The Robot` remix rule

`The Robot` remix rule changes the CPU counter to the You Choose, You Lose rules. This requires quite a lot of substitutions and changes to level up rewards to work! If you have any custom equipment that depends on/changes CPU values, you should append the substitions to the end of the `scripts/diceydungeons/remixes/therobot.hx` script.

## Encyclopedia

The Inventor equipment `Encyclopedia` gives the player a random gadget. The list of possible gadgets has been moved to the data file `scripts/diceydungeons/encyclopedia.txt`.

## Mimic

The Mimic enemy changes to a random piece of equipment every turn. The list of possible equipment is now loaded from the data file `scripts/diceydungeons/mysterybox.txt`.

## Expect the Unexpected

In Witch Episode 2, Expect the Unexpected, the Witch gets a random spell each turn. The way this is implemented has been changed.

The way this used to work: if Rules.witch_randomspellslot was TRUE, the game would choose a random spell from equipment.csv, choosing valid Witch spells that were marked NO under the Parallel Universe column.

The Parallel Universe column in equipment.csv has been removed. Instead, Rules.witch_randomspellslot is an array of Array<String> - each entry contains an array of strings which contains possible spells that can be randomly selected for that slot. The episode Expect the Unexpected is now implemented like this:

Rules.witch_randomspellslot[3] = loadtext(`diceydungeons/unexpectedspells`);

If you want to change or add to the list of random spells that can appear in this episode, you can append the data file `scripts/diceydungeons/unexpectedspells.txt`.

(Yes, this means that it is possible to have multiple random spellslots now! This is mostly untested and probably causes some bugs - let me know if you find anything.)

## The Frog Remix rule

The new Frog remix rule makes it possible for almost any enemy to appear as a boss. If your mod has custom enemies, you should:

 * either append `scripts/diceydungeons/remixes/frog_excludelist.txt` if you don't want your custom enemies to be considered for this rule change...
 * or append `scripts/diceydungeons/remixes/frog_hpmodifers.csv` to specify what HP your custom enemies should have if they appear as bosses.
 
Make sure you also set the correct values in the new `BossScreenPosition` column in fighters.csv, so that they appear correctly centered on the versus screen!

## Marshmallow Swaps

The Marshmallow remix rule swaps all fire themed equipment for ice equipment, and vice versa. If you have custom equipment that should be swapped, append it to `scripts/diceydungeons/remixes/marshmallow.csv`.

## Excluded Enemies

Each episode excludes some enemies from appearing. These enemies used to be listed in the `Script: Start Game` field of each episode's entry in the episodes.csv file - they have now been moved to `scripts/diceydungeons/excludedenemies.csv`. If you have custom enemies that need to be excluded from certain episodes, you can append their names to this file.

## Initial Equipment

In bonus round episodes, you can choose your initial equipment at the start of the episode, and you will get offered different equipment when you level up that depends on what you've selected. These lists are now loaded from `scripts/diceydungeons/initialequipment/(character name).csv`.

`DoubleEquipment` rewards previously used commas to seperate the list (e.g. `DoubleEquipment:Boxing Gloves,Boxing Gloves`). They now use the pipe symbol | so that they can be loaded from this csv file. (e.g. `DoubleEquipment:Boxing Gloves|Boxing Gloves`).

The available columns for each character differ depending on how their level up rewards are designed: 

For Warrior, Thief and Inventor, level up rewards are in three columns - `init`, offered at the start of the run, `rewards1`, offered at level 2, and `rewards2`, offered at level 4. 

Robot, however, has seperate `rewards2_sink` and `rewards2_inc` columns, and is always offered a random element from each column at level 4.

Witch has `rewards1_common` and `rewards1_rare` columns: her level 2 reward takes a single element from reward1_rare and shuffles it in with rewards1_common, and offers two spells from the final list.

Jester has their own thing going on with bonus round level up rewards - see the `Jester level up rewards` section below for details on that. Their initial equipment (Finale Card selection) is loaded from the text file `scripts/diceydungeons/initialequipment/jester.txt`.

## Jester level up rewards

Booster pack selections for Jester level up rewards are now loaded from the files `packs_normal.txt`, `packs_paralleluniverse.txt` and `packs_bonusround.txt` in the `scripts/diceydungeons/jesterpacks/` folder.

In Jester episodes, the dungeons changes based on what level up pack the player chooses. The script `scripts/diceydungeons/jesterpacks/dungeonchanges.hx` now controls these changes - simply append a check for your custom booster packs at the end of this file. `Backfire` is the proxy item for the level 2 shop item, and `Bop,Bop,Bop` is the proxy for the level 4 booster collectable. (In a previous version of Dicey Dungeons, `Flaming Sword` and `Blammo,Blammo,Blammo` were used as the proxy items in some episodes - this is no longer the case, Backfire and Bop are now used everywhere.)

## Flexible generators

Thanks to a big contribution by Jackeea and ncrecc, you can now add things to the itempools for various generators without modifying the generators themselves! This is great news if your mod is mainly about adding new equipment to the game.

Here are Jackeea's notes on the new feature:

Huge thanks to ncrecc/Wisp for starting off the framework for this! Makes things a bit more complicated, but much more moddable this way.

Each generator has a few files:
* The generator file itself - e.g. warrior_normal.hx. This is an ordinary generator, except all of the items have been stripped out. It includes a call to an external script, flexible_generator.hx, with some arguments - this script then returns all the items for the episode, loading from other mods.
* An "itempools" folder - scripts/diceydungeons/itempools/[generator name]/vanilla.hx. This contains all the item pools for that episode, in the correct format. This data is loaded into the generator, along with any modded item pools.
* Any other mods can add their own item pool list - you just create a file in the same place as vanilla.hx, except with the name of your mod (or some other internal identifier). Then, you append your mod's name to scripts/diceydungeons/itempools/[generator name]/scriptstorun.txt, which are loaded when the generator is.

This flexible way of loading generators allows users to have greater control over which items generate when, by letting them add their own scripts which return lists of items to append to each list inside the generator. Larger generator changes will still necessitate a whole overwrite, but this setup should be flexible enough.
