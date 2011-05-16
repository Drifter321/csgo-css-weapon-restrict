#include <sourcemod>
#include <sdktools>
//#include <cstrike>
#pragma semicolon 1

//Include defines
#define WARMUP
#define CONFIGLOADER
#define STOCKMENU
#define PERPLAYER

//Team defines
#define SPEC_TEAM 1
#define CT_TEAM 3
#define T_TEAM 2
#define UNASSIGNED_TEAM 0

//Flag used for admin immunity.
#define ADMIN_LEVEL ADMFLAG_RESERVATION

#if defined STOCKMENU
#undef REQUIRE_PLUGIN
#include <adminmenu>
#endif

new g_iAccount;
new bool:warmup = false;
new bool:knives = false;
new bool:pistols = false;
new bool:isknivesround = false;
new bool:ispistolsround = false;
new Handle:gameConf = INVALID_HANDLE;
new Handle:weaponDrop = INVALID_HANDLE;
#if defined WARMUP
new Handle:roundRespawn = INVALID_HANDLE;
#endif
new String:RestrictSound[PLATFORM_MAX_PATH];
new Handle:AdminOverride = INVALID_HANDLE;
new bool:newround;
new bool:HasSound = false;
#if defined STOCKMENU
new Handle:hAdminMenu = INVALID_HANDLE;
#endif
#if defined WARMUP
new bool:grenadehooked = false;
#endif

#include "restrictinc/commands_cvars_tries.sp"

#if defined WARMUP
#include "restrictinc/warmup.sp"
#endif

#include "restrictinc/events.sp"

#if defined CONFIGLOADER
#include "restrictinc/configloader.sp"
#endif

#if defined STOCKMENU
#include "restrictinc/adminmenu.sp"
#endif

#if defined PERPLAYER
#include "restrictinc/perplayer.sp"
#endif

#include "restrictinc/admincmds.sp"
public Plugin:myinfo = 
{
	name = "Weapon Restrict",
	author = "Dr!fter",
	description = "Weapon restrict",
	version = PLUGIN_VERSION,
	url = "www.spawnpoint.com"
}
public OnPluginStart()
{
	new String:modname[50];
	GetGameFolderName(modname, sizeof(modname));
	if(!StrEqual(modname,"cstrike",false) && !StrEqual(modname, "cstrike_beta", false))
		SetFailState("Game is not counter strike source!");
	
	CreateWeaponTrie();
	RegisterHooks();
	RegisterAdminCommands();
	RegisterHacks();
	LoadTranslations("common.phrases");
	LoadTranslations("WeaponRestrict.phrases");
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	if(g_iAccount == -1)
		SetFailState("Could not find m_iAccount");
	
	PlayerWeapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
	if(PlayerWeapons == -1)
		SetFailState("Failed to find m_hMyWeapons offset");
	
	#if defined STOCKMENU
	//For late load 
	if(LibraryExists("adminmenu"))
	{
		new Handle:topmenu;
		topmenu = GetAdminTopMenu();
		
		if(topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
	#endif
	OnMapEnd();
	GetSounds();
	AdminOverride = CreateTrie();
	
	CreateTimer(0.1, LateLoadExec, _, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:LateLoadExec(Handle:timer)
{
	new String:file[] = "cfg/sourcemod/weapon_restrict.cfg";
	if(FileExists(file))
	{
		ServerCommand("exec sourcemod/weapon_restrict.cfg");
	}
	#if defined CONFIGLOADER
	CheckConfig();
	#endif
}
public OnMapStart()
{
	if(AdminOverride != INVALID_HANDLE)
	{
		ClearTrie(AdminOverride);
	}
	warmup = false;
	knives = false;
	pistols = false;
	newround = false;
	if(HasSound)
		PrecacheSound(RestrictSound, true);
	ResetEventGlobals();
}
public OnMapEnd()
{
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		if(!StrEqual(g_WeaponNames[i],  "knife", false))
		{
			if(!StrEqual(g_WeaponNames[i],  "c4", false))
				SetTrieValue(WeaponTrieCT, g_WeaponNames[i], -1);
			
			if(!StrEqual(g_WeaponNames[i],  "defuser", false))
				SetTrieValue(WeaponTrieT, g_WeaponNames[i], -1);
		}
	}
	#if defined WARMUP
	if(grenadehooked && !warmup)
	{
		grenadehooked = false;
		UnhookEvent("hegrenade_detonate", HeBoom);
	}
	#endif
	ResetConVars();
	if(AdminOverride != INVALID_HANDLE)
	{
		ClearTrie(AdminOverride);
	}
}
public OnConfigsExecuted()
{
	#if defined CONFIGLOADER
	CheckConfig();
	#endif
	#if defined WARMUP
	if(GetConVarInt(WarmUp) == 1)
	{
		if(ReadWarmup() && GetWarmupWeapon())
		{
			StartWarmup();
		}
	}
	#endif
	#if defined PERPLAYER
	perplayer = false;
	GetDefaultVals();// always get defaults just incase we revert back
	#endif
	SetConVarString(g_version, PLUGIN_VERSION, true, false);
}
RegisterHooks()
{
	#if defined WARMUP
	RegisterWarmup();
	#endif
	HookEvent("round_end", EventRoundEnd);
	HookEvent("round_start", EventRoundStart);
	HookEvent("item_pickup", EventItemPickup);
	RegConsoleCmd("buy", BuyCheck);
	RegConsoleCmd("rebuy", RebuyCheck);
	RegConsoleCmd("autobuy", RebuyCheck);
}
public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if defined WARMUP
	if(warmup)
	{
		StripGroundWeapons();
	}
	#endif
	if(knives)
	{
		knives = false;
		isknivesround = true;
		StripGuns(true);//true means no pistol
	}
	else if(pistols)
	{
		pistols = false;
		ispistolsround = true;
		StripGuns(false);//false means allow pistol
	}
	if(!isknivesround && !ispistolsround && !warmup)
	{
		CheckPlayersWeapons();
	}
	newround = true;
	CreateTimer(0.5, ResetRound, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}
public Action:ResetRound(Handle:timer)
{
	newround = false;
}
public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isknivesround)
	{
		knives = false;
		isknivesround = false;
	}
	else if(ispistolsround)
	{
		pistols = false;
		ispistolsround = false;
	}
	return Plugin_Continue;
}
RegisterHacks()
{
	gameConf = LoadGameConfigFile("weapon_restrict.games");
	if(gameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/weapon_restrict.games.txt not loadable");
	}
	//taken from GunGame:SM
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	weaponDrop = EndPrepSDKCall();
	
	if(weaponDrop == INVALID_HANDLE)
		SetFailState("Unable to find WeaponDrop Signature");

	#if defined WARMUP
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "RoundRespawn");
	roundRespawn = EndPrepSDKCall();
	
	if(roundRespawn == INVALID_HANDLE)
		SetFailState("Unable to find RoundRespawn Signature");
	#endif
}
CheckPlayersWeapons()
{
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		decl valuet;
		decl valuect;
		new String:weapon[100];
		weapon = g_WeaponNames[i];
		new slot;
		GetTrieValue(WeaponSlotTrie, weapon, slot);
		if(GetTrieValue(WeaponTrieCT, g_WeaponNames[i], valuect) && valuect != -1 && !StrEqual(g_WeaponNames[i], "c4", false) && !StrEqual(g_WeaponNames[i], "knife", false))
		{
			new total = GetTotal(-1, g_WeaponNames[i], CT_TEAM);
			if(total > valuect)
				RemoveWeaponRandom(total-valuect, CT_TEAM, g_WeaponNames[i], slot);
		}
		if(GetTrieValue(WeaponTrieT, g_WeaponNames[i], valuet) && valuet != -1 && !StrEqual(g_WeaponNames[i], "defuser", false) && !StrEqual(g_WeaponNames[i], "knife", false))
		{
			//PrintToChatAll("we need to check %s", g_WeaponNames[i]);
			new total = GetTotal(-1, g_WeaponNames[i], T_TEAM);
			//PrintToChatAll("total %i valuet %i", total, valuet);
			if(total > valuet)
				RemoveWeaponRandom(total-valuet, T_TEAM, g_WeaponNames[i], slot);
		}
	}
}
RemoveWeaponRandom(ammount, team, String:weapon[], slot)
{
	new String:weapon2[100];
	new playerarray[MAXPLAYERS+1];
	new count;
	
	Format(weapon2, sizeof(weapon2), "weapon_%s", weapon);
	if(slot == 3)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetConVarInt(AdminImmunity) == 1 && ((GetUserFlagBits(i) & ADMIN_LEVEL) || (GetUserFlagBits(i) & ADMFLAG_ROOT)))
				continue;
			if(IsClientInGame(i) && GetClientTeam(i) == team)
			{
				decl String:WeaponClass[64];
				static x = 0, EntityIndex = 0;
				for (x = 0; x <= (32 * 4); x += 4)
				{
					EntityIndex = GetEntDataEnt2(i, (PlayerWeapons + x));
					if(EntityIndex && IsValidEdict(EntityIndex))
					{
						GetEdictClassname(EntityIndex, WeaponClass, sizeof(WeaponClass));
						if(StrEqual(WeaponClass, weapon2))
						{
							playerarray[count] = i;
							count++;
						}
					}
				}
			}
		}
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetConVarInt(AdminImmunity) == 1 && ((GetUserFlagBits(i) & ADMIN_LEVEL) || (GetUserFlagBits(i) & ADMFLAG_ROOT)))
				continue;
			if(IsClientInGame(i) && GetClientTeam(i) == team)
			{
				new weaponindex = GetPlayerWeaponSlot(i, slot);
				new String:classname[100];
				if(IsValidEdict(weaponindex) && weaponindex != -1)
				{
					GetEdictClassname(weaponindex, classname, sizeof(classname));
					if(StrEqual(classname, weapon2, false))
					{
						playerarray[count] = i;
						count++;
					}
				}
			}
		}
	}
	
	SortIntegers(playerarray, count-1, Sort_Random);
	for(new i = 0; i < ammount; i++)
	{
		if(IsClientInGame(playerarray[i]))
		{
			if(slot != 3)
			{
				RemoveWeapon(playerarray[i], weapon, slot, false, true);
			}
			else if(StrEqual(weapon, "flashbang"))
			{
				CreateTimer(0.1, StripFlash, playerarray[i], TIMER_FLAG_NO_MAPCHANGE);
			}
			else if(StrEqual(weapon, "hegrenade"))
			{
				CreateTimer(0.1, StripNade, playerarray[i], TIMER_FLAG_NO_MAPCHANGE);
			}
			else if(StrEqual(weapon, "smokegrenade"))
			{
				CreateTimer(0.1, StripSmoke, playerarray[i], TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}
GetSounds()
{
	HasSound = false;
	new Handle:kv = CreateKeyValues("WeaponRestrictSounds");
	new String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "configs/restrict/sound.txt");
	if(FileExists(file))
	{
		FileToKeyValues(kv, file);
		if(KvJumpToKey(kv, "sounds", false))
		{
			new String:dtfile[PLATFORM_MAX_PATH];
			KvGetString(kv, "restricted", dtfile, sizeof(dtfile), "");
			if(FileExists(dtfile) && strlen(dtfile) > 0)
			{
				AddFileToDownloadsTable(dtfile);
				if(StrContains(dtfile, "sound/", false) == 0)
				{
					ReplaceStringEx(dtfile, sizeof(dtfile), "sound/", "", -1, -1, false);
					strcopy(RestrictSound, PLATFORM_MAX_PATH, dtfile);
				}
				PrecacheSound(RestrictSound, true);
				if(IsSoundPrecached(RestrictSound))
				{
					HasSound = true;
				}
				else
				{
					LogError("Failed to precache restrict sound please make sure path is correct in %s and sound is in the sounds folder", file);
				}
			}
			else
			{
				LogError("Sound %s dosnt exist", dtfile);
			}
		}
		else
		{
			LogError("sounds key missing from %s");
		}
	}
	else
	{
		LogError("File %s dosnt exist", file);
	}
	CloseHandle(kv);
}