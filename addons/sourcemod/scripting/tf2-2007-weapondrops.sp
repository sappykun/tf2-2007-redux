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

#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Simulates TF2's old weapons drop system."

#define SOLID_VPHYSICS 6
#define FSOLID_TRIGGER (1<<3)
#define FSOLID_NOT_STANDABLE (1<<4)
// Ammo packs also usually use FSOLID_USE_TRIGGER_BOUNDS, but this causes physics to break on weapon drops

Handle sdk_CBaseEntity_VPhysicsInitNormal;

ConVar convar_DisableDroppedWeapons;

public Plugin myinfo = 
{
	name = "TF2007 Project Redux - Weapon Drops", 
	author = "Keith Warren (Drixevel), Sappykun", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://github.com/drixevel"
};

public void OnPluginStart()
{
	convar_DisableDroppedWeapons = CreateConVar("sm_tf2007_disable_droppedweapons", "1", "Delete dropped weapons on creation.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	Handle conf = LoadGameConfigFile("tf2.2007");
	if (conf == null) SetFailState("Failed to load conf");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CBaseEntity::VPhysicsInitNormal");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // SolidType_t solidType
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // int nSolidFlags
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // bool createAsleep
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // solid_t *pSolid
	sdk_CBaseEntity_VPhysicsInitNormal = EndPrepSDKCall();
	if (sdk_CBaseEntity_VPhysicsInitNormal == null) SetFailState("Failed to create sdk_CBaseEntity_VPhysicsInitNormal");
	
	delete conf;
	
	HookEvent("player_death", Event_OnPlayerDeath);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = -1;
	int weaponIndex = -1;
	int weaponItemDefinitionIndex = -1;
	int ammopack = -1;
	char model[PLATFORM_MAX_PATH];
	
	float force[3];
	force[0] = GetRandomFloat(-150.0, 150.0);
	force[1] = GetRandomFloat(-150.0, 150.0);
	force[2] = GetRandomFloat(0.0, 300.0);
	
	float origin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);

	if (convar_DisableDroppedWeapons.BoolValue) {
		while ((ammopack = FindEntityByClassname(ammopack, "tf_ammo_pack")) != -1) {
			if (GetEntPropEnt(ammopack, Prop_Send, "m_hOwnerEntity") == client) {
				weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				weaponIndex = GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex");
				weaponItemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				ModelIndexToString(weaponIndex, model, sizeof(model));

				 // Dirty hack for Heavy's fists, should drop minigun	
				if (weaponItemDefinitionIndex == 5)
					model = "models/weapons/c_models/c_minigun/c_minigun.mdl";

				// If a player doesn't have a weapon, they shouldn't spawn an
				// ammo pack anyways, but just in case.
				if (!model[0])
					return;
				
				PrecacheModel(model); // shouldn't be necessary, but just in case
				SetEntityModel(ammopack, model);

				SetEntPropEnt(ammopack, Prop_Send, "m_hOwnerEntity", -1);
				SDKCall(sdk_CBaseEntity_VPhysicsInitNormal, ammopack, SOLID_VPHYSICS, FSOLID_TRIGGER | FSOLID_NOT_STANDABLE, false, 0);
				// Give it a random push so it doesn't just drop straight down
				SDKHooks_TakeDamage(ammopack, 0, 0, 0.0, DMG_BLAST, -1, force, origin, false);
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (convar_DisableDroppedWeapons.BoolValue && StrEqual(classname, "tf_dropped_weapon"))
		SDKHook(entity, SDKHook_Spawn, OnPreventEntitySpawn);
}

public Action OnPreventEntitySpawn(int entity)
{
	return Plugin_Stop;
}

public void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}
