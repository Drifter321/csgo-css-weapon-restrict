/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////
new String:MenuAmmount[MAXPLAYERS+1];
new String:WeaponSelectedMenu[MAXPLAYERS+1];
new bool:unrestrict[MAXPLAYERS+1];
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, "restrict");
	
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		player_commands = AddToTopMenu(
		hAdminMenu,		// Menu
		"restrict",		// Name
		TopMenuObject_Category,	// Type
		Handle_Category,	// Callback
		INVALID_TOPMENUOBJECT	// Parent
		);
	}
	
	AddToTopMenu(hAdminMenu,
	"sm_restrict",
	TopMenuObject_Item,
	AdminMenu_Restrict,
	player_commands,
	"sm_restrict",
	ADMFLAG_CONVARS);
	
	AddToTopMenu(hAdminMenu,
	"sm_unrestrict",
	TopMenuObject_Item,
	AdminMenu_Unrestrict,
	player_commands,
	"sm_unrestrict",
	ADMFLAG_CONVARS);
	
	AddToTopMenu(hAdminMenu,
	"sm_dropc4",
	TopMenuObject_Item,
	AdminMenu_dropc4,
	player_commands,
	"sm_dropc4",
	ADMFLAG_BAN);
	
	AddToTopMenu(hAdminMenu,
	"sm_knives",
	TopMenuObject_Item,
	AdminMenu_Knives,
	player_commands,
	"sm_knives",
	ADMFLAG_CONVARS);
	
	AddToTopMenu(hAdminMenu,
	"sm_pistols",
	TopMenuObject_Item,
	AdminMenu_Pistols,
	player_commands,
	"sm_pistols",
	ADMFLAG_CONVARS);
}
public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "WeaponRestrictMenuItem", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "RestrictMenuItem", param);
	}
}
public AdminMenu_Restrict(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "RestrictWeaponsItem", param);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		unrestrict[param] = false;
		DisplayRestrictMenu(param);
	}
}
public AdminMenu_Unrestrict(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "UnrestrictWeaponsItem", param);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		unrestrict[param] = true;
		DisplayRestrictMenu(param);
	}
}
public AdminMenu_dropc4(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "ForceBombDropItem", param);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		DropC4(param, 0);
	}
}
public AdminMenu_Knives(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "SetupKnife", param);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		KnifeRound(param, 0);
	}
}
public AdminMenu_Pistols(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "SetupPistols", param);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		PistolRound(param, 0);
	}
}
DisplayRestrictMenu(client)
{
	new Handle:menu = CreateMenu(MenuWeaponHandler);
	
	decl String:title[100];
	
	if(!unrestrict[client])
		Format(title, sizeof(title), "%T", "WeaponRestrictTitle", client);
	else
		Format(title, sizeof(title), "%T", "WeaponUnrestrictTitle", client);

	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddWeaponsToMenu(menu);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuWeaponHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
	}
	else if(action == MenuAction_Select)
	{
		decl String:weapon[100];
		
		GetMenuItem(menu, param2, weapon, sizeof(weapon));
		
		strcopy(WeaponSelectedMenu[param1], 100, weapon);
		if(!unrestrict[param1])
		{
			DisplayAmmountMenu(param1);
		}
		else
		{
			if(StrEqual(weapon, "c4", false))
				RestrictWeaponCmd(param1, weapon, -1, T_TEAM);
			else if(StrEqual(weapon, "defuser", false))
				RestrictWeaponCmd(param1, weapon, -1, CT_TEAM);
			else
				DisplayTeamMenu(param1);
		}
	}
}
DisplayAmmountMenu(client)
{
	new Handle:menu = CreateMenu(MenuAmmountHandler);
	
	decl String:title[100];
	
	Format(title, sizeof(title), "%T", "AmmountTitle", client);

	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	for(new i = 0; i <= 6; i++)
	{
		decl String:num[3];
		Format(num, sizeof(num), "%i", i);
		AddMenuItem(menu, num, num);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
DisplayTeamMenu(client)
{
	new Handle:menu = CreateMenu(MenuTeamHandler);
	
	decl String:title[100];
	
	if(!unrestrict[client])
		Format(title, sizeof(title), "%T", "TeamRestrictTitle", client);
	else
		Format(title, sizeof(title), "%T", "TeamUnrestrictTitle", client);

	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	Format(title, sizeof(title), "%T", "CounterTerrorists", client);
	AddMenuItem(menu, "ct", title);
	Format(title, sizeof(title), "%T", "Terrorists", client);
	AddMenuItem(menu, "t", title);
	Format(title, sizeof(title), "%T", "Allteams", client);
	AddMenuItem(menu, "all", title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuTeamHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			DisplayAmmountMenu(param1);
	}
	else if(action == MenuAction_Select)
	{
		decl String:team[5];
		
		GetMenuItem(menu, param2, team, sizeof(team));
		
		if(!unrestrict[param1])
		{
			if(StrEqual(team, "ct", false))
				RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], MenuAmmount[param1], CT_TEAM);
			else if(StrEqual(team, "t", false))
				RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], MenuAmmount[param1], T_TEAM);
			else if(StrEqual(team, "all", false))
				RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], MenuAmmount[param1], 0);
		}
		else
		{
			if(StrEqual(team, "ct", false))
				RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], -1, CT_TEAM);
			else if(StrEqual(team, "t", false))
				RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], -1, T_TEAM);
			else if(StrEqual(team, "all", false))
				RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], -1, 0);
		}
	}
}
public MenuAmmountHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			DisplayRestrictMenu(param1);
	}
	else if(action == MenuAction_Select)
	{
		decl String:ammount[10];
		
		GetMenuItem(menu, param2, ammount, sizeof(ammount));
		
		MenuAmmount[param1] = StringToInt(ammount);
		
		if(StrEqual(WeaponSelectedMenu[param1], "c4", false))
			RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], MenuAmmount[param1], T_TEAM);
		else if(StrEqual(WeaponSelectedMenu[param1], "defuser", false))
			RestrictWeaponCmd(param1, WeaponSelectedMenu[param1], MenuAmmount[param1], CT_TEAM);
		else
			DisplayTeamMenu(param1);
	}
}
AddWeaponsToMenu(Handle:menu)
{
	decl String:weapon[MAX_WEAPONS][100];
	new size;
	
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		if(!StrEqual(g_WeaponNames[i], "knife", false))
		{
			strcopy(weapon[size], sizeof(weapon), g_WeaponNames[i]);
			size++;
		}
	}
	SortStrings(weapon, size-1, Sort_Ascending);
	for(new i = 0; i < size-1; i++)
		AddMenuItem(menu, weapon[i], weapon[i]);
}

