RegisterAdminCommands()
{
	RegAdminCmd("sm_restrict", RestrictAdminCmd, ADMFLAG_CONVARS, "Restrict weapons");
	RegAdminCmd("sm_unrestrict", UnrestrictAdminCmd, ADMFLAG_CONVARS, "Unrestrict weapons");
	RegAdminCmd("sm_knives", KnifeRound, ADMFLAG_CONVARS, "Sets up a knife round.");
	RegAdminCmd("sm_pistols", PistolRound, ADMFLAG_CONVARS, "Sets up a pistol round.");
	RegAdminCmd("sm_dropc4", DropC4, ADMFLAG_BAN, "Forces bomb drop");
	RegAdminCmd("sm_reload_restrictions", ReloadRestrict, ADMFLAG_CONVARS, "Reloads all restricted weapon cvars and removes any admin overrides");
	RegAdminCmd("sm_remove_restricted", RemoveRestricted, ADMFLAG_CONVARS, "Removes restricted weapons from players to the limit the weapons are set to.");
}
public Action:RemoveRestricted(client, args)
{
	decl String:username[MAX_NAME_LENGTH];
	if(client != 0 && IsClientInGame(client))
	{
		GetClientName(client, username, sizeof(username));
	}
	else
	{
		username = "Console";
	}
	
	LogAction(client, -1, "\"%L\" removed all restricted weapons", client);
	PrintToChatAll("\x04[SM] %s %t", username, "RemovedRestricted");
	CheckPlayersWeapons();
	return Plugin_Handled;
}
public Action:RestrictAdminCmd(client, args)
{
	new ammount;
	new String:weapon[100];
	new String:ammountstring[4];
	new valuect;
	new valuet;
	if(args == 1)
	{
		GetCmdArg(1, weapon, sizeof(weapon));
		if(StrEqual(weapon, "@all", false))
		{
			RestrictAllWeapons(client);
		}
		else
		{
			ReplyToCommand(client, "%t", "RestrictReply");
		}
		return Plugin_Handled;
	}
	else if(args < 2)
	{
		ReplyToCommand(client, "%t", "RestrictReply");
		return Plugin_Handled;
	}
	GetCmdArg(1, weapon, sizeof(weapon));
	new len = strlen(weapon);
	for(new i = 0; i < len; i++)
	{
		weapon[i] = CharToLower(weapon[i]);
	}
	if(GetTrieValue(WeaponTrieCT, weapon, valuect) || GetTrieValue(WeaponTrieT, weapon, valuet))// valid weapon we need to do something.
	{
		GetCmdArg(2, ammountstring, sizeof(ammountstring));
		ammount = StringToInt(ammountstring);
		if(ammount == 0 && !StrEqual(ammountstring, "0"))
		{
			ReplyToCommand(client, "%t", "InvalidAmmount");
			return Plugin_Handled;
		}
		if(args == 2)
		{
			RestrictWeaponCmd(client, weapon, ammount, 0);
		}
		else
		{
			decl String:team[10];
			GetCmdArg(3, team, sizeof(team));
			if(StrEqual(team, "ct", false))
				RestrictWeaponCmd(client, weapon, ammount, CT_TEAM);
			else if(StrEqual(team, "t", false))
				RestrictWeaponCmd(client, weapon, ammount, T_TEAM);
			else if(StrEqual(team, "all", false))
				RestrictWeaponCmd(client, weapon, ammount, 0);
			else
				ReplyToCommand(client, "%t", "InvalidTeam");
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "InvalidWeapon");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:UnrestrictAdminCmd(client, args)
{
	new String:weapon[100];
	new valuect;
	new valuet;
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "UnrestrictReply");
		return Plugin_Handled;
	}
	GetCmdArg(1, weapon, sizeof(weapon));
	if(StrEqual(weapon, "@all", false))
	{
		UnrestrictAllWeapons(client);
		return Plugin_Handled;
	}
	new len = strlen(weapon);
	for(new i = 0; i < len; i++)
	{
		weapon[i] = CharToLower(weapon[i]);
	}
	if(GetTrieValue(WeaponTrieCT, weapon, valuect) || GetTrieValue(WeaponTrieT, weapon, valuet))// valid weapon we need to do something.
	{
		if(args == 1)
		{
			RestrictWeaponCmd(client, weapon, -1, 0);
		}
		else
		{
			decl String:team[10];
			GetCmdArg(2, team, sizeof(team));
			if(StrEqual(team, "ct", false))
				RestrictWeaponCmd(client, weapon, -1, CT_TEAM);
			else if(StrEqual(team, "t", false))
				RestrictWeaponCmd(client, weapon, -1, T_TEAM);
			else if(StrEqual(team, "all", false))
				RestrictWeaponCmd(client, weapon, -1, 0);
			else
				ReplyToCommand(client, "%t", "InvalidTeam");
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "InvalidWeapon");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:DropC4(client, args)
{
	new bomb;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != T_TEAM)
			continue;
		
		bomb = GetPlayerWeaponSlot(i, 4);
		
		if(bomb != -1 && IsClientInGame(i))
		{
			SDKCall(weaponDrop, i, bomb, true, true);
			if(client > 0)
			{
				PrintToChatAll("\x04[SM] %N %t", client, "ForcedBombDrop");
				LogAction(client, -1, "\"%L\" forced the C4 bomb to be dropped.", client);
			}
			else
			{
				PrintToChatAll("\x04%t", "ConsoleBombDrop");
				LogAction(client, -1, "\"%L\" forced the C4 bomb to be dropped.", client);
			}
			return Plugin_Handled;
		}
	}
	
	ReplyToCommand(client, "%t", "NoOneHasBomb");
	
	return Plugin_Handled;
}
RestrictWeaponCmd(client, String:weapon[100], ammount, teamnum)
{
	new valuect;
	new valuet;
	new bool:changed;
	
	if(GetTrieValue(WeaponTrieCT, weapon, valuect) && (teamnum == CT_TEAM || teamnum == 0))
	{
		SetTrieValue(WeaponTrieCT, weapon, ammount);
		changed = true;
	}
	if(GetTrieValue(WeaponTrieT, weapon, valuet) && (teamnum == T_TEAM || teamnum == 0))
	{
		SetTrieValue(WeaponTrieT, weapon, ammount);
		changed = true;
	}
	if(changed)
	{
		//admin override time
		new overrideteam;
		if(GetTrieValue(AdminOverride, weapon, overrideteam))
		{
			if(overrideteam != teamnum && overrideteam != 0)
			{
				SetTrieValue(AdminOverride, weapon, 0);
			}
		}
		else
		{
			SetTrieValue(AdminOverride, weapon, teamnum);
		}
		
		decl String:username[MAX_NAME_LENGTH];
		decl String:action[15];
		decl String:action2[15];
		if(client != 0 && IsClientInGame(client))
		{
			GetClientName(client, username, sizeof(username));
		}
		else
		{
			username = "Console";
		}
		
		if(teamnum == T_TEAM)
		{
			action = "ForTeamT";
			action2 = "for t";
		}
		else if(teamnum == CT_TEAM)
		{
			action = "ForTeamCT";
			action2 = "for ct";
		}
		
		if(ammount >=0 && (teamnum == T_TEAM || teamnum == CT_TEAM))
		{
			LogAction(client, -1, "\"%L\" restricted %s to %i %s.", client, weapon, ammount, action2);
			PrintToChatAll("\x04[SM] %s %t %i %t", username, "RestrictedWeapon", weapon, ammount, action);
		}
		else if((teamnum == T_TEAM || teamnum == CT_TEAM))
		{
			LogAction(client, -1, "\"%L\" unrestricted %s %s", client, weapon, action2);
			PrintToChatAll("\x04[SM] %s %t %s %t", username, "UnrestrictedWeapon", weapon, action);
		}
		else
		{
			if(ammount < 0)
			{
				LogAction(client, -1, "\"%L\" unrestricted %s", client, weapon);
				PrintToChatAll("\x04[SM] %s %t %s", username, "UnrestrictedWeapon", weapon);
			}
			else
			{
				LogAction(client, -1, "\"%L\" restricted %s to %i", client, weapon, ammount);
				PrintToChatAll("\x04[SM] %s %t %i", username, "RestrictedWeapon", weapon, ammount);
			}
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "InvalidTeam");
	}
}
public Action:KnifeRound(client, args)
{
	if(pistols)
	{
		ReplyToCommand(client, "%t", "PistolsAlreadySet");
		return Plugin_Handled;
	}
	else if(warmup)
	{
		ReplyToCommand(client, "%t", "WarmupInProgress");
		return Plugin_Handled;
	}
	if(client > 0 && IsClientInGame(client))
	{
		new String:name[124];
		GetClientName(client, name, sizeof(name));
		LogAction(client, -1, "\"%L\" setup a knife round.", client);
		PrintToChatAll("\x04[SM] %s %t", name, "KnifeRoundSetup");
	}
	else
	{
		PrintToChatAll("\x04%t", "NextRoundKnife");
	}
	knives = true;
	return Plugin_Handled;
}
public Action:PistolRound(client, args)
{
	if(knives)
	{
		ReplyToCommand(client, "%t", "KnivesAlreadySet");
		return Plugin_Handled;
	}
	else if(warmup)
	{
		ReplyToCommand(client, "%t", "WarmupInProgress");
		return Plugin_Handled;
	}
	if(client > 0 && IsClientInGame(client))
	{
		new String:name[124];
		GetClientName(client, name, sizeof(name));
		LogAction(client, -1, "\"%L\" setup a pistol round.", client);
		PrintToChatAll("\x04[SM] %s %t", name, "PistolsRoundSetup");
	}
	else
	{
		PrintToChatAll("\x04%t", "NextRoundPistols");
	}
	pistols = true;
	return Plugin_Handled;
}
UnrestrictAllWeapons(client)
{
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		if(!StrEqual(g_WeaponNames[i], "knife", false))
		{
			if(!StrEqual(g_WeaponNames[i], "c4", false))
				SetTrieValue(WeaponTrieCT, g_WeaponNames[i], -1);
			
			if(!StrEqual(g_WeaponNames[i], "defuser", false))
				SetTrieValue(WeaponTrieT, g_WeaponNames[i], -1);
			
			SetTrieValue(AdminOverride, g_WeaponNames[i], 0);
		}
	}
	if(client > 0 && IsClientInGame(client))
	{
		new String:name[124];
		GetClientName(client, name, sizeof(name));
		LogAction(client, -1, "\"%L\" unrestricted all weapons.", client);
		PrintToChatAll("\x04[SM] %s %t", name, "UnrestrictedAll");
	}
	else
	{
		PrintToChatAll("\x04%t", "AllUnrestricted");
	}
}
RestrictAllWeapons(client)
{
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		if(!StrEqual(g_WeaponNames[i], "knife", false) && !StrEqual(g_WeaponNames[i], "c4", false) && !StrEqual(g_WeaponNames[i], "defuser", false))
		{
			SetTrieValue(WeaponTrieCT, g_WeaponNames[i], 0);
			SetTrieValue(WeaponTrieT, g_WeaponNames[i], 0);
			SetTrieValue(AdminOverride, g_WeaponNames[i], 0);
		}
	}
	if(client > 0 && IsClientInGame(client))
	{
		new String:name[124];
		GetClientName(client, name, sizeof(name));
		LogAction(client, -1, "\"%L\" restricted all weapons.", client);
		PrintToChatAll("\x04[SM] %s %t", name, "RestrictedAll");
	}
	else
	{
		PrintToChatAll("\x04%t", "AllRestricted");
	}
}
public Action:ReloadRestrict(client, args)
{
	decl String:username[MAX_NAME_LENGTH];
	if(client != 0 && IsClientInGame(client))
	{
		GetClientName(client, username, sizeof(username));
	}
	else
	{
		username = "Console";
	}
	if(AdminOverride != INVALID_HANDLE)
	{
		ClearTrie(AdminOverride);
	}
	OnMapEnd();
	CreateTimer(0.1, LateLoadExec, _, TIMER_FLAG_NO_MAPCHANGE);
	
	LogAction(client, -1, "\"%L\" reset all restrictions and overrides", client);
	PrintToChatAll("\x04[SM] %s %t", username, "ResetRestrictions");
	
	return Plugin_Handled;
}