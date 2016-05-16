#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <ttt_shop>
#include <ttt>
#include <config_loader>
#include <multicolors>

#pragma newdecls required

#define SHORT_NAME "dt"

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: Decoy Teleporter"

int g_iTPrice = 0;
int g_iDPrice = 0;

int g_iTCount = 0;
int g_iTPCount[MAXPLAYERS + 1] =  { 0, ... };

int g_iDCount = 0;
int g_iDPCount[MAXPLAYERS + 1] =  { 0, ... };

int g_bHasTeleporter[MAXPLAYERS + 1] =  { false, ... };

char g_sConfigFile[PLATFORM_MAX_PATH] = "";
char g_sPluginTag[PLATFORM_MAX_PATH] = "";
char g_sLongName[64];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = TTT_PLUGIN_AUTHOR,
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/config.cfg");
	Config_Setup("TTT", g_sConfigFile);
	
	Config_LoadString("ttt_plugin_tag", "{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %T", "The prefix used in all plugin messages (DO NOT DELETE '%T')", g_sPluginTag, sizeof(g_sPluginTag));
	
	Config_Done();
	
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/decoy_teleporter.cfg");

	Config_Setup("TTT-Decoy-Teleporter", g_sConfigFile);
	
	Config_LoadString("dt_name", "Decoy Teleprter", "The name of the Decoy Teleporter in the Shop", g_sLongName, sizeof(g_sLongName));
	
	g_iTPrice = Config_LoadInt("dt_traitor_price", 9000, "The amount of credits for decoy teleporter costs as traitor. 0 to disable.");
	g_iDPrice = Config_LoadInt("dt_detective_price", 9000, "The amount of credits for decoy teleporter costs as detective. 0 to disable.");
	
	g_iTCount = Config_LoadInt("dt_traitor_count", 1, "The amount of usages for decoy teleporters per round as traitor. 0 to disable.");
	g_iDCount = Config_LoadInt("dt_detective_count", 1, "The amount of usages for decoy teleporters per round as detective. 0 to disable.");
	
	
	Config_Done();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("decoy_started", Event_DecoyStarted, EventHookMode_Pre);
}

public void OnClientDisconnect(int client)
{
	ResetDecoyCount(client);
}

public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(TTT_IsClientValid(client))
	{
		int entity = event.GetInt("entityid");
		
		if(!g_bHasTeleporter[client])
			return Plugin_Continue;
		

		
		float fPos[3];
		fPos[0] = event.GetFloat("x");
		fPos[1] = event.GetFloat("y");
		fPos[2] = event.GetFloat("z");
		
		TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
		
		AcceptEntityInput(entity, "kill");
		
		g_bHasTeleporter[client] = false;
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(TTT_IsClientValid(client))
		ResetDecoyCount(client);
}

public void OnAllPluginsLoaded()
{
	TTT_RegisterCustomItem(SHORT_NAME, g_sLongName, g_iTPrice, TTT_TEAM_TRAITOR);
	TTT_RegisterCustomItem(SHORT_NAME, g_sLongName, g_iDPrice, TTT_TEAM_DETECTIVE);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort)
{
	if(TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if(StrEqual(itemshort, SHORT_NAME, false))
		{
			int role = TTT_GetClientRole(client);
			
			if(role == TTT_TEAM_TRAITOR && g_iTPCount[client] >= g_iTCount)
			{
				CPrintToChat(client, g_sPluginTag, "Bought All", client, g_sLongName, g_iTCount);
				return Plugin_Stop;
			}
			else if(role == TTT_TEAM_DETECTIVE && g_iDPCount[client] >= g_iDCount)
			{
				CPrintToChat(client, g_sPluginTag, "Bought All", client, g_sLongName, g_iDCount);
				return Plugin_Stop;
			}
			
			GivePlayerItem(client, "weapon_decoy");
			
			g_bHasTeleporter[client] = true;
			
			if(role == TTT_TEAM_TRAITOR)
				g_iTPCount[client]++;
			else if(role == TTT_TEAM_DETECTIVE)
				g_iDPCount[client]++;
		}
	}
	return Plugin_Continue;
}

void ResetDecoyCount(int client)
{
	g_iTPCount[client] = 0;
	g_iDPCount[client] = 0;
	
	g_bHasTeleporter[client] = false;
}
