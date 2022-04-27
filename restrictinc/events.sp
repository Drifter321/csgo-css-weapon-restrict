#define PRINTDELAY 2.0
bool g_bSpamProtectPrint[MAXPLAYERS+1];

void HookEvents()
{
	AddCommandListener(OnJoinClass, "joinclass");
	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end", EventRoundEnd);
}

public Action OnJoinClass(int client, const char [] szCommand, int args) 
{
	#if defined PERPLAYER
	CheckPerPlayer();
	#endif
	
	#if defined WARMUP
	if(!Restrict_IsWarmupRound() || !IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR || !hWarmupRespawn.BoolValue)
		return Plugin_Continue;
	
	if(RespawnTimer[client] == INVALID_HANDLE)
		RespawnTimer[client] = CreateTimer(hWarmupRespawnTime.FloatValue, RespawnFunc, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	#endif
	
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	#if defined PERPLAYER
	CheckPerPlayer();
	#endif
	
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	#if defined PERPLAYER
	CheckPerPlayer();
	#endif
	#if defined WARMUP
	KillRespawnTimer(client);
	#endif
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	int iTeam = GetClientTeam(client);
	
	if(iTeam <= CS_TEAM_SPECTATOR)
		return Plugin_Continue;

	CSWeaponID id = GetWeaponIDFromEnt(weapon);
	
	if(id == CSWeapon_NONE)
		return Plugin_Continue;
	
	#if defined WARMUP
	if(Restrict_IsWarmupRound() && Restrict_CanPickupWeapon(client, iTeam, id))
	{
		return Plugin_Continue;
	}
	else if(Restrict_IsWarmupRound())
	{
		AcceptEntityInput(weapon, "Kill");
		return Plugin_Handled;
	}
	#endif
	
	if(Restrict_CanPickupWeapon(client, iTeam, id) || !IsGoingToPickup(client, id))
		return Plugin_Continue;
	
	WeaponType type = CSWeapons_GetWeaponType(id);
	
	if(id == CSWeapon_C4 || type == WeaponTypeKnife)
		AcceptEntityInput(weapon, "Kill");
	
	if(!g_bSpamProtectPrint[client])
	{
		char szWeaponName[WEAPONARRAYSIZE];
		CSWeapons_GetAlias(id, szWeaponName, sizeof(szWeaponName), true);
		bool bWeaponTranslation = TranslationPhraseExists(szWeaponName);

		if(Restrict_IsSpecialRound() && !Restrict_AllowedForSpecialRound(id))
		{
			if(bWeaponTranslation)
				PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "SpecialNotAllowed", client);
			else
				PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "SpecialNotAllowed", client);
		}
		else if(iTeam == CS_TEAM_CT)
		{
			if(bWeaponTranslation)
				PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "IsRestrictedPickupCT", client, Restrict_GetRestrictValue(iTeam, id));
			else
				PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "IsRestrictedPickupCT", client, Restrict_GetRestrictValue(iTeam, id));
		}
		else
		{
			if(bWeaponTranslation)
				PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "IsRestrictedPickupT", client, Restrict_GetRestrictValue(iTeam, id));
			else
				PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "IsRestrictedPickupT", client, Restrict_GetRestrictValue(iTeam, id));
		}
		
		g_bSpamProtectPrint[client] = true;
		CreateTimer(PRINTDELAY, ResetPrintDelay, client);
	}
	return Plugin_Handled;
}

public Action ResetPrintDelay(Handle timer, int client)
{
	g_bSpamProtectPrint[client] = false;

	return Plugin_Continue;
}

public void OnMapStart()
{
	g_nextRoundSpecial = RoundType_None;
	g_currentRoundSpecial = RoundType_None;
	
	#if defined PERPLAYER
	g_bPerPlayerReady = false;
	#endif
	
	CSWeapons_Init();
	
	CreateConVars();
	
	RegisterGrenades();
	
	ClearOverride();
	
	CheckWeaponArrays();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bSpamProtectPrint[i] = false;
		
		if(g_bLateLoaded)
		{
			if(!IsClientInGame(i))
				continue;
			
			OnClientPutInServer(i);
		}
	}
	
	hVersion.SetString(PLUGIN_VERSION, true, false);
}

public void OnConfigsExecuted()
{
	#if defined CONFIGLOADER
	CheckConfig();
	#endif
	
	CreateTimer(0.1, DelayExec);
}

public Action DelayExec(Handle timer)
{
	#if defined WARMUP
	if(hWarmupEnabled.BoolValue && !g_bLateLoaded)
	{
		if(StartWarmup())
			g_currentRoundSpecial = RoundType_Warmup;
	}
	#endif
	
	GetWeaponRestrictSound();
	
	#if defined PERPLAYER
	PerPlayerInit();
	CheckPerPlayer();
	#endif
	
	g_bLateLoaded = false;

	return Plugin_Continue;
}

public Action EventRoundStart(Handle event, const char [] name, bool dontBroadcast)
{
	if(Restrict_IsSpecialRound())
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
				continue;
			RemoveForSpecialRound(i);
		}
	}
	else
	{
		Restrict_CheckPlayerWeapons();
	}
	return Plugin_Continue;
}

public Action EventRoundEnd(Handle event, const char [] name, bool dontBroadcast)
{
	if(g_currentRoundSpecial == RoundType_Warmup)
		return Plugin_Continue;
	
	g_currentRoundSpecial = g_nextRoundSpecial;
	g_nextRoundSpecial = RoundType_None;
	
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char [] szWeapon)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_bInBuyZone") == 0)
		return Plugin_Continue;
	
	#if defined WARMUP
	if(Restrict_IsWarmupRound())
	{
		if(!g_bSpamProtectPrint[client])
		{
			PrintToChat(client, "\x01[\x04SM\x01]\x04 %T", "CannotBuyWarmup", client);
			g_bSpamProtectPrint[client] = true;
			CreateTimer(PRINTDELAY, ResetPrintDelay, client);
		}
		
		return Plugin_Handled;
	}
	#endif
	
	int iTeam = GetClientTeam(client);
	
	if(iTeam <= CS_TEAM_SPECTATOR)
		return Plugin_Continue;
	
	CSWeaponID id = Restrict_GetWeaponIDExtended(szWeapon);
	
	if(id == CSWeapon_NONE)
		return Plugin_Continue;
	
	int iBuyteam = CSWeapons_GetWeaponBuyTeam(id);
	
	if(iTeam != iBuyteam && iBuyteam != BOTH_TEAMS)
		return Plugin_Continue;
	
	CanBuyResult result = Restrict_CanBuyWeapon(client, iTeam, id);
	
	if(result == CanBuy_Block || result == CanBuy_BlockDontDisplay)
	{
		char szWeaponName[WEAPONARRAYSIZE];
		CSWeapons_GetAlias(id, szWeaponName, sizeof(szWeaponName), true);
		
		bool bWeaponTranslation = TranslationPhraseExists(szWeaponName);

		if(bWeaponTranslation)
		{
			if(iTeam == CS_TEAM_CT && result != CanBuy_BlockDontDisplay)
			{
				if(Restrict_IsSpecialRound() && !Restrict_AllowedForSpecialRound(id))
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "SpecialNotAllowed", client);
				else
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "IsRestrictedBuyCT", client, Restrict_GetRestrictValue(iTeam, id));
			}
			else if(iTeam == CS_TEAM_T && result != CanBuy_BlockDontDisplay)
			{	if(Restrict_IsSpecialRound() && !Restrict_AllowedForSpecialRound(id))
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "SpecialNotAllowed", client);
				else
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", szWeaponName, client, "IsRestrictedBuyT", client, Restrict_GetRestrictValue(iTeam, id));
			}
		}
		else
		{
			if(iTeam == CS_TEAM_CT && result != CanBuy_BlockDontDisplay)
			{
				if(Restrict_IsSpecialRound() && !Restrict_AllowedForSpecialRound(id))
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "SpecialNotAllowed", client);
				else
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "IsRestrictedBuyCT", client, Restrict_GetRestrictValue(iTeam, id));
			}
			else if(iTeam == CS_TEAM_T && result != CanBuy_BlockDontDisplay)
			{	if(Restrict_IsSpecialRound() && !Restrict_AllowedForSpecialRound(id))
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "SpecialNotAllowed", client);
				else
					PrintToChat(client, "\x01[\x04SM\x01]\x04 %s %T", szWeaponName, client, "IsRestrictedBuyT", client, Restrict_GetRestrictValue(iTeam, id));
			}
		}
		
		Restrict_PlayRestrictSound(client, id);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}