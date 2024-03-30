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

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Simulates Medigun quirks from TF2 1.0.0.9."

#define NOOP 0x90

Handle dhook_CWeaponMedigun_FindAndHealTargets;
Handle dhook_CWeaponMedigun_ItemHolsterFrame;

ConVar convar_DisableSetupBonus;
ConVar convar_DisableFlashingPenalty;
ConVar convar_DisableHolsterDrain;
ConVar convar_DisableAutoHeal;

Address g_addrDrainCharge;
int g_offsetExtraPlayerCost;

bool g_bMemoryPatchTestWasSuccessful = true;
int g_iDrainChargeOriginalValues[5] = {0xF3, 0x0F, 0x58, 0x4D, 0xD4}; // do not change this

int g_iIsInSetupTime = false;
bool g_bPlayerIsUbering[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo = 
{
	name = "TF2007 Project Redux - Medigun tweaks", 
	author = "Keith Warren (Drixevel), Sappykun", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://github.com/drixevel"
};

public void OnPluginStart()
{
	convar_DisableSetupBonus = CreateConVar("sm_tf2007_medigun_disable_setup_bonus", "1", "Disables the setup time ubercharge rate increase.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableFlashingPenalty = CreateConVar("sm_tf2007_medigun_disable_flash_penalty", "1", "Disables the ubercharge drain increase when flashing multiple players.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableHolsterDrain = CreateConVar("sm_tf2007_medigun_disable_holster_drain", "1", "Prevents Uber from draining when holstered.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableAutoHeal = CreateConVar("sm_tf2007_medigun_disable_auto_heal", "1", "Disables auto-heal (forces the Medic to hold MOUSE1).\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(convar_DisableFlashingPenalty, ConVarChanged_FlashingPenalty);
	
	HookEvent("player_chargedeployed", Event_OnChargeDeployed);

	Handle conf = LoadGameConfigFile("tf2.2007");
	if (conf == null) SetFailState("Failed to load conf");

	dhook_CWeaponMedigun_FindAndHealTargets = DHookCreateFromConf(conf, "CWeaponMedigun::FindAndHealTargets");
	dhook_CWeaponMedigun_ItemHolsterFrame = DHookCreateFromConf(conf, "CWeaponMedigun::ItemHolsterFrame");

	if (dhook_CWeaponMedigun_FindAndHealTargets == null) SetFailState("Failed to create dhook_CWeaponMedigun_FindAndHealTargets");
	if (dhook_CWeaponMedigun_ItemHolsterFrame == null) SetFailState("Failed to create dhook_CWeaponMedigun_ItemHolsterFrame");

	DHookEnableDetour(dhook_CWeaponMedigun_FindAndHealTargets, false, DHookCallback_CWeaponMedigun_FindAndHealTargets_Pre);
	DHookEnableDetour(dhook_CWeaponMedigun_FindAndHealTargets, true, DHookCallback_CWeaponMedigun_FindAndHealTargets_Post);
	
	DHookEnableDetour(dhook_CWeaponMedigun_ItemHolsterFrame, false, DHookCallback_CWeaponMedigun_ItemHolsterFrame);
	DHookEnableDetour(dhook_CWeaponMedigun_ItemHolsterFrame, true, DHookCallback_CWeaponMedigun_ItemHolsterFrame);

	// The medigun has code to increase the ubercharge drain rate when
	// flashing multiple people. This is applied using this line:
	// flChargeAmount += flExtraPlayerCost; (C++ code)
	// addss xmm1, [ebp+var_2C] (equivalent assembly code)
	// This instruction is 5 bytes.  If we replace these bytes with no-op
	// instructions, we prevent adding the extra player cost to the charge
	// rate.
	// TODO: I hate this implementation. Find a better approach.

	g_addrDrainCharge = GameConfGetAddress(conf, "DrainCharge");
	g_offsetExtraPlayerCost = GameConfGetOffset(conf, "flExtraPlayerCost");

	delete conf;

	for (int i = 0; i < 5; i++) {
		int test = LoadFromAddress(g_addrDrainCharge + view_as<Address>(g_offsetExtraPlayerCost) + view_as<Address>(i), NumberType_Int8);
		if (test != g_iDrainChargeOriginalValues[i] && test != NOOP) {
			PrintToServer("Byte #%d for DrainCharge is incorrect! We wanted %X but got %X. Either the gamedata is out of date or the instruction has changed.", i, g_iDrainChargeOriginalValues[i], test);
			g_bMemoryPatchTestWasSuccessful = false;
		}
	}

	if (g_bMemoryPatchTestWasSuccessful && convar_DisableFlashingPenalty.BoolValue)
		DisableFlashPenalty();
		
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnPluginEnd()
{
	EnableFlashPenalty();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public void OnClientSettingsChanged(int client)
{
	if (!IsClientInGame(client))
		return;

	char buffer[16];

	GetClientInfo(client, "tf_medigun_autoheal", buffer, sizeof(buffer));
	if (convar_DisableAutoHeal.BoolValue && !StrEqual(buffer, "0"))
		SetClientInfo(client, "tf_medigun_autoheal", "0");
}

public void OnPreThink(int client)
{
	if (!IsClientInGame(client))
		return;

	TFClassType class = TF2_GetPlayerClass(client);
	if (class != TFClass_Medic)
		return;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
		return;
		
	if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != 29)
		return;
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") <= 0.0) 
		g_bPlayerIsUbering[client] = false;
}

public Action OnWeaponSwitch(int client, int weapon) 
{
	if (!convar_DisableHolsterDrain.BoolValue)
		return Plugin_Continue;

	if (!IsValidEntity(weapon))
		return Plugin_Continue;

	if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != 29)
		return Plugin_Continue;

	SetEntProp(weapon, Prop_Send, "m_bChargeRelease", g_bPlayerIsUbering[client]);
	return Plugin_Continue;
} 

void ConVarChanged_FlashingPenalty(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_bMemoryPatchTestWasSuccessful)
		return;

	if (StringToInt(newValue))
		DisableFlashPenalty();
	else
		EnableFlashPenalty();
}

public void DisableFlashPenalty()
{
	for (int i = 0; i < 5; i++)
		StoreToAddress(g_addrDrainCharge + view_as<Address>(g_offsetExtraPlayerCost) + view_as<Address>(i), NOOP, NumberType_Int8);
}

public void EnableFlashPenalty()
{
	for (int i = 0; i < 5; i++)
		StoreToAddress(g_addrDrainCharge + view_as<Address>(g_offsetExtraPlayerCost) + view_as<Address>(i), g_iDrainChargeOriginalValues[i], NumberType_Int8);
}

public void Event_OnChargeDeployed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bPlayerIsUbering[client] = true;
}

MRESReturn DHookCallback_CWeaponMedigun_FindAndHealTargets_Pre(int entity, DHookReturn hReturn)
{
	if (convar_DisableSetupBonus.BoolValue) {
		g_iIsInSetupTime = GameRules_GetProp("m_bInSetup");
		GameRules_SetProp("m_bInSetup", false);
	}
	return MRES_Ignored;
}

MRESReturn DHookCallback_CWeaponMedigun_FindAndHealTargets_Post(int entity, DHookReturn hReturn)
{
	if (convar_DisableSetupBonus.BoolValue)
		GameRules_SetProp("m_bInSetup", g_iIsInSetupTime);
	return MRES_Ignored;
}

MRESReturn DHookCallback_CWeaponMedigun_ItemHolsterFrame(int entity, DHookReturn hReturn)
{
	SetEntProp(entity, Prop_Send, "m_bChargeRelease", false);
	return MRES_Ignored;
}
