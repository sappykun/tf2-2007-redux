# TF2007 Project - Redux

A very, very, very heavily modified version of Drixevel's [TF2-2007 project](https://github.com/Drixevel-Archive/TF2-2007).

This is a suite of Sourcemod plugins that try to simulate TF2 1.0.0.9 (the version released on October 11, 2007), as well as a couple of others that I made. 

## PLUGINS

### tf2-2007-redux.sp

- Weapon stats
- Modified weapon mechanics (semi-auto Pistol, indestructable stickybombs, etc)

### tf2-2007-medigun.sp

- Medigun-specific modifications
- Disables flashing penalty and uber drain when holstered

### tf2-2007-falldamage.sp

- Play the old fall damage sounds when a player takes fall damage and attempts to vocalize

### tf2-2007-ragdolls.sp

- Disables player animations on headshot and backstab

### tf2-2007-weapondrops.sp

- Disables weapon drops
- Reskins the dropped ammo box into the weapon the player was holding when they died

### nominviewmodels.sp

- Disables minimized viewmodels across clients
- **Can potentially crash clients if applied to non-stock weapons. Usage without stockonly.sp or an item whitelist is not recommended.**

### voicespampatch.sp

- Disables the voice anti-spam features Valve added to the game in 2018
- Not an unlimited voice spam plugin

## DEPENDENCIES

[TF2Items](https://forums.alliedmods.net/showthread.php?t=115100)

[TF2Attributes](https://github.com/FlaminSarge/tf2attributes)

## RECOMMENDED

stockonly.sp and stockonly.txt from [Mikusch's misc plugins repoo](https://github.com/Mikusch/tf2-misc/tree/master)

[tf-bhop](https://github.com/Mikusch/tf-bhop) (optional)

## TODO - FEATURES

- Increase level 2/3 sentry resistance to minigun damage (15% to 20% and 20% to 33%)
- Decrease wrench construction speed by 33% (150% -> 100%). Buildings should be built 25% slower (2.5 -> 2.0)
- Reduce building repair costs to 20 metal (from 33), 5 HP per metal from 3
- Undo Spy reduced debuff timer when cloaked
- Remove damage/accuracy rampup on minigun
- Restore Spy disguise time when already disguised (make it 2 seconds, it's 0.5s now)
- Change sentry bullet damage to use engineer's position, not sentry
- Disable loser stun state when a round is won (this one is proving to be very tricky)

## TODO - BUGS

- Pistol fire rate doesn't always sync with client, causing silent shots and non-responsive fire rates.
- Medic's regen rate should be nerfed properly, starting at 1 HP/s and ramping up to 3 HP/s. Right now it uses the Blutsauger attribute which isn't very accurate.
