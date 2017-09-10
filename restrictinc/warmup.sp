#define MAX_WARMUP_WEAPONS 25
CSWeaponID g_iWarmupWeapon = CSWeapon_NONE;
int iWarmupCount;
int iFriendlyFire;

Handle RespawnTimer[MAXPLAYERS+1];

void RegisterWarmup()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("hegrenade_detonate", OnHegrenadeDetonate);
}

void KillRespawnTimer(int client)
{
	if(RespawnTimer[client] != null)
	{
		delete RespawnTimer[client];
	}
}

bool StartWarmup()
{
	for(int i = 1; i <= MaxClients; i++)
		RespawnTimer[i] = null;
	
	g_iWarmupWeapon = GetWarmupWeapon();
	
	if(g_iWarmupWeapon == CSWeapon_NONE)
		return false;
	
	char szPreConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPreConfig, sizeof(szPreConfig), "configs/restrict/prewarmup.cfg");
	RunFile(szPreConfig);
	
	StripGroundWeapons();
	
	if(hFriendlyFire)
	{
		iFriendlyFire = hFriendlyFire.IntValue;
	
		if(hWarmupFriendlyFire.BoolValue)
		{
			hFriendlyFire.SetInt(0, true, false);
		}
	}
	
	iWarmupCount = 1;
	
	if(g_iEngineVersion == Engine_CSS)
	{
		PrintCenterTextAll("%t", "WarmupCountdown", hWarmupTime.IntValue);
	}
	else
	{
		static ConVar mp_do_warmup_period_cvar = null;
		static ConVar mp_warmuptime_cvar = null;
		
		if(mp_do_warmup_period_cvar == null)
			mp_do_warmup_period_cvar = FindConVar("mp_do_warmup_period");
		
		if(mp_warmuptime_cvar == null)
			mp_warmuptime_cvar = FindConVar("mp_warmuptime");
		
		if(mp_do_warmup_period_cvar)
			mp_do_warmup_period_cvar.SetInt(0, true, false);
		
		if(mp_warmuptime_cvar)
			mp_warmuptime_cvar.SetInt(hWarmupTime.IntValue, true, false);
		
		GameRules_SetProp("m_bWarmupPeriod", true, _, _, true);
		GameRules_SetPropFloat("m_fWarmupPeriodEnd", (GetGameTime()+hWarmupTime.FloatValue), _, true);
	}
	
	CreateTimer(1.0, WarmupCount, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	OnWarmupStart_Post();
	return true;
}

CSWeaponID GetWarmupWeapon()
{
	char szWarmupConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szWarmupConfig, sizeof(szWarmupConfig), "configs/restrict/warmup.cfg");
	
	if(!FileExists(szWarmupConfig))
	{
		LogError("Cannot find warmup.cfg. Disabling warmup.");
		return CSWeapon_NONE;
	}
	
	File hWarmupConfig = OpenFile(szWarmupConfig, "r");
	
	CSWeaponID iWeaponArray[MAX_WARMUP_WEAPONS];
	
	char szFileLine[WEAPONARRAYSIZE];
	int iWeaponCount = 0;
	
	while(!hWarmupConfig.EndOfFile())
	{
		hWarmupConfig.ReadLine(szFileLine, sizeof(szFileLine));
		
		if(strncmp(szFileLine, "//", 2) != 0)
		{
			TrimString(szFileLine);
			
			CSWeaponID id = Restrict_GetWeaponIDExtended(szFileLine);
			
			if(id == CSWeapon_NONE)
				continue;
			
			WeaponSlot slot = CSWeapons_GetWeaponSlot(id);
			
			if(slot == SlotInvalid || slot == SlotNone)
				continue;
			
			iWeaponArray[iWeaponCount] = id;
			iWeaponCount++;
		}
	}
	
	delete hWarmupConfig;
	
	if(iWeaponCount == 0)
		return CSWeapon_NONE;
	
	int index = GetRandomInt(0, iWeaponCount-1);
	
	return iWeaponArray[index];
}

public Action WarmupCount(Handle timer)
{
	if(hWarmupTime.IntValue <= iWarmupCount)
	{
		EndWarmup();
		if(g_iEngineVersion == Engine_CSS)
		{
			ServerCommand("mp_restartgame 1");
		}
		
		return Plugin_Stop;
	}
	
	if(g_iEngineVersion == Engine_CSS)
	{
		PrintCenterTextAll("%t", "WarmupCountdown", hWarmupTime.IntValue-iWarmupCount);
	}

	iWarmupCount++;
	
	return Plugin_Continue;
}

void EndWarmup()
{
	g_currentRoundSpecial = RoundType_None;
	OnWarmupEnd_Post();
	
	char szPostConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPostConfig, sizeof(szPostConfig), "configs/restrict/postwarmup.cfg");
	RunFile(szPostConfig);
		
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			KillRespawnTimer(i);
	}
		
	CreateTimer(1.1, ResetFF, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ResetFF(Handle timer)
{
	//Check if special round was set
	g_currentRoundSpecial = g_nextRoundSpecial;
	g_nextRoundSpecial = RoundType_None;
	
	hFriendlyFire.SetInt(iFriendlyFire, true, false);	
}

void GiveWarmupWeapon(int client)
{
	if((CSWeapons_GetWeaponSlot(g_iWarmupWeapon) != SlotKnife || g_iWarmupWeapon == CSWeapon_TASER) && IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR && Restrict_IsWarmupRound())
	{
		if(GetPlayerWeaponSlot(client, view_as<int>(CSWeapons_GetWeaponSlot(g_iWarmupWeapon))) == -1 || g_iWarmupWeapon == CSWeapon_TASER)// avoids giving player weapon twice for some odd reason grenade is given twice without this
		{
			char szClassname[WEAPONARRAYSIZE];
			
			if(CSWeapons_GetWeaponClassname(g_iWarmupWeapon, szClassname, sizeof(szClassname)))
				GivePlayerItem(client, szClassname);
		}
	}
}

public Action OnPlayerSpawn(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	RespawnTimer[client] = INVALID_HANDLE;
	
	if(Restrict_IsWarmupRound() && IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR && IsPlayerAlive(client))
	{
		GiveWarmupWeapon(client);
	}
}

public Action OnPlayerDeath(Event event, const char [] name, bool dontBroadcast)
{
	if(Restrict_IsWarmupRound() && hWarmupRespawn.BoolValue)
	{
		int userid = event.GetInt("userid");
		int client = GetClientOfUserId(userid);
		
		if(RespawnTimer[client] == null)
			RespawnTimer[client] = CreateTimer(hWarmupRespawnTime.FloatValue, RespawnFunc, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnHegrenadeDetonate(Event event, const char [] name, bool dontBroadcast)
{
	if(!Restrict_IsWarmupRound() || g_iWarmupWeapon != CSWeapon_HEGRENADE || !hInfiniteGrenade.BoolValue)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(client != 0 && IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR && IsPlayerAlive(client))
	{
		if(Restrict_GetClientGrenadeCount(client, CSWeapon_HEGRENADE) <= 0)
		{
			int weapon = GivePlayerItem(client,"weapon_hegrenade");
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
	
	return Plugin_Continue;
}

public Action RespawnFunc(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client != 0)
		RespawnTimer[client] = null;
		
	if(client != 0 && hWarmupRespawn.BoolValue && Restrict_IsWarmupRound() && IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		CS_RespawnPlayer(client);
	}
}

void StripGroundWeapons()
{
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			char szClassname[WEAPONARRAYSIZE];
			GetEdictClassname(i, szClassname, sizeof(szClassname));
			
			if((strncmp(szClassname, "weapon_", 7, false) == 0 || strncmp(szClassname, "item_", 5, false) == 0) && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1 && Restrict_GetWeaponIDExtended(szClassname) != CSWeapon_NONE)
				AcceptEntityInput(i, "Kill");
		}
	}
}