new bool:g_Rebuy[MAXPLAYERS+1];
new PlayerWeapons;
new Handle:g_ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new g_account[MAXPLAYERS+1];
new bool:TimerCreated[MAXPLAYERS+1];
//////////////////////////////////////////////////
//Events, Hooks, Registered cmd's/////////////////
//////////////////////////////////////////////////
public Action:RebuyCheck(client, args)
{	
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) < T_TEAM || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_bInBuyZone") == 0)
		return Plugin_Continue;
	if(!warmup)
	{
		g_Rebuy[client] = true;
		g_ClientTimer[client] = CreateTimer(0.3, ResetRebuy, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(warmup)
	{
		PrintToChat(client, "\x04%t", "WarmUpBuy");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:BuyCheck(client, args)
{
	if(client < 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_bInBuyZone") == 0)
		return Plugin_Continue;
	
	#if defined WARMUP
	if(warmup)
	{
		PrintToChat(client, "\x04%t", "WarmUpBuy");
		return Plugin_Handled;
	}
	#endif
	new clientteam = GetClientTeam(client);
	if(clientteam < T_TEAM)
		return Plugin_Continue;
	new String:weapon[100];
	GetCmdArgString(weapon, sizeof(weapon));
	
	ReplaceString(weapon, 100, "weapon_", "", false);
	TrimString(weapon);
	
	new len = strlen(weapon);
	for(new i = 0; i < len; i++)
	{
		weapon[i] = CharToLower(weapon[i]);
	}
	
	if(strncmp(weapon, "c4", 2, false) == 0 || strncmp(weapon, "knife", 5, false) == 0)
		return Plugin_Continue;
	
	decl valuect;
	decl valuet;
	if(!GetTrieValue(WeaponTrieCT, weapon, valuect) && !GetTrieValue(WeaponTrieT, weapon, valuet))
	{
		new index = GetWeaponIndex(weapon);
		if(index > -1)
			weapon = g_WeaponNames[index];
		else
			return Plugin_Continue;
	}
	
	decl teamnum;
	
	if(!GetTrieValue(WeaponTeamTrie, weapon, teamnum))
		return Plugin_Continue;
	
	if(teamnum != 0 && clientteam != teamnum)
		return Plugin_Continue;
	if(!IsAllowed(client, weapon, clientteam))
	{
		PrintToChat(client, "\x04%t", "WeaponRestricted");
		if(HasSound)
			EmitSoundToClient(client, RestrictSound);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:ResetRebuy(Handle:timer, any:client)
{
	g_Rebuy[client] = false;
	if(g_ClientTimer[client] != INVALID_HANDLE)
		g_ClientTimer[client] = INVALID_HANDLE;
}

public Action:EventItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[100];
	GetEventString(event, "item", weapon, sizeof(weapon));
	
	ReplaceString(weapon, sizeof(weapon), "weapon_", "", false);
	TrimString(weapon);
	
	if(ispistolsround || isknivesround || warmup || g_Rebuy[client] || GetConVarInt(AllowPickup) == 0 || StrEqual(weapon, "c4", false) || newround)
	{
		if(StrEqual(weapon, "knife", false))
			return Plugin_Continue;
		#if defined WARMUP
		if(warmup && StrEqual(weapon, g_weaponwarmup, false))
			return Plugin_Continue;
		#endif
		new team = GetClientTeam(client);
		if(!IsAllowed(client, weapon, team))
		{
			new slot;
			GetTrieValue(WeaponSlotTrie, weapon, slot);
			RemoveWeapon(client, weapon, slot, true, false);
		}
	}
	return Plugin_Continue;
}
public Action:GiveMoneyDelayed(Handle:timer, any:client)
{
	TimerCreated[client] = false;
	if(IsClientInGame(client))
	{
		new account = GetEntData(client, g_iAccount);
		new price = g_account[client];
		account += price;
		if(account < 16000)
			SetEntData(client, g_iAccount, account);
		else
		SetEntData(client, g_iAccount, 16000);
	}
	g_account[client] = 0;
}
ResetEventGlobals()
{
	isknivesround = false;
	ispistolsround = false;
	for(new i = 1; i <= MaxClients; i++)
	{
		g_Rebuy[i] = false;
		if(g_ClientTimer[i] != INVALID_HANDLE)
			g_ClientTimer[i] = INVALID_HANDLE;
		TimerCreated[i] = false;
		g_account[i] = 0;
	}
}
IsAllowed(client, String:weapon[100], clientteam)
{
	if(!warmup && !ispistolsround && !isknivesround)
	{
		if((GetUserFlagBits(client) & ADMIN_LEVEL) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			if(GetConVarInt(AdminImmunity) == 1 && !StrEqual(weapon, "c4", false))
				return true;
		}
		new bool:allowed = CheckAmmount(client, weapon, clientteam);
		return allowed;
	}
	else if(ispistolsround || isknivesround)
	{
		new slot;
		GetTrieValue(WeaponSlotTrie, weapon, slot);
		if((ispistolsround && slot > 2) || (isknivesround && slot > 3) || slot == -1)
		{
			new bool:allowed = CheckAmmount(client, weapon, clientteam);
			return allowed;
		}
		else if(ispistolsround && slot == 1)
			return true;
		else if(ispistolsround && slot == 2)
			return true;
		else if(isknivesround && slot == 2)
			return true;
		
		return false;
	}
	#if defined WARMUP
	if(warmup)
	{
		new slot;
		GetTrieValue(WeaponSlotTrie, weapon, slot);
		RemoveWeapon(client, weapon, slot, false, false);
		GiveWarmupWeapon(client);
		return false;
	}
	#endif
	return true;
}
bool:CheckAmmount(client, String:weapon[100], clientteam)
{
	new value;
	if(clientteam == 3)
		GetTrieValue(WeaponTrieCT, weapon, value);
	else if(clientteam == 2)
		GetTrieValue(WeaponTrieT, weapon, value);
	else 
	return true;
	//PrintToChatAll("value: %i", value);
	if(value == -1)
		return true;
	if(value == 0)
		return false;
	
	new total = GetTotal(client, weapon, clientteam);
	//PrintToChatAll("total: %i, value: %i", total, value);
	if(total < value)
		return true;
	else
	return false;
}
GetTotal(client, String:weapon[], clientteam)
{
	new count = 0;
	new String:weapon2[100];
	new slot;
	
	//PrintToChatAll("Going to get slot");
	GetTrieValue(WeaponSlotTrie, weapon, slot);
	
	Format(weapon2, sizeof(weapon2), "weapon_%s", weapon);
	
	//PrintToChatAll("Weapon name is, %s slot is %i", weapon2, slot);
	if(slot == 3)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetConVarInt(AdminImmunity) == 1 && ((GetUserFlagBits(i) & ADMIN_LEVEL) || (GetUserFlagBits(i) & ADMFLAG_ROOT)))
				continue;
			
			if(IsClientInGame(i) && i != client && GetClientTeam(i) == clientteam)
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
			if(IsClientInGame(i) && i != client && GetClientTeam(i) == clientteam)
			{
				new weaponindex = GetPlayerWeaponSlot(i, slot);
				new String:classname[100];
				if(weaponindex != -1 && IsValidEdict(weaponindex))
				{
					GetEdictClassname(weaponindex, classname, sizeof(classname));
					if(StrEqual(classname, weapon2, false))
						count++;
				}
			}
		}
	}
	return count;
}
GetWeaponIndex(String:weapon[100])
{
	new String:weapon2[100];
	new bool:found = false;
	new index;
	ReplaceString(weapon, sizeof(weapon), "weapon_", "", false);
	//This is for shorter buy commands/ other buy commands that buy a weapon.
	if(StrContains(weapon, "kevlar", false) != -1)
	{
		found = true;
		weapon2 = "vest";
	}
	else if(StrContains(weapon, "hegren", false) != -1)
	{
		found = true;
		weapon2 = "hegrenade";
	}
	else if(StrContains(weapon, "flash", false) != -1)
	{
		found = true;
		weapon2 = "flashbang";
	}
	else if(StrContains(weapon, "magnum", false) != -1)
	{
		found = true;
		weapon2 = "awp";
	}
	else if(StrContains(weapon, "mp5", false) != -1)
	{
		found = true;
		weapon2 = "mp5navy";
	}
	if(found)
	{
		index = GetNumber(weapon2);
		if(index != -2)
		{
			return index;
		}
	}
	//Lets check for weird buy commands then.better to loop than a bunch of if's
	// This checks for binds like.. glock18 and only compares the first bit being glock.
	for(new i = 1; i < MAX_WEAPONS; i++)
	{
		new len = strlen(g_WeaponNames[i]);
		if(StrContains(weapon, g_WeaponNames[i], false) != -1)
		{
			return i;
		}
	}
	return -2;
}
GetNumber(String:weapon[100])
{
	new index;
	for(new i = 1; i < MAX_WEAPONS; i++)
	{
		if(StrEqual(g_WeaponNames[i], weapon, false))
		{
			index = i;
			return index;
		}
	}
	return -2;
}
public Action:RemoveEdictDelay(Handle:timer, any:index)//This isnt needed anymore but for this version ill leave it
{
	if(IsValidEdict(index))
		AcceptEntityInput(index, "Kill");
}
RemoveWeapon(client, String:weapon[], slot, bool:print, bool:refund)
{
	if(slot != -1 && IsClientInGame(client) && slot != 3 && slot != 2)
	{
		new weapon2 = GetPlayerWeaponSlot(client, slot);
		if(weapon2 != -1)
		{
			HackWeaponRemove(weapon2, slot, client);
		}
	}
	else if(slot == -1 && IsClientInGame(client))
	{
		if(StrEqual(weapon, "defuser", false))
			CreateTimer(0.1, RemoveDefuser, client);
		else if(StrEqual(weapon, "vesthelm", false))
			CreateTimer(0.1, RemoveVestHelm, client);
		else if(StrEqual(weapon, "vest", false))
			CreateTimer(0.1, RemoveVest, client);
		else if(StrEqual(weapon, "nvgs", false))
			CreateTimer(0.1, RemoveNvgs, client);
	}
	else if(slot == 3)
	{
		if(StrEqual(weapon, "flashbang"))
		{
			CreateTimer(0.1, StripFlash, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(StrEqual(weapon, "hegrenade"))
		{
			CreateTimer(0.1, StripNade, client);
		}
		else if(StrEqual(weapon, "smokegrenade"))
		{
			CreateTimer(0.1, StripSmoke, client);
		}
	}
	if(g_Rebuy[client])
	{
		new price;
		GetTrieValue(WeaponPriceTrie, weapon, price);
		g_account[client] += price;
		if(!TimerCreated[client])
		{
			TimerCreated[client] = true;
			CreateTimer(0.3, GiveMoneyDelayed, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(refund)
	{
		new price;
		GetTrieValue(WeaponPriceTrie, weapon, price);
		GiveMoney(client, price);
	}
	if(print && !warmup)
	{
		PrintToChat(client, "\x04%t", "WeaponRestricted");
		if(HasSound)
			EmitSoundToClient(client, RestrictSound);
	}
}
//Other removes
public Action:RemoveDefuser(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(GetEntProp(client, Prop_Send, "m_bHasDefuser") !=0)
			SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
	}
}
public Action:RemoveNvgs(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(GetEntProp(client, Prop_Send, "m_bHasNightVision") !=0)
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0);
	}
}
public Action:RemoveVest(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(GetEntProp(client, Prop_Send, "m_ArmorValue") != 0)
			SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
	}
}
public Action:RemoveVestHelm(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(GetEntProp(client, Prop_Send, "m_ArmorValue") != 0)
			SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
		if(GetEntProp(client, Prop_Send, "m_bHasHelmet") !=0)
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	}
}
public Action:StripNade(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		decl String:WeaponClass[64];
		static x = 0, EntityIndex = 0;
		for (x = 0; x <= (32 * 4); x += 4)
		{
			EntityIndex = GetEntDataEnt2(client, (PlayerWeapons + x));
			if (EntityIndex && IsValidEdict(EntityIndex))
			{
				GetEdictClassname(EntityIndex, WeaponClass, sizeof(WeaponClass));
				if (StrEqual(WeaponClass, "weapon_hegrenade"))
				{
					RemovePlayerItem(client, EntityIndex);
					CreateTimer(0.1, RemoveEdictDelay, EntityIndex, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}
public Action:StripFlash(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		decl String:WeaponClass[64];
		static x = 0, EntityIndex = 0;
		for (x = 0; x <= (32 * 4); x += 4)
		{
			EntityIndex = GetEntDataEnt2(client, (PlayerWeapons + x));
			if (EntityIndex && IsValidEdict(EntityIndex))
			{
				GetEdictClassname(EntityIndex, WeaponClass, sizeof(WeaponClass));
				if (StrEqual(WeaponClass, "weapon_flashbang"))
				{
					RemovePlayerItem(client, EntityIndex);
					CreateTimer(0.1, RemoveEdictDelay, EntityIndex, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}
public Action:StripSmoke(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		decl String:WeaponClass[64];
		static x = 0, EntityIndex = 0;
		for (x = 0; x <= (32 * 4); x += 4)
		{
			EntityIndex = GetEntDataEnt2(client, (PlayerWeapons + x));
			if (EntityIndex && IsValidEdict(EntityIndex))
			{
				GetEdictClassname(EntityIndex, WeaponClass, sizeof(WeaponClass));
				if (StrEqual(WeaponClass, "weapon_smokegrenade"))
				{
					RemovePlayerItem(client, EntityIndex);
					CreateTimer(0.1, RemoveEdictDelay, EntityIndex, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}
StripGuns(bool:remove)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		new price = 0;
		new weapon = 0;
		new value = 0;
		new String:weapon2[100] = "";
		if(remove && IsClientInGame(i))
		{
			weapon = GetPlayerWeaponSlot(i, 1);
			if(weapon != -1)
			{
				GetEdictClassname(weapon, weapon2, sizeof(weapon2));
				ReplaceString(weapon2, sizeof(weapon2), "weapon_", "", false);
				TrimString(weapon2);
				HackWeaponRemove(weapon, 1, i);
				GetTrieValue(WeaponPriceTrie, weapon2, value);
				price += value;
			}
		}
		if(IsClientInGame(i))
		{
			weapon = GetPlayerWeaponSlot(i, 0);
			if(weapon != -1)
			{
				GetEdictClassname(weapon, weapon2, sizeof(weapon2));
				ReplaceString(weapon2, sizeof(weapon2), "weapon_", "", false);
				TrimString(weapon2);
				HackWeaponRemove(weapon, 0, i);
				GetTrieValue(WeaponPriceTrie, weapon2, value);
				price += value;
			}
		}
		GiveMoney(i, price);
	}
}
GiveMoney(client, price)
{
	if(IsClientInGame(client))
	{
		new account = GetEntData(client, g_iAccount);
		account += price;
		if(account < 16000)
			SetEntData(client, g_iAccount, account);
		else
		SetEntData(client, g_iAccount, 16000);
		
		PrintToChat(client, "\x04%t", "Refunded");
	}
}
HackWeaponRemove(weapon, slot, client)
{	
	if(slot >= 5 || slot < 0)
		return;
	new Float:orgin[3] = {-10000.0, -10000.0, -10000.0};
	SDKCall(weaponDrop, client, weapon, true, true);// i use this because if auto switch is enabled it wont leave them without a weapon in hand
	TeleportEntity(weapon, orgin, NULL_VECTOR, NULL_VECTOR);
	CreateTimer(0.1, RemoveEdictDelay, weapon, TIMER_FLAG_NO_MAPCHANGE);
}
	