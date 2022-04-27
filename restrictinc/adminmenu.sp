int g_iMenuAmount[MAXPLAYERS+1];
CSWeaponID g_iWeaponSlected[MAXPLAYERS+1];
WeaponType g_iGroupSelected[MAXPLAYERS+1];
bool g_bIsGroup[MAXPLAYERS+1];
bool g_bIsUnrestrict[MAXPLAYERS+1];

public void OnLibraryRemoved(const char [] name)
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = null;
	}
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = view_as<TopMenu>(topmenu);
	
	TopMenuObject menuObject = hAdminMenu.FindCategory("restrict");
	
	if (menuObject == INVALID_TOPMENUOBJECT )
	{
		menuObject = hAdminMenu.AddCategory("restrict", Handle_Category);
	}
	
	hAdminMenu.AddItem("sm_restrict", AdminMenu_Restrict, menuObject, "sm_restrict", ADMFLAG_CONVARS);
	hAdminMenu.AddItem("sm_unrestrict", AdminMenu_Unrestrict, menuObject, "sm_unrestrict", ADMFLAG_CONVARS);
	hAdminMenu.AddItem("sm_dropc4", AdminMenu_dropc4, menuObject, "sm_dropc4", ADMFLAG_BAN);
	hAdminMenu.AddItem("sm_knives", AdminMenu_Knives, menuObject, "sm_knives", ADMFLAG_CONVARS);
	hAdminMenu.AddItem("sm_pistols", AdminMenu_Pistols, menuObject, "sm_pistols", ADMFLAG_CONVARS);
}

public void Handle_Category(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char [] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "RestrictMenuMainTitle", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "RestrictMenuMainOption", param);
	}
}

public void AdminMenu_Restrict(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char [] buffer, int maxlength )
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "RestrictWeaponsOption", param);
		case TopMenuAction_SelectOption:
		{
			g_bIsUnrestrict[param] = false;
			DisplayTypeMenu(param);
		}
	}
}

public void AdminMenu_Unrestrict(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char [] buffer, int maxlength )
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "UnrestrictWeaponsOption", param);
		case TopMenuAction_SelectOption:
		{
			g_bIsUnrestrict[param] = true;
			g_iMenuAmount[param] = -1;
			DisplayTypeMenu(param);
		}
	}
}

public void AdminMenu_dropc4(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char [] buffer, int maxlength )
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "ForceBombDropOption", param);
		case TopMenuAction_SelectOption:
			DropC4(param, 0);
	}
}

public void AdminMenu_Knives(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char [] buffer, int maxlength )
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "SetupKnivesOption", param);
		case TopMenuAction_SelectOption:
			KnifeRound(param, 0);
	}
}

public void AdminMenu_Pistols(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char [] buffer, int maxlength )
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "SetupPistolsOption", param);
		case TopMenuAction_SelectOption:
			PistolRound(param, 0);
	}
}

void DisplayTypeMenu(int client)
{
	Menu menu = CreateMenu(Handle_TypeMenu);
	
	char title[64];
	
	Format(title, sizeof(title), "%T", "RestrictionTypeMenuTitle", client);

	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	Format(title, sizeof(title), "%T", "TypeWeaponRestrict", client);
	menu.AddItem("0", title);
	
	Format(title, sizeof(title), "%T", "TypeGroupRestrict", client);
	menu.AddItem("1", title);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_TypeMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != null)
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			char type[5];
			GetMenuItem(menu, param2, type, sizeof(type));
			g_bIsGroup[param1] = view_as<bool>(StringToInt(type));
			DisplayRestrictMenu(param1);
		}
	}
}

void DisplayRestrictMenu(int client)
{
	Menu menu = CreateMenu(Handle_WeaponMenu);
	
	char title[64];
	
	if(!g_bIsUnrestrict[client])
		Format(title, sizeof(title), "%T", "RestrictMenuTitle", client);
	else
		Format(title, sizeof(title), "%T", "UnrestrictMenuTitle", client);

	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	if(g_bIsGroup[client])
		AddGroupsToMenu(menu, client);
	else
		AddWeaponsToMenu(menu, client);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_WeaponMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != null)
				DisplayTypeMenu(param1);
		}
		case MenuAction_Select:
		{
			char weapon[WEAPONARRAYSIZE];
			GetMenuItem(menu, param2, weapon, sizeof(weapon));
			if(g_bIsGroup[param1])
				g_iGroupSelected[param1] = GetTypeGroup(weapon);
			else
				g_iWeaponSlected[param1] = CS_AliasToWeaponID(weapon);
		
			if(g_bIsGroup[param1] && g_bIsUnrestrict[param1])
			{
				DisplayTeamMenu(param1);
			}
			else if(!g_bIsUnrestrict[param1])
			{
				DisplayAmountMenu(param1);
			}
			else
			{
				DisplayTeamMenu(param1);
			}
		}
	}
}

void DisplayAmountMenu(int client)
{
	Menu menu = CreateMenu(Handle_AmountMenu);
	
	char title[64];
	
	Format(title, sizeof(title), "%T", "AmountMenuTitle", client);

	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	char num[5];
	for(int i = 0; i <= MaxClients; i++)
	{
		Format(num, sizeof(num), "%i", i);
		AddMenuItem(menu, num, num);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayTeamMenu(int client)
{
	Menu menu = CreateMenu(Handle_TeamMenu);
	
	char title[64];
	
	Format(title, sizeof(title), "%T", "SelectTeamMenuTitle", client);

	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	Format(title, sizeof(title), "%T", "CounterTerrorists", client);
	AddMenuItem(menu, "3", title);
	
	Format(title, sizeof(title), "%T", "Terrorists", client);
	AddMenuItem(menu, "2", title);
	
	Format(title, sizeof(title), "%T", "Allteams", client);
	
	char szBothTeams[4];
	IntToString(BOTH_TEAMS, szBothTeams, sizeof(szBothTeams));
	
	AddMenuItem(menu, szBothTeams, title);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_TeamMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != null)
			{
				if(!g_bIsUnrestrict[param1])
					DisplayAmountMenu(param1);
				else
					DisplayRestrictMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char sTeam[5];
			GetMenuItem(menu, param2, sTeam, sizeof(sTeam));
			
			int team = StringToInt(sTeam);
			
			if(!g_bIsGroup[param1])
				HandleMenuRestriction(param1, g_iWeaponSlected[param1], g_iMenuAmount[param1], team);
			else
				HandleMenuGroupRestriction(param1, g_iGroupSelected[param1], g_iMenuAmount[param1], team);
		}
	}
}

public int Handle_AmountMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hAdminMenu != null)
				DisplayRestrictMenu(param1);
		}
		case MenuAction_Select:
		{
			char amount[10];
			GetMenuItem(menu, param2, amount, sizeof(amount));
			g_iMenuAmount[param1] = StringToInt(amount);
			DisplayTeamMenu(param1);
		}
	}
}

stock void HandleMenuRestriction(int client, CSWeaponID id, int amount, int team)
{
	char szWeaponName[WEAPONARRAYSIZE];
	
	CSWeapons_GetAlias(id, szWeaponName, sizeof(szWeaponName), true);
	
	if(amount != -1)
	{
		if(team == 3 || team == BOTH_TEAMS)
		{
			Restrict_SetRestriction(id, CS_TEAM_CT, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", szWeaponName, "ToAmount", amount, "ForCT");
		}
		if(team == 2 || team == BOTH_TEAMS)
		{
			Restrict_SetRestriction(id, CS_TEAM_T, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", szWeaponName, "ToAmount", amount, "ForT");
		}
	}
	else
	{
		if(team == 3 || team == BOTH_TEAMS)
		{
			Restrict_SetRestriction(id, CS_TEAM_CT, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", szWeaponName, "ForCT");
		}
		if(team == 2 || team == BOTH_TEAMS)
		{
			Restrict_SetRestriction(id, CS_TEAM_T, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", szWeaponName, "ForT");
		}
	}
}

stock void HandleMenuGroupRestriction(int client, WeaponType group, int amount, int team)
{
	if(group == WeaponTypeNone)
	{
		for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
		{
			if(!CSWeapons_IsValidID(view_as<CSWeaponID>(i), true))
				continue;
			
			Restrict_SetRestriction(view_as<CSWeaponID>(i), CS_TEAM_CT, amount, true);
			Restrict_SetRestriction(view_as<CSWeaponID>(i), CS_TEAM_T, amount, true);
		}
		if(amount != -1)
		{
			ShowActivity2(client, ADMINCOMMANDTAG, "%t", "RestrictedAll");
		}
		else
		{
			ShowActivity2(client, ADMINCOMMANDTAG, "%t", "UnrestrictedAll");
		}
		return;
	}
	if(amount != -1)
	{
		if(team == 3 || team == BOTH_TEAMS)
		{
			Restrict_SetGroupRestriction(group, CS_TEAM_CT, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ToAmount", amount, "ForCT");
		}
		if(team == 2 || team == BOTH_TEAMS)
		{
			Restrict_SetGroupRestriction(group, CS_TEAM_T, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t %t", "RestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ToAmount", amount, "ForT");
		}
	}
	else
	{
		if(team == 3 || team == BOTH_TEAMS)
		{
			Restrict_SetGroupRestriction(group, CS_TEAM_CT, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ForCT");
		}
		if(team == 2 || team == BOTH_TEAMS)
		{
			Restrict_SetGroupRestriction(group, CS_TEAM_T, amount, true);
			ShowActivity2(client, ADMINCOMMANDTAG, "%t %t %t", "UnrestrictedCmd", g_WeaponGroupNames[view_as<int>(group)], "ForT");
		}
	}
}

void AddGroupsToMenu(Menu menu, int client)
{
	static char groupArray[MAXWEAPONGROUPS][WEAPONARRAYSIZE];
	static int size = -1;
	
	if(size == -1)
	{
		for(int i = 0; i < MAXWEAPONGROUPS; i++)
		{
			strcopy(groupArray[i], WEAPONARRAYSIZE, g_WeaponGroupNames[i]);
		}
		
		size = sizeof(groupArray);
		
		SortStrings(groupArray, size, Sort_Ascending);
	}
	
	char weapon[WEAPONARRAYSIZE];
	Format(weapon, sizeof(weapon), "%T", "AllWeapons", client);
	AddMenuItem(menu, "all", weapon);
	
	for(int i = 0; i < size; i++)
	{
		Format(weapon, sizeof(weapon), "%T", groupArray[i], client); 
		AddMenuItem(menu, groupArray[i], weapon);
	}
}

void AddWeaponsToMenu(Menu menu, int client)
{
	static int size = -1;
	
	char szWeaponName[WEAPONARRAYSIZE];
	
	if(size == -1)
	{
		size = hWeaponNameList.Length;
		
		char [][] szWeaponArray = new char[size][WEAPONARRAYSIZE];
		
		for(int i = 0; i < size; i++)
		{
			hWeaponNameList.GetString(i, szWeaponName, sizeof(szWeaponName));
			strcopy(szWeaponArray[i], WEAPONARRAYSIZE, szWeaponName);
		}
		
		SortStrings(szWeaponArray, size, Sort_Ascending);
		
		hWeaponNameList.Clear();
		
		for(int i = 0; i < size; i++)
		{
			hWeaponNameList.PushString(szWeaponArray[i]);
		}
	}
	
	char szAlias[WEAPONARRAYSIZE];
	
	for(int i = 0; i < size; i++)
	{
		hWeaponNameList.GetString(i, szAlias, sizeof(szAlias));
		Format(szWeaponName, sizeof(szWeaponName), "%T", szAlias, client);

		AddMenuItem(menu, szAlias, szWeaponName);
	}
}