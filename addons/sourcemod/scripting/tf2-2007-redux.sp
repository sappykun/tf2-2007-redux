/*
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <dhooks>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0.0"
#define PLUGIN_DESCRIPTION "Simulates weapon stats/mechanics from TF2 1.0.0.9."

#define TF_MAX_SLOTS 6
#define MELEE_FORCE 23999.0

Handle dhook_CBaseEntity_CanBeUpgraded;
Handle dhook_CTFPlayer_CanPickupBuilding;

ConVar convar_tf_damagescale_self_soldier;
ConVar convar_tf_pipebomb_force_to_move;

ConVar convar_DisableTaunts;
ConVar convar_DisableMoveBuildings;
ConVar convar_DisableAirblasts;
ConVar convar_FixedMedicSpeed;
ConVar convar_FixedSpySpeed;
ConVar convar_BuildingLevels;
ConVar convar_LegacyPistol;
ConVar convar_GodPipes;
ConVar convar_DisableTauntKills;
ConVar convar_DisableInspection;
ConVar convar_LowerWeaponSwitching;
ConVar convar_IncreaseSoldierAmmoReserve;
ConVar convar_IncreaseDemoAmmoReserve;
ConVar convar_IncreaseDemoClipSize;
ConVar convar_DecreaseSoldierExplosionRadius;
ConVar convar_IncreaseDemoExplosionRadius;
ConVar convar_IncreaseTeleporterCost;
ConVar convar_BuffSoldierSelfDamage;
ConVar convar_SlowerHeavyRev;
ConVar convar_NoCloakFillFromAmmo;
ConVar convar_NoCloakDamageResistance;
ConVar convar_NerfMedicHealthRegen;
ConVar convar_RemoveDemoSelfDamageOnDirectHit;
ConVar convar_NerfSpyShootingSappedBuildings;
ConVar convar_NoDetonateStickiesWhileTaunting;
ConVar convar_DisableIntelGlows;

int g_iLastDirectHitPipe = -1;

public Plugin myinfo = 
{
	name = "TF2007 Project Redux", 
	author = "Keith Warren (Drixevel), Sappykun", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://github.com/drixevel"
};

public void OnPluginStart()
{
	CreateConVar("sm_tf2007_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);

	convar_DisableTaunts = CreateConVar("sm_tf2007_disable_taunts", "1", "Disables every taunt BUT default ones.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableMoveBuildings = CreateConVar("sm_tf2007_disable_movebuildings", "1", "Disables moving buildings around for Engineers.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableAirblasts = CreateConVar("sm_tf2007_disable_airblasts", "1", "Disables airblast for Pyro.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_FixedMedicSpeed = CreateConVar("sm_tf2007_fixed_medic_speed", "1", "Prevents Medics from speeding up while healing Scouts.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_FixedSpySpeed = CreateConVar("sm_tf2007_fixed_spy_speed", "1", "Locks Spy's speed to 300 units/second.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_BuildingLevels = CreateConVar("sm_tf2007_building_levels", "1", "Automatically sets the default building levels for Dispensers and Teleporters making them nonupgradable.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_LegacyPistol = CreateConVar("sm_tf2007_legacy_pistol", "1", "Lower the fire rate for pistols and allow for manual faster firing.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_GodPipes = CreateConVar("sm_tf2007_indestructable_pipes", "1", "Whether pipe bombs can take damage when shot.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableTauntKills = CreateConVar("sm_tf2007_disable_taunt_kills", "1", "Disable taunt kills.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableInspection = CreateConVar("sm_tf2007_disable_inspection", "1", "Disable player weapon inspections.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_LowerWeaponSwitching = CreateConVar("sm_tf2007_lower_weapon_switching", "1", "Lower the amount of time it takes to switch between weapons.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_IncreaseSoldierAmmoReserve = CreateConVar("sm_tf2007_increase_ammo_soldier", "1", "Increases Soldier's primary ammo reserve.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_IncreaseDemoAmmoReserve = CreateConVar("sm_tf2007_increase_ammo_demo", "1", "Increases Demo's primary ammo reserve.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_IncreaseDemoClipSize = CreateConVar("sm_tf2007_increase_clip_demo", "1", "Increases Demo's primary clip size.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DecreaseSoldierExplosionRadius = CreateConVar("sm_tf2007_decrease_explosion_soldier", "1", "Decreases the Rocket launcher's explosion radius.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_IncreaseDemoExplosionRadius = CreateConVar("sm_tf2007_increase_explosion_demo", "1", "Increases Demo's explosion radius (both weapons).\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_IncreaseTeleporterCost = CreateConVar("sm_tf2007_increase_teleporter_cost", "1", "Increases the cost for Engineer's teleporters.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_BuffSoldierSelfDamage = CreateConVar("sm_tf2007_buff_soldier_self_damage", "1", "Applies Soldier's blast damage resistance to all self-damage, not just rocket jumps.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_SlowerHeavyRev = CreateConVar("sm_tf2007_slower_heavy_rev", "1", "Makes Heavy move slower when revved up.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_NoCloakFillFromAmmo = CreateConVar("sm_tf2007_no_cloak_fill_from_ammo", "1", "Removes the ability to refill cloak from dropped ammo.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_NoCloakDamageResistance = CreateConVar("sm_tf2007_no_cloak_damage_resistance", "1", "Removes the 20% damage resistance when cloaked.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_NerfMedicHealthRegen = CreateConVar("sm_tf2007_nerf_medic_health_gen", "1", "Lowers Medic's health regeneration. Currently not very accurate.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_RemoveDemoSelfDamageOnDirectHit = CreateConVar("sm_tf2007_demo_no_damage_direct_hit", "1", "Removes Demo's self-damage when getting direct hits with the grenade launcher.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_NerfSpyShootingSappedBuildings = CreateConVar("sm_tf2007_nerf_spy_shooting_sapped", "1", "Halfs the damage Spy's revolver does to buildings he has sapped.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_NoDetonateStickiesWhileTaunting = CreateConVar("sm_tf2007_no_taunt_detonate", "1", "Removes the ability for Demo to detonate stickies while taunting.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableIntelGlows = CreateConVar("sm_tf2007_disable_intel_glows", "1", "Disable glows on intel briefcases.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig();

	convar_tf_damagescale_self_soldier = FindConVar("tf_damagescale_self_soldier");
	convar_tf_pipebomb_force_to_move = FindConVar("tf_pipebomb_force_to_move");

	convar_BuffSoldierSelfDamage.AddChangeHook(ConVarChanged_BuffSoldierSelfDamage);
	convar_GodPipes.AddChangeHook(ConVarChanged_GodPipes);
	
	ConVarChanged_BuffSoldierSelfDamage(convar_BuffSoldierSelfDamage, "", "");
	ConVarChanged_GodPipes(convar_GodPipes, "", "");

	HookEvent("post_inventory_application", Event_OnResupply);
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	
	AddCommandListener(OnTaunt, "taunt");
	AddCommandListener(OnTaunt, "+taunt");
	
	Handle conf = LoadGameConfigFile("tf2.2007");
	if (conf == null) SetFailState("Failed to load conf");
	
	dhook_CBaseEntity_CanBeUpgraded = DHookCreateFromConf(conf, "CBaseEntity::CanBeUpgraded");
	dhook_CTFPlayer_CanPickupBuilding = DHookCreateFromConf(conf, "CTFPlayer::CanPickupBuilding");

	if (dhook_CBaseEntity_CanBeUpgraded == null) SetFailState("Failed to create dhook_CBaseEntity_CanBeUpgraded");
	if (dhook_CTFPlayer_CanPickupBuilding == null) SetFailState("Failed to create dhook_CTFPlayer_CanPickupBuilding");

	DHookEnableDetour(dhook_CTFPlayer_CanPickupBuilding, true, DHookCallback_CTFPlayer_CanPickupBuilding);

	delete conf;

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);

	int entity = -1; char classname[32];
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		OnEntityCreated(entity, classname);
	}
}

public void OnPluginEnd()
{
	convar_tf_damagescale_self_soldier.SetFloat(0.6, false, false);
	convar_tf_pipebomb_force_to_move.SetFloat(1500.0, false, false);
}

void ConVarChanged_BuffSoldierSelfDamage(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue)
		convar_tf_damagescale_self_soldier.SetFloat(1.0, false, false);
	else
		convar_tf_damagescale_self_soldier.SetFloat(0.6, false, false);
}

void ConVarChanged_GodPipes(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue)
		convar_tf_pipebomb_force_to_move.SetFloat(150.0, false, false);
	else
		convar_tf_pipebomb_force_to_move.SetFloat(1500.0, false, false);
}

public void Event_OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = -1;
	int itemIndex = -1;
	
	if (convar_LowerWeaponSwitching.BoolValue)
		TF2Attrib_SetByName(client, "deploy time increased", 1.1); // Supposed to be 0.66 seconds, default is 0.5. 1.33 makes the switch way too slow.

	for (int i = 0; i < TF_MAX_SLOTS; i++) {
		weapon = GetPlayerWeaponSlot(client, i);
		itemIndex = GetWeaponIndex(weapon);

		if (weapon == -1 || itemIndex == -1)
			continue;
	
		if (itemIndex == 21) { // Flamethrower
			if (convar_DisableAirblasts.BoolValue) {
				TF2Attrib_SetByName(weapon, "airblast disabled", 1.0);
				TF2Attrib_RemoveByName(weapon, "extinguish restores health");
			}
		}
		
		if (itemIndex == 19) { // Grenade Launcher (clip size)
			if (convar_IncreaseDemoClipSize.BoolValue) {
				TF2Attrib_SetByName(weapon, "clip size bonus", 1.5); // 1.5 is 50% more ammo
				SetEntProp(weapon, Prop_Send, "m_iClip1", 6); // Weapon doesn't automatically reload
			}
			
			if (convar_IncreaseDemoAmmoReserve.BoolValue)
				TF2Attrib_SetByName(weapon, "maxammo primary increased", 1.875); // 16 * 1.875 = 30
				
			if (convar_IncreaseDemoExplosionRadius.BoolValue)
				TF2Attrib_SetByName(weapon, "Blast radius increased", 1.089); // 146 to 159 units
		}

		if (itemIndex == 20) { // Stickybomb Launcher
			if (convar_IncreaseDemoAmmoReserve.BoolValue)
				TF2Attrib_SetByName(weapon, "maxammo secondary increased", 1.66667); // 24 * 1.67 = 40
			
			if (convar_IncreaseDemoExplosionRadius.BoolValue)
				TF2Attrib_SetByName(weapon, "Blast radius increased", 1.089); // 146 to 159 units
		}

		
		if (itemIndex == 18) { // Rocket Launcher
			if (convar_IncreaseSoldierAmmoReserve.BoolValue)
				TF2Attrib_SetByName(weapon, "maxammo primary increased", 1.8); // 20 * 1.8 = 36
			
			if (convar_DecreaseSoldierExplosionRadius.BoolValue)
				TF2Attrib_SetByName(weapon, "Blast radius decreased", 0.828767); // 146 to 121 units
			
			if (convar_BuffSoldierSelfDamage.BoolValue) {
				TF2Attrib_SetByName(weapon, "blast dmg to self increased", 0.6);

				 // 0.6 is too low for a ctap. 0.7 might be too high, but eh
				TF2Attrib_SetByName(weapon, "self dmg push force decreased", 0.7);
			}
		}
		
		if (itemIndex == 7) { // Wrench
			if (convar_IncreaseTeleporterCost.BoolValue)
				TF2Attrib_SetByName(weapon, "mod teleporter cost", 2.5); // 50 * 2.5 = 125
		}
		
		if (itemIndex == 22 || itemIndex == 23) { // Pistol
			if (convar_LegacyPistol.BoolValue)
				TF2Attrib_SetByName(weapon, "fire rate bonus", 1.66666); // not a bonus, sets the fire rate from 0.15s to 0.25s
		}
		
		if (itemIndex == 15) { // Minigun
			if (convar_SlowerHeavyRev.BoolValue)
				TF2Attrib_SetByName(weapon, "aiming movespeed decreased", 80.0/110.0);
		}

		if (itemIndex == 30) { // Invis watch
			if (convar_NoCloakFillFromAmmo.BoolValue)
				TF2Attrib_SetByName(weapon, "mod_cloak_no_regen_from_items", 1.0);
				
			if (convar_NoCloakDamageResistance.BoolValue)
				TF2Attrib_SetByName(weapon, "absorb damage while cloaked", 0.8);
		}
		
		// In TF2 1.0.0.9, Medic's health regen started at 1 HP/s and ramped up to 3 HP/s.
		// In modern TF2, it starts at 3 HP/s and scales to 6 HP/s.
		// This is a bit hacky, the starting regen is all over the place
		// but the final rampup is 3 HP/s.
		// TODO: Make this more accurate. Apparently patching this requires a LOT of code.
		if (itemIndex == 17) { // Syringe gun
			if (convar_NerfMedicHealthRegen.BoolValue)
				TF2Attrib_SetByName(weapon, "health regen", -3.0);
		}
		
		TF2Attrib_ClearCache(weapon);
	}
	TF2Attrib_ClearCache(client);
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageFromPipe);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageFromTaunt);
}


public Action OnTakeDamageFromTaunt(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!convar_DisableTauntKills.BoolValue)
		return Plugin_Continue;

	if (damagecustom == TF_CUSTOM_TAUNT_HADOUKEN || 
		damagecustom == TF_CUSTOM_TAUNT_FENCING || 
		damagecustom == TF_CUSTOM_TAUNT_HIGH_NOON) {
			damage = 0.0;
			return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnTakeDamageFromPipe(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!convar_RemoveDemoSelfDamageOnDirectHit.BoolValue)
		return Plugin_Continue;

	char classname[64];

	if (!GetEntityClassname(inflictor, classname, sizeof(classname)))
		return Plugin_Continue;
	
	if (StrEqual(classname, "tf_projectile_pipe")) {
		if (GetEntProp(inflictor, Prop_Send, "m_bTouched"))
			return Plugin_Continue;

		// This assumes the victim will always get damaged before the inflictor.
		// May not be guaranteed? It always damaged the victim first in my tests.
		if (victim != attacker) {
			g_iLastDirectHitPipe = inflictor;
			RequestFrame(ResetLastFiredPipe);
		} else if (inflictor == g_iLastDirectHitPipe) {
			g_iLastDirectHitPipe = -1;
			damage = 0.0;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

void ResetLastFiredPipe()
{
	g_iLastDirectHitPipe = -1;
}

public Action OnTakeDamageFromSappingSpy(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!convar_NerfSpyShootingSappedBuildings.BoolValue)
		return Plugin_Continue;

	if (!IsValidClient(attacker))
		return Plugin_Continue;

	if (damagetype & DMG_BULLET == 0)
		return Plugin_Continue;
		
	if (!GetEntProp(victim, Prop_Send, "m_bHasSapper"))
		return Plugin_Continue;

	// Spy has a 33% damage reduction to shooting sapped buildings.
	// To make this 66%, all we need to do is half that number.
	int sapper = -1; 
	while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE) {
		if (GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity") == victim) {
			if (GetEntPropEnt(sapper, Prop_Send, "m_hBuilder") == attacker) {
				damage *= 0.5;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}


public Action OnTaunt(int client, const char[] command, int args)
{
	if (!convar_DisableTaunts.BoolValue)
		return Plugin_Continue;
	
	char sArg[32];
	GetCmdArgString(sArg, sizeof(sArg));
	
	if (!StrEqual(sArg, "0")) {
		FakeClientCommand(client, "taunt 0");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsValidClient(client))
		return Plugin_Continue;
		
	if (!IsPlayerAlive(client))
		return Plugin_Continue;

	TFClassType class = TF2_GetPlayerClass(client);

	if (class == TFClass_DemoMan && convar_NoDetonateStickiesWhileTaunting.BoolValue) {
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
			buttons &= ~IN_ATTACK2;
	} 
	else
	if (class == TFClass_Medic && convar_FixedMedicSpeed.BoolValue)
	{
		if (GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 320.0)
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
	}
	else
	if (class == TFClass_Spy && convar_FixedSpySpeed.BoolValue)
	{
		if (GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 300.0)
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
	}
	else
	if (class == TFClass_Pyro && convar_DisableAirblasts.BoolValue) {
		// This is a bit of a hack, but when airblast is disabled
		// pressing M2 prevents firing entirely.
		buttons &= ~IN_ATTACK2;
	}
	else

	// Pistol fires every 0.15s by default. We're setting the full-auto rate 
	// to 0.25s and the semi-auto rate to 0.15s.
	// I'm not sure what the exact number is for the semi-auto rate, but
	// going lower than 0.15 can cause client prediction issues.
	if ((class == TFClass_Scout || class == TFClass_Engineer) && convar_LegacyPistol.BoolValue)
	{
		int pistol = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int weaponIndex = GetWeaponIndex(pistol);
		if (weaponIndex != 22 && weaponIndex != 23)
			return Plugin_Continue;

		float nextAttack = GetEntPropFloat(pistol, Prop_Send, "m_flNextPrimaryAttack");
		if (buttons & IN_ATTACK) {
			TF2Attrib_SetByName(pistol, "fire rate bonus", 1.66666);
		} else {
			TF2Attrib_SetByName(pistol, "fire rate bonus", 0.8);
			if (nextAttack - GetGameTime() > 0.125)
				SetEntPropFloat(pistol, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.125);
		}
		TF2Attrib_ClearCache(pistol);	
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "obj_sentrygun") ||
		StrEqual(classname, "obj_dispenser") ||
		StrEqual(classname, "obj_teleporter"))
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageFromPipe);
	
	if (convar_GodPipes.BoolValue && StrEqual(classname, "tf_projectile_pipe_remote"))
		SDKHook(entity, SDKHook_OnTakeDamage, OnPipeTakeDamage);
	
	if (StrEqual(classname, "obj_sentrygun"))
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageFromSappingSpy);

	if (convar_BuildingLevels.BoolValue && (StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_teleporter")))
		DHookEntity(dhook_CBaseEntity_CanBeUpgraded, true, entity, _, DHookCallback_CBaseEntity_CanBeUpgraded);
}

MRESReturn DHookCallback_CBaseEntity_CanBeUpgraded(int entity, DHookReturn hReturn) {
	if (convar_BuildingLevels.BoolValue){
		DHookSetReturn(hReturn, false);
		return MRES_Override;
	}
	return MRES_Ignored;
}

MRESReturn DHookCallback_CTFPlayer_CanPickupBuilding(int entity, DHookReturn hReturn) {
	if (convar_DisableMoveBuildings.BoolValue){
		DHookSetReturn(hReturn, false);
		return MRES_Override;
	}
	return MRES_Ignored;
}

public Action OnPipeTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!convar_GodPipes.BoolValue)
		return Plugin_Continue;

	float force = GetVectorLength(damageForce, false);

	// These aren't actual specs, but arbitrary scales
	// we thought "felt right" during testing
	if (damagetype & DMG_BULLET)
		ScaleVector(damageForce, 3.0);
	else if (damagetype & DMG_BUCKSHOT) 
		ScaleVector(damageForce, 2.0);
	else if (damagetype & DMG_CLUB) {
		// Special case for the Shovel which has a force of 300.0 for some reason
		if (force > 0.0 && GetVectorLength(damageForce, false) < MELEE_FORCE) {
			NormalizeVector(damageForce, damageForce);
			ScaleVector(damageForce, MELEE_FORCE);
		}
		ScaleVector(damageForce, 0.5);
	}

	damagetype = DMG_BLAST;
	return Plugin_Changed;
}

public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!convar_DisableIntelGlows.BoolValue)
		return Plugin_Continue;

	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "item_teamflag")) != -1)
		if (HasEntProp(entity, Prop_Send, "m_bGlowEnabled"))
			SetEntProp(entity, Prop_Send, "m_bGlowEnabled", false);
	
	return Plugin_Continue;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char sBuffer[32];
	kv.GetSectionName(sBuffer, sizeof(sBuffer));
	
	if (convar_DisableInspection.BoolValue && StrEqual(sBuffer, "+inspect_server", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

stock int GetWeaponIndex(int weapon)
{
	return IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}

stock int GetActiveWeaponIndex(int client)
{
	return GetWeaponIndex(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
		return false;

	return IsClientInGame(client);
}
