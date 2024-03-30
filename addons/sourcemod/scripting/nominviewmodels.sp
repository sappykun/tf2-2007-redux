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
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Force-disables min viewmodels."

#define TF_MAX_SLOTS 6
#define TF_MAX_ATTRIBUTES 16

#define min_viewmodel_offset 796
#define weapon_stattrak_module_scale 724
#define meter_label 2058
#define inspect_viewmodel_offset 817
#define custom_projectile_model 675
#define taunt_attack_name 556


DynamicHook g_hDHookItemIterateAttribute;
int g_iCEconItem_m_Item;
int g_iCEconItemView_m_bOnlyIterateItemViewAttributes;

public Plugin myinfo = 
{
	name = "No Min Viewmodels", 
	author = "Benoist3012, Sappykun", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=336156"
};

// Most code below is taken ad-verbatim from the snippet linked above.
// I don't know exactly how it works, but it does.

public void OnPluginStart()
{
	Handle hConfig = new GameData("tf2.nominviewmodels");

	int iOffset = GameConfGetOffset(hConfig, "CEconItemView::IterateAttributes");
	g_hDHookItemIterateAttribute = new DynamicHook(iOffset, HookType_Raw, ReturnType_Void, ThisPointer_Address);
	if (g_hDHookItemIterateAttribute == null)
	{
		SetFailState("Failed to create hook CEconItemView::IterateAttributes offset from SF2 gamedata!");
	}
	g_hDHookItemIterateAttribute.AddParam(HookParamType_ObjectPtr);

	g_iCEconItem_m_Item = FindSendPropInfo("CEconEntity", "m_Item");
	FindSendPropInfo("CEconEntity", "m_bOnlyIterateItemViewAttributes", _, _, g_iCEconItemView_m_bOnlyIterateItemViewAttributes);
	
	delete hConfig;
	
	HookEvent("post_inventory_application", Event_OnResupply);
}

public void TF2Items_OnGiveNamedItem_Post(int iClient, char[] sClassname, int iItemDefIndex, int iLevel, int iQuality, int iEntity)
{
	Address pCEconItemView = GetEntityAddress(iEntity) + view_as<Address>(g_iCEconItem_m_Item);
	g_hDHookItemIterateAttribute.HookRaw(Hook_Pre, pCEconItemView, CEconItemView_IterateAttributes);
	g_hDHookItemIterateAttribute.HookRaw(Hook_Post, pCEconItemView, CEconItemView_IterateAttributes_Post);
}

static MRESReturn CEconItemView_IterateAttributes(Address pThis, DHookParam hParams)
{
	StoreToAddress(pThis + view_as<Address>(g_iCEconItemView_m_bOnlyIterateItemViewAttributes), true, NumberType_Int8, false);
	return MRES_Ignored;
}

static MRESReturn CEconItemView_IterateAttributes_Post(Address pThis, DHookParam hParams)
{
	StoreToAddress(pThis + view_as<Address>(g_iCEconItemView_m_bOnlyIterateItemViewAttributes), true, NumberType_Int8, false);
	return MRES_Ignored;
} 

public void Event_OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = -1;
	int itemIndex = -1;
	
	int iAttribIndices[TF_MAX_ATTRIBUTES];
	float flAttribValues[TF_MAX_ATTRIBUTES];

	for (int i = 0; i < TF_MAX_SLOTS; i++) {
		weapon = GetPlayerWeaponSlot(client, i);

		if (weapon < 1)
			continue;
			
		itemIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (itemIndex == -1)
			continue;

		// We need to reapply all the static attributes when disabling min viewmodels.
		// Otherwise, the flamethrower completely breaks.  I don't know how other
		// weapons are affected, so it's safer to just reapply them all on every weapon.
		// Some static attributes will crash a client if they are re-applied.
		// TODO: Find a better way to filter out bad attributes.
		TF2Attrib_GetStaticAttribs(itemIndex, iAttribIndices, flAttribValues, TF_MAX_ATTRIBUTES);
		for (int j = 0; j < TF_MAX_ATTRIBUTES; j++)
			if (iAttribIndices[j] > 0 && 
				iAttribIndices[j] != min_viewmodel_offset &&  // on all vanilla weapons
				iAttribIndices[j] != weapon_stattrak_module_scale && // on all vanilla weapons
				iAttribIndices[j] != meter_label &&
				iAttribIndices[j] != inspect_viewmodel_offset &&
				iAttribIndices[j] != custom_projectile_model &&
				iAttribIndices[j] != taunt_attack_name) {
				TF2Attrib_SetByDefIndex(weapon, iAttribIndices[j],  flAttribValues[j]);
			}
	}
}
