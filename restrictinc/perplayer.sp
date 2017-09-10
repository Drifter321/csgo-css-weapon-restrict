static int g_iDefaultValues[CSWeapon_MAX_WEAPONS_NO_KNIFES][CVarTeam_MAX];
static CSWeaponID g_iCurrentID = CSWeapon_NONE;
static bool g_bIsFirstKey = true;
static int g_iLastVal = -1;
static int g_iLastIndex = 0;
static int g_iPerPlayer[CSWeapon_MAX_WEAPONS_NO_KNIFES][MAXPLAYERS+1];
bool g_bPerPlayerReady = false;

enum
{
	InvalidWeapon = -3,
	UninitializedWeapon = -2
};

void PerPlayerInit()
{
	for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		if(!CSWeapons_IsValidID(view_as<CSWeaponID>(i), true))
		{
			g_iPerPlayer[i][0] = InvalidWeapon;
			continue;
		}
		
		for(int x = 0; x <= MAXPLAYERS; x++)
		{
			g_iPerPlayer[i][x] = UninitializedWeapon;
		}
	}
	
	for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		if(g_iPerPlayer[i][0] == InvalidWeapon)
			continue;
		
		g_iDefaultValues[i][CVarTeam_T] = Restrict_GetRestrictValue(CS_TEAM_T, view_as<CSWeaponID>(i));
		g_iDefaultValues[i][CVarTeam_CT] = Restrict_GetRestrictValue(CS_TEAM_CT, view_as<CSWeaponID>(i));
	}
	
	char szPerPlayerFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPerPlayerFile, sizeof(szPerPlayerFile), "configs/restrict/perplayerrestrict.txt");
	
	if(!FileExists(szPerPlayerFile))
	{
		LogError("Failed to locate perplayer.txt");
		return;
	}
	
	Handle parser = SMC_CreateParser();
	int line = 0;
	int col = 0;
	
	SMC_SetReaders(parser, Perplayer_NewSection, Perplayer_KeyValue, Perplayer_EndSection);
	SMC_SetParseEnd(parser, Perplayer_ParseEnd);
	
	SMCError error = SMC_ParseFile(parser, szPerPlayerFile, line, col);
	CloseHandle(parser);
	
	if(error)
	{
		char szErrorString[128];
		SMC_GetErrorString(error, szErrorString, sizeof(szErrorString));
		LogError("Perplayer parser error on line %i col %i. Error: %s", line, col, szErrorString);
		return;
	}
	
	g_bPerPlayerReady = true;
	#if defined DEBUG
	Perplayer_Debug(0);
	#endif
}

public Action Perplayer_Debug(int argc)
{
	int last;
	int lastval;
	for(int i = 0; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		if(g_iPerPlayer[i][0] == InvalidWeapon || g_iPerPlayer[i][0] == UninitializedWeapon)
			continue;
		else
		{
			last = 0;
			lastval = g_iPerPlayer[i][0];
			
			char szWeaponName[WEAPONARRAYSIZE];
			CSWeapons_GetAlias(view_as<CSWeaponID>(i), szWeaponName, sizeof(szWeaponName), true);
			
			for(int x = 1; x <= MAXPLAYERS; x++)
			{
				if(lastval != g_iPerPlayer[i][x])
				{
					PrintToServer("Between %i and %i %s will be restricted to %i", last, x-1, szWeaponName, lastval);
					lastval = g_iPerPlayer[i][x];
					last = x;
				}
				if(x == MAXPLAYERS)
				{
					PrintToServer("Between %i and %i %s will be restricted to %i", last, MAXPLAYERS, szWeaponName, lastval);
				}
			}
		}
	}
	return Plugin_Handled;
}

public SMCResult Perplayer_NewSection(Handle parser,const char [] section, bool quotes)
{
	if(StrEqual(section, "PerPlayer", false))
	{
		return SMCParse_Continue;
	}
	
	CSWeaponID id = Restrict_GetWeaponIDExtended(section);
	
	if(CSWeapons_IsValidID(id, true))
	{
		g_iCurrentID = id;
		g_bIsFirstKey = true;
		g_iLastIndex = 0;
	}
	else
	{
		LogError("Invalid section name found in perplayer.txt");
		return SMCParse_HaltFail;
	}
	return SMCParse_Continue;
}

public SMCResult Perplayer_KeyValue(Handle parser, const char [] key, const char [] value, bool key_quotes, bool value_quotes)
{
	if(g_bIsFirstKey)
	{
		if(StrEqual(key, "default", false))
		{
			g_bIsFirstKey = false;
			g_iLastVal = StringToInt(value);
			if(g_iLastVal < -1)
				g_iLastVal = -1;
		}
		else
		{
			return SMCParse_HaltFail;
		}
	}
	else
	{
		int index = StringToInt(key);
		
		if(index > MAXPLAYERS)
			index = MAXPLAYERS;
		
		for(int i = g_iLastIndex; i < index; i++)
		{
			g_iPerPlayer[g_iCurrentID][i] = g_iLastVal;
		}
		g_iLastVal = index;
		g_iLastVal = StringToInt(value);
		if(g_iLastVal < -1)
			g_iLastVal = -1;
	}
	return SMCParse_Continue;
}

public SMCResult Perplayer_EndSection(Handle parser)
{
	for(int i = g_iLastIndex; i <= MAXPLAYERS; i++)
	{
		g_iPerPlayer[g_iCurrentID][i] = g_iLastVal;
	}
	g_iCurrentID = CSWeapon_NONE;
	return SMCParse_Continue;
}

public void Perplayer_ParseEnd(Handle parser, bool halted, bool failed)
{
	if(failed)
	{
		LogError("Failed to parse Perplayer fully");
	}
}

void CheckPerPlayer()
{
	if(!g_bPerPlayerReady)
		return;
	
	int count = GetPerPlayerCount();
	
	bool bPerPlayer = hPerPlayerRestrict.BoolValue;
	
	for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		if(g_iPerPlayer[i][0] == InvalidWeapon)
			continue;
		
		if(bPerPlayer && g_iPerPlayer[i][0] == UninitializedWeapon)
			continue;
		
		int iRestrictValues[CVarTeam_MAX];
		
		if(bPerPlayer)
		{
			iRestrictValues[CVarTeam_CT] = iRestrictValues[CVarTeam_T] = g_iPerPlayer[i][count];
		}
		else
		{
			iRestrictValues[CVarTeam_CT] = g_iDefaultValues[i][CVarTeam_CT];
			iRestrictValues[CVarTeam_T] = g_iDefaultValues[i][CVarTeam_T];
		}
		
		if(Restrict_GetRestrictValue(CS_TEAM_T, view_as<CSWeaponID>(i)) != iRestrictValues[CVarTeam_T] && !Restrict_IsWeaponInOverride(CS_TEAM_T, view_as<CSWeaponID>(i)))
		{
			Restrict_SetRestriction(view_as<CSWeaponID>(i), CS_TEAM_T, iRestrictValues[CVarTeam_T], false);
		}
		
		if(Restrict_GetRestrictValue(CS_TEAM_CT, view_as<CSWeaponID>(i)) != iRestrictValues[CVarTeam_CT] && !Restrict_IsWeaponInOverride(CS_TEAM_CT, view_as<CSWeaponID>(i)))
		{
			Restrict_SetRestriction(view_as<CSWeaponID>(i), CS_TEAM_CT, iRestrictValues[CVarTeam_CT], false);
		}
	}
}

int GetPerPlayerCount()
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || (!hPerPlayerBots.BoolValue && IsFakeClient(i)) || (!hPerPlayerSpecs.BoolValue && (GetClientTeam(i) == CS_TEAM_NONE || GetClientTeam(i) == CS_TEAM_SPECTATOR)))
			continue;
		
		count++;
	}
	return count;
}