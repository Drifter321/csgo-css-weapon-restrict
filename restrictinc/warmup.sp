new String:g_warmupweapons[MAX_WEAPONS][100];
new String:g_weaponwarmup[100];
new WarmupArray;
new warmupcount;
new ffvalue;

new Handle:RespawnTimer[MAXPLAYERS+1];
RegisterWarmup()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	RegConsoleCmd("joinclass", OnJoinClass);
}
public OnClientDisconnect(client)
{
	KillRespawnTimer(client);
}
KillRespawnTimer(client)
{
	if(RespawnTimer[client] != INVALID_HANDLE)
	{
		KillTimer(RespawnTimer[client]);
		RespawnTimer[client] = INVALID_HANDLE;
	}
}
public Action:OnJoinClass(client, args)
{
	if(IsClientInGame(client) && GetClientTeam(client) > SPEC_TEAM && GetConVarInt(WarmupRespawn) == 1)
		CreateTimer(3.0, RespawnFunc, client, TIMER_FLAG_NO_MAPCHANGE);
}
RespawnClient(client)
{
	RespawnTimer[client] = INVALID_HANDLE;
	if(warmup && IsClientInGame(client) && !IsPlayerAlive(client))
		SDKCall(roundRespawn, client);
}
GetWarmupWeapon()
{
	if(WarmupArray < 0)
		return false;
	new int = GetRandomInt(0, WarmupArray);
	g_weaponwarmup = g_warmupweapons[int];
	if(StrEqual(g_weaponwarmup, "", false))
		return false;
	new warm = GetConVarInt(WarmUp);
	switch(warm)
	{
		case 1:
		{
			warmup = true;
			return true;
		}
		default:
		{
			warmup = false;
			return false;
		}
	}
	return false;
}
StartWarmup()
{
	for(new i = 1; i <= MaxClients; i++)
		RespawnTimer[i] = INVALID_HANDLE;
	
	WarmupConfigExec(true);
	StripGroundWeapons();
	ffvalue = GetConVarInt(ffcvar);
	if(GetConVarInt(warmupff) == 1)
	{
		SetConVarInt(ffcvar, 0, true, false);
	}
	if(GetConVarInt(grenadegive) == 1 && StrEqual(g_weaponwarmup, "hegrenade", false))
	{
		grenadehooked = true;
		HookEvent("hegrenade_detonate", HeBoom);
	}
	//PrintToServer("Starting warm up");
	PrintCenterTextAll("%t", "WarmupCountdown", GetConVarInt(WarmupTime));
	CreateTimer(1.0, WarmupCount, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
ReadWarmup()
{
	if(warmup)
		return false;
	
	WarmupArray = -1;
	warmupcount = 0;
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		g_warmupweapons[i] = "";
	}
	new String:file[150];
	BuildPath(Path_SM,file,sizeof(file),"configs/restrict/warmup.cfg");
	if(!FileExists(file))
	{
		LogMessage("warmup.cfg not parsed...file doesnt exist!");
		return false;
	}
	new Handle:FileHandle = OpenFile(file, "r");
	new String:weapon[100];
	while(!IsEndOfFile(FileHandle))
	{
		ReadFileLine(FileHandle, weapon, sizeof(weapon));
		TrimString(weapon);
		if(strncmp(weapon, "//", 2) != 0)
		{
			decl slot;
			if(GetTrieValue(WeaponSlotTrie, weapon, slot) || StrEqual(weapon, "knife", false))
			{
				WarmupArray++;
				g_warmupweapons[WarmupArray] = weapon;
			}
		}
	}
	CloseHandle(FileHandle);
	return true;
}
public Action:WarmupCount(Handle:timer)
{
	if(GetConVarInt(WarmupTime) <= warmupcount)
	{
		warmup = false;
		//PrintToServer("Warmup finished");
		ServerCommand("mp_restartgame 1");
		WarmupConfigExec(false);
		if(grenadehooked)
		{
			grenadehooked = false;
			UnhookEvent("hegrenade_detonate", HeBoom);
		}
		SetConVarInt(ffcvar, ffvalue, true, false);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
				KillRespawnTimer(i);
		}
		return Plugin_Stop;
	}
	PrintCenterTextAll("%t", "WarmupCountdown" , GetConVarInt(WarmupTime)-warmupcount);
	warmupcount++;
	return Plugin_Continue;
}
GiveWarmupWeapon(client)
{
	if(!StrEqual(g_weaponwarmup, "knife", false) && IsClientInGame(client) && GetClientTeam(client) > SPEC_TEAM && warmup)
	{
		new weapon;
		weapon = GetPlayerWeaponSlot(client, 1);
		if(weapon != -1)
		{
			HackWeaponRemove(weapon, 1, client);
		}
		weapon = GetPlayerWeaponSlot(client, 0);
		if(weapon != -1)
		{
			HackWeaponRemove(weapon, 0, client);
		}
		decl slot;
		GetTrieValue(WeaponSlotTrie, g_weaponwarmup, slot);
		if(GetPlayerWeaponSlot(client, slot) == -1)// avoids giving player weapon twice for some odd reason grenade is given twice without this
		{
			new String:weapon2[100];
			Format(weapon2, sizeof(weapon2), "weapon_%s", g_weaponwarmup);
			GivePlayerItem(client, weapon2);
		}
	}
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(warmup)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		RespawnTimer[client] = INVALID_HANDLE;
		CreateTimer(0.2, SpawnWeapoDelay, client);
	}	
}
public Action:SpawnWeapoDelay(Handle:timer, any:client)
{
	GiveWarmupWeapon(client);
}
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(warmup && GetConVarInt(WarmupRespawn) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		RespawnTimer[client] = CreateTimer(GetConVarFloat(WarmupRespawnTime), RespawnFunc, client, TIMER_FLAG_NO_MAPCHANGE);
	}	
}
public Action:HeBoom(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(IsClientInGame(client) && warmup && StrEqual(g_weaponwarmup, "hegrenade", false) && GetClientTeam(client) > SPEC_TEAM && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, 3) == -1)// avoids giving player a nade if they already have one (picked one up from the ground)
		{
			new weapon = GivePlayerItem(client,"weapon_hegrenade");
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
}
public Action:RespawnFunc(Handle:timer, any:client)
{
	if(GetConVarInt(WarmupRespawn) == 1 && warmup && IsClientInGame(client) && !IsPlayerAlive(client))// spawn
	{
		RespawnClient(client);
		RespawnTimer[client] = INVALID_HANDLE;
	}
}
StripGroundWeapons()
{
	for (new i = MaxClients; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			decl String:name[120];
			GetEdictClassname(i, name, sizeof(name));
			if(strncmp(name, "weapon_", 7, false) == 0 && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1)
				RemoveEdict(i);
		}
	}
}
WarmupConfigExec(bool:pre)
{
	new String:file[PLATFORM_MAX_PATH];
	if(pre)
	{
		BuildPath(Path_SM, file, sizeof(file), "configs/restrict/prewarmup.cfg");
	}
	else
	{
		BuildPath(Path_SM, file, sizeof(file), "configs/restrict/postwarmup.cfg");
	}
	if(!FileExists(file))
	{
		LogError("%s dosnt exist", file);
		return;
	}
	new Handle:FileHandle = OpenFile(file, "r");
	new String:Command[50];
	while(!IsEndOfFile(FileHandle))
	{
		ReadFileLine(FileHandle, Command, sizeof(Command));
		TrimString(Command);
		if(strncmp(Command, "//", 2) != 0 && strlen(Command) != 0)
		{
			ServerCommand("%s", Command);// We can really expand on this but simple is always good..
		}
	}
	CloseHandle(FileHandle);
}