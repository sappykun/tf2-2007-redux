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

#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Removes backstab and headshot animations."

#define RAG_GIBBED			(1<<0)
#define RAG_BURNING			(1<<1)
#define RAG_ELECTROCUTED	(1<<2)
#define RAG_FEIGNDEATH		(1<<3)
#define RAG_WASDISGUISED	(1<<4)
#define RAG_BECOMEASH		(1<<5)
#define RAG_ONGROUND		(1<<6)
#define RAG_CLOAKED			(1<<7)
#define RAG_GOLDEN			(1<<8)
#define RAG_ICE				(1<<9)
#define RAG_CRITONHARDCRIT	(1<<10)
#define RAG_HIGHVELOCITY	(1<<11)
#define RAG_NOHEAD			(1<<12)

ConVar convar_FixedRagdolls;

public Plugin myinfo = 
{
	name = "TF2007 Project Redux - Ragdolls", 
	author = "Keith Warren (Drixevel), Sappykun", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://github.com/drixevel"
};

public void OnPluginStart()
{
	convar_FixedRagdolls = CreateConVar("sm_tf2007_fixed_ragdolls", "1", "Fix ragdolls such as Spy backstabbing animations.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookEvent("player_death", Event_OnPlayerDeath);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0)
		return;
		
	bool IsBackstab = event.GetInt("customkill") == TF_CUSTOM_BACKSTAB;
	bool IsHeadshot = event.GetInt("customkill") == TF_CUSTOM_HEADSHOT;
	
	if (convar_FixedRagdolls.BoolValue && (IsBackstab || IsHeadshot))
		RequestFrame(Frame_Ragdoll, client);
}

public void Frame_Ragdoll(any client)
{
	if (client == 0 || !IsClientInGame(client) || IsPlayerAlive(client))
		return;
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEdict(ragdoll))
		return;
	
	char classname[64];
	GetEdictClassname(ragdoll, classname, sizeof(classname));

	if (!StrEqual(classname, "tf_ragdoll", false))
		return;
	
	float vel[3];
	GetEntPropVector(ragdoll, Prop_Send, "m_vecForce", vel);

	RemoveEdict(ragdoll);
	TF2_SpawnRagdoll(client, 0.0, 0, vel);
}

int TF2_SpawnRagdoll(int client, float destruct = 10.0, int flags = 0, float vel[3] = NULL_VECTOR)
{
	int ragdoll = CreateEntityByName("tf_ragdoll");

	if (IsValidEntity(ragdoll))
	{
		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);

		float vecAngles[3];
		GetClientAbsAngles(client, vecAngles);

		TeleportEntity(ragdoll, vecOrigin, vecAngles, NULL_VECTOR);

		SetEntProp(ragdoll, Prop_Send, "m_iTeam", GetClientTeam(client));
		SetEntProp(ragdoll, Prop_Send, "m_iClass", view_as<int>(TF2_GetPlayerClass(client)));
		SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 1);
		SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", TF_CUSTOM_TAUNT_ENGINEER_SMASH);
		
		SetEntProp(ragdoll, Prop_Send, "m_bGib", (flags & RAG_GIBBED) == RAG_GIBBED);
		SetEntProp(ragdoll, Prop_Send, "m_bBurning", (flags & RAG_BURNING) == RAG_BURNING);
		SetEntProp(ragdoll, Prop_Send, "m_bElectrocuted", (flags & RAG_ELECTROCUTED) == RAG_ELECTROCUTED);
		SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", (flags & RAG_FEIGNDEATH) == RAG_FEIGNDEATH);
		SetEntProp(ragdoll, Prop_Send, "m_bWasDisguised", (flags & RAG_WASDISGUISED) == RAG_WASDISGUISED);
		SetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh", (flags & RAG_BECOMEASH) == RAG_BECOMEASH);
		SetEntProp(ragdoll, Prop_Send, "m_bOnGround", (flags & RAG_ONGROUND) == RAG_ONGROUND);
		SetEntProp(ragdoll, Prop_Send, "m_bCloaked", (flags & RAG_CLOAKED) == RAG_CLOAKED);
		SetEntProp(ragdoll, Prop_Send, "m_bGoldRagdoll", (flags & RAG_GOLDEN) == RAG_GOLDEN);
		SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", (flags & RAG_ICE) == RAG_ICE);
		SetEntProp(ragdoll, Prop_Send, "m_bCritOnHardHit", (flags & RAG_CRITONHARDCRIT) == RAG_CRITONHARDCRIT);
		
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", vecOrigin);
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", vel);
		SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", vel);
		
		if ((flags & RAG_HIGHVELOCITY) == RAG_HIGHVELOCITY)
		{
			float HighVel[3];
			HighVel[0] = -180000.552734;
			HighVel[1] = -1800.552734;
			HighVel[2] = 800000.552734;
			
			SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", HighVel);
			SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", HighVel);
		}
		
		SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", (flags & RAG_NOHEAD) == RAG_NOHEAD ? 0.0 : 1.0);
		SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", 1.0);
		SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", 1.0);
		
		DispatchSpawn(ragdoll);
		ActivateEntity(ragdoll);
		
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll, 0);
		
		if (destruct > 0.0)
		{
			char output[64];
			Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1", destruct);

			SetVariantString(output);
			AcceptEntityInput(ragdoll, "AddOutput");
			AcceptEntityInput(ragdoll, "FireUser1");
		}
	}

	return ragdoll;
}
