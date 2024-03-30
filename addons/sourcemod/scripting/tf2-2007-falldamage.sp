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

#include <regex>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Replaces all fall damage sounds with the originals from TF2 1.0.0.9."

Handle g_hFallVoiceRegex;

ConVar convar_ReplaceFallDamageSounds;

bool g_bShouldReplaceFallDamageSound[MAXPLAYERS + 1];
char g_sFallPainTemplate[32] = "player/pl_fallpain%d.wav";

public Plugin myinfo =
{
	name = "TF2007 Project Redux - Fall Damage Sound Replacer",
	author = "Sappykun",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://weea.boutique/"
}

public void OnPluginStart()
{	
	convar_ReplaceFallDamageSounds = CreateConVar("sm_tf2007_falldamage_replace", "1", "Replaces fall damage sounds.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_hFallVoiceRegex = CompileRegex("vo/\\w+_PainSevere\\d+.(wav|mp3)", PCRE_CASELESS);

	AddNormalSoundHook(ReplaceFallDamageSound);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

// The original files go from pl_fallpain3 to pl_fallpain13
// but pl_fallpain3 is used in later versions of HL2
// so I renamed it to pl_fallpain14.
public void OnMapStart()
{
	char sFallPain[64];
	for (int i = 4; i <= 14; i++) {
		Format(sFallPain, sizeof(sFallPain), g_sFallPainTemplate, i);
		PrecacheSound(sFallPain, true);
		Format(sFallPain, sizeof(sFallPain), "sound/%s", sFallPain);
		AddFileToDownloadsTable(sFallPain);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagetype & DMG_FALL)
		g_bShouldReplaceFallDamageSound[victim] = true;
	return Plugin_Continue;
}

public Action ReplaceFallDamageSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (entity <= 0 || entity > 4096 || entity > MaxClients)
		return Plugin_Continue;
	
	if (convar_ReplaceFallDamageSounds.BoolValue) {
		if (StrEqual(sample, "player/pl_fallpain.wav"))
			return Plugin_Handled;

		if (g_bShouldReplaceFallDamageSound[entity] && MatchRegex(g_hFallVoiceRegex, sample) > 0) {
			Format(sample, sizeof(sample), g_sFallPainTemplate, GetRandomInt(4, 14));
			g_bShouldReplaceFallDamageSound[entity] = false;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bShouldReplaceFallDamageSound[client] = false;
}
