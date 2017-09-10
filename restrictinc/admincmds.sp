void RegisterAdminCommands()
{
	RegAdminCmd("sm_restrict", RestrictAdminCmd, ADMFLAG_CONVARS, "Restrict weapons");
	RegAdminCmd("sm_unrestrict", UnrestrictAdminCmd, ADMFLAG_CONVARS, "Unrestrict weapons");
	RegAdminCmd("sm_knives", KnifeRound, ADMFLAG_CONVARS, "Sets up a knife round.");
	RegAdminCmd("sm_pistols", PistolRound, ADMFLAG_CONVARS, "Sets up a pistol round.");
	RegAdminCmd("sm_dropc4", DropC4, ADMFLAG_BAN, "Forces bomb drop");
	RegAdminCmd("sm_reload_restrictions", ReloadRestrict, ADMFLAG_CONVARS, "Reloads all restricted weapon cvars and removes any admin overrides");
	RegAdminCmd("sm_remove_restricted", RemoveRestricted, ADMFLAG_CONVARS, "Removes restricted weapons from players to the limit the weapons are set to.");
}

public Action RemoveRestricted(int client, int args)
{
	LogAction(client, -1, "\"%L\" removed all restricted weapons", client);
	ShowActivity2(client, ADMINCOMMANDTAG, "%t", "RemovedRestricted");
	Restrict_CheckPlayerWeapons();
	
	return Plugin_Handled;
}

stock bool HandleRestrictionCommand(int client, char [] szWeapon, int iTeam = BOTH_TEAMS, int iAmount = -1, bool bAll = false)
{
	CSWeaponID id = CSWeapon_NONE;
	
	if(StrEqual(szWeapon, "@all", false) || StrEqual(szWeapon, "all", false))
	{
		for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS); i++)
		{
			id = view_as<CSWeaponID>(i);
			
			if(CSWeapons_IsValidID(id))
			{
				Restrict_SetRestriction(id, CS_TEAM_CT, iAmount, true);
				Restrict_SetRestriction(id, CS_TEAM_T, iAmount, true);
			}
		}
		if(iAmount != -1)
		{
			ShowActivity2(client, ADMINCOMMANDTAG, "%t", "RestrictedAll");
		}
		else
		{
			ShowActivity2(client, ADMINCOMMANDTAG, "%t", "UnrestrictedAll");
		}
		return true;
	}
	else if(!bAll)
	{
		int len = strlen(szWeapon);
		
		for(int i = 0; i < len; i++)
		{
			szWeapon[i] = CharToLower(szWeapon[i]);
		}
		
		id = Restrict_GetWeaponIDExtended(szWeapon);
		WeaponType group = GetTypeGroup(szWeapon);//For group restrictions.
		
		if(id == CSWeapon_NONE && group == WeaponTypeNone)
		{
			ReplyToCommand(client, "%T", "InvalidWeapon", client);
			return false;
		}
		
		char szWeaponName[WEAPONARRAYSIZE];
		
		if(id != CSWeapon_NONE)
			CSWeapons_GetAlias(id, szWeaponName, sizeof(szWeaponName), true);
		
		if(iAmount != -1)
		{
			if(iTeam == CS_TEAM_CT || iTeam == BOTH_TEAMS)
			{
				if(group == WeaponTypeNone && Restrict_SetRestriction(id, CS_TEAM_CT, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", szWeaponName, "ToAmount", iAmount, "ForCT");
				else if(id == CSWeapon_NONE && Restrict_SetGroupRestriction(group, CS_TEAM_CT, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ToAmount", iAmount, "ForCT");
			}
			if(iTeam == CS_TEAM_T || iTeam == BOTH_TEAMS)
			{
				if(group == WeaponTypeNone && Restrict_SetRestriction(id, CS_TEAM_T, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", szWeaponName, "ToAmount", iAmount, "ForT");
				else if(id == CSWeapon_NONE && Restrict_SetGroupRestriction(group, CS_TEAM_T, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ToAmount", iAmount, "ForT");
			}
		}
		else
		{
			if(iTeam == CS_TEAM_CT || iTeam == BOTH_TEAMS)
			{
				if(group == WeaponTypeNone && Restrict_SetRestriction(id, CS_TEAM_CT, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", szWeaponName, "ForCT");
				else if(id == CSWeapon_NONE && Restrict_SetGroupRestriction(group, CS_TEAM_CT, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ForCT");
			}
			if(iTeam == CS_TEAM_T || iTeam == BOTH_TEAMS)
			{
				if(group == WeaponTypeNone && Restrict_SetRestriction(id, CS_TEAM_T, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", szWeaponName, "ForT");
				else if(id == CSWeapon_NONE && Restrict_SetGroupRestriction(group, CS_TEAM_T, iAmount, true))
					ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ForT");
			}
		}
		return true;
	}
	return false;
}

public Action RestrictAdminCmd(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "RestrictReply", client);
		return Plugin_Handled;
	}
	
	char szWeapon[WEAPONARRAYSIZE];
	GetCmdArg(1, szWeapon, sizeof(szWeapon));
	
	if(args == 1)
	{
		if(!HandleRestrictionCommand(client, szWeapon, BOTH_TEAMS, 0, true))
			ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "RestrictReply", client);
		return Plugin_Handled;
	}
	
	int iAmount = 0;
	if(args >= 2)
	{
		char szAmountString[10];
		GetCmdArg(2, szAmountString, sizeof(szAmountString));
		
		iAmount = StringToInt(szAmountString);
		
		if((iAmount == 0 && !StrEqual(szAmountString, "0")) || iAmount < -1)
		{
			ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "InvalidAmount", client);
			return Plugin_Handled;
		}
	}
	
	int iTeam = BOTH_TEAMS;
	if(args == 3)
	{
		char szTeam[10];
		GetCmdArg(3, szTeam, sizeof(szTeam));
		
		if(StrEqual(szTeam, "both", false))
			iTeam = BOTH_TEAMS;
		else if(StrEqual(szTeam, "ct", false))
			iTeam = CS_TEAM_CT;
		else if(StrEqual(szTeam, "t", false))
			iTeam = CS_TEAM_T;
		else
		{
			ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "InvalidTeam", client);
			return Plugin_Handled;
		}
	}
	
	HandleRestrictionCommand(client, szWeapon, iTeam, iAmount, false);
	
	return Plugin_Handled;
}

public Action UnrestrictAdminCmd(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "UnrestrictReply", client);
		return Plugin_Handled;
	}
	
	char szWeapon[WEAPONARRAYSIZE];
	GetCmdArg(1, szWeapon, sizeof(szWeapon));
	
	if(args == 1)
	{
		if(!HandleRestrictionCommand(client, szWeapon, BOTH_TEAMS, -1, true) && !HandleRestrictionCommand(client, szWeapon, BOTH_TEAMS, -1, false))
			ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "UnrestrictReply", client);
		
		return Plugin_Handled;
	}
	
	int iTeam = BOTH_TEAMS;
	if(args == 2)
	{
		char szTeam[10];
		GetCmdArg(3, szTeam, sizeof(szTeam));
		
		if(StrEqual(szTeam, "both", false))
			iTeam = BOTH_TEAMS;
		else if(StrEqual(szTeam, "ct", false))
			iTeam = CS_TEAM_CT;
		else if(StrEqual(szTeam, "t", false))
			iTeam = CS_TEAM_T;
		else
		{
			ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "InvalidTeam", client);
			return Plugin_Handled;
		}
	}
	
	HandleRestrictionCommand(client, szWeapon, iTeam, -1, false);
	
	return Plugin_Handled;
}

public Action DropC4(int client, int args)
{
	int bomb = -1;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if((bomb = GetPlayerWeaponSlot(i, view_as<int>(SlotC4))) != -1)
		{
			CS_DropWeapon(i, bomb, true, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t", "ForcedBombDrop");
			LogAction(client, -1, "\"%L\" forced the C4 bomb to be dropped.", client);
			return Plugin_Handled;
		}
	}
	
	ReplyToCommand(client, "%T", "NoOneHasBomb", client);
	
	return Plugin_Handled;
}

public Action KnifeRound(int client, int args)
{
	if(g_nextRoundSpecial != RoundType_None)
	{
		ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "SpecialRoundAlreadySet", client);
		return Plugin_Handled;
	}
	
	ShowActivity2(client, ADMINCOMMANDTAG, "%t", "KnivesRoundSetup");
	LogAction(client, -1, "\"%L\" setup a knives only round for the next round.", client);	
	
	g_nextRoundSpecial = RoundType_Knife;
	
	return Plugin_Handled;
}

public Action PistolRound(int client, int args)
{
	if(g_nextRoundSpecial != RoundType_None)
	{
		ReplyToCommand(client, "\x01[\x04SM\x01]\x04 %T", "SpecialRoundAlreadySet", client);
		return Plugin_Handled;
	}
	
	ShowActivity2(client, ADMINCOMMANDTAG, "%t", "PistolRoundSetup");
	LogAction(client, -1, "\"%L\" setup a pistol round for the next round.", client);
	
	g_nextRoundSpecial = RoundType_Pistol;
	
	return Plugin_Handled;
}

public Action ReloadRestrict(int client, int args)
{
	ClearOverride();
	
	CreateTimer(0.1, LateLoadExec, _, TIMER_FLAG_NO_MAPCHANGE);
	
	ShowActivity2(client, ADMINCOMMANDTAG, "%t", "ReloadedRestricitions");
	LogAction(client, -1, "\"%L\" reloaded the restrictions.", client);
	
	#if defined CONFIGLOADER
	CheckConfig();
	#endif
	
	#if defined PERPLAYER
	PerPlayerInit();
	CheckPerPlayer();
	#endif
	
	return Plugin_Handled;
}