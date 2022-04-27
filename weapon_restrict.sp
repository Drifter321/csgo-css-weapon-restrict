#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required;
#include <cstrike_weapons>
#include <restrict>
#pragma semicolon 1

#define WARMUP
#define CONFIGLOADER
#define STOCKMENU
#define PERPLAYER

#if defined STOCKMENU
#undef REQUIRE_PLUGIN
#include <adminmenu>
#endif

#define PLUGIN_VERSION "4.2.0"
#define ADMINCOMMANDTAG "\x01[\x04SM\x01]\x04 "
#define MAXWEAPONGROUPS 7

EngineVersion g_iEngineVersion;
char g_WeaponGroupNames[][] = {"pistols", "smgs", "shotguns", "rifles", "snipers", "grenades", "armor"};

bool g_bRestrictSound = false;
char g_sCachedSound[PLATFORM_MAX_PATH];
bool g_bLateLoaded = false;

RoundType g_nextRoundSpecial = RoundType_None;
RoundType g_currentRoundSpecial = RoundType_None;
#if defined STOCKMENU
TopMenu hAdminMenu = null;
#endif

#include "restrictinc/cvars.sp"

#if defined WARMUP
#include "restrictinc/warmup.sp"
#endif

#if defined CONFIGLOADER
#include "restrictinc/configloader.sp"
#endif

#if defined STOCKMENU
#include "restrictinc/adminmenu.sp"
#endif

#if defined PERPLAYER
#include "restrictinc/perplayer.sp"
#endif

#include "restrictinc/weapon-tracking.sp"
#include "restrictinc/natives.sp"
#include "restrictinc/functions.sp"
#include "restrictinc/events.sp"
#include "restrictinc/admincmds.sp"

public Plugin myinfo = 
{
	name = "Weapon Restrict",
	author = "Dr!fter",
	description = "CS:S & CS:GO Weapon restrict",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	g_iEngineVersion = GetEngineVersion();
	
	if(g_iEngineVersion != Engine_CSGO && g_iEngineVersion != Engine_CSS)
	{
		strcopy(error, err_max, "This plugin is only supported on CS");
		return APLRes_Failure;
	}

	g_bLateLoaded = late;
	RegisterNatives();
	
	return APLRes_Success;
}

public void OnPluginStart()
{	
	HookEvents();
	RegisterAdminCommands();
	RegisterForwards();
	
	#if defined WARMUP
	RegisterWarmup();
	#endif
	
	#if defined STOCKMENU
	//For late load 
	if(LibraryExists("adminmenu"))
	{
		TopMenu topmenu;
		topmenu = GetAdminTopMenu();
		
		if(topmenu != null)
		OnAdminMenuReady(topmenu);
	}
	#endif
	
	LoadTranslations("common.phrases");
	LoadTranslations("WeaponRestrict.phrases");
	
	CreateTimer(0.1, LateLoadExec, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action LateLoadExec(Handle timer)
{
	char szFile[] = "cfg/sourcemod/weapon_restrict.cfg";
	
	if(FileExists(szFile))
	{
		ServerCommand("exec sourcemod/weapon_restrict.cfg");
	}

	return Plugin_Continue;
}
