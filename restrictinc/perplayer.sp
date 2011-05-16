new defaultawpct;
new defaultawpt;
new totalrestricts;
new bool:perplayer;
new awprestricts[MAXPLAYERS+1][2];
GetDefaultVals()
{
	GetTrieValue(WeaponTrieCT, "awp", defaultawpct);
	GetTrieValue(WeaponTrieT, "awp", defaultawpt);
	if(GetConVarInt(PerPlayerRestrict) == 1)
	{
		totalrestricts = 0;
		for(new i = 0; i <= MaxClients; i++)
		{
			awprestricts[i][0] = 0;
			awprestricts[i][1] = 0;
		}
		GetPerPlayer();
	}
}
public OnClientPostAdminCheck(client)
{
	if(perplayer)
	{
		RunPerPlayerCheck();
	}
}
public OnClientDisconnect_Post(client)
{
	if(perplayer)
	{
		RunPerPlayerCheck();
	}
}
stock GetInGameCount()
{
	new count;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			count++;
	}
	return count;
}
GetPerPlayer()
{
	new Handle:kv = CreateKeyValues("AwpRestrict");
	new String:file[300];
	BuildPath(Path_SM, file, 300, "configs/restrict/perplayerrestrict.txt");
	if(!FileExists(file))
	{
		PrintToServer("couldnt find file");
		return;
	}
	FileToKeyValues(kv, file);
	if(KvJumpToKey(kv, "awp"))// awp restrictions exist
	{
		for(new i = 0; i <= MaxClients; i++)//again this is correct im not assigning it to a client.
		{
			new String:key[10];
			Format(key, sizeof(key), "%i", i);
			new ammount = KvGetNum(kv, key, -5);
			if(ammount != -5)
			{
				perplayer = true;
				awprestricts[totalrestricts][0] = i;
				awprestricts[totalrestricts][1] = ammount;
				//PrintToServer("%i",i);
				totalrestricts++;
			}
		}
	}
	CloseHandle(kv);
	SortCustom2D(_:awprestricts, totalrestricts-1, SortRestrictAsc);
	//PrintRestricts();
}
public SortRestrictAsc(x[], y[], array[][], Handle:data) 
{ 
	if (x[1] < y[1]) 
		return -1; 
	return x[1] > y[1]; 
}
stock PrintRestricts()// used to debug problems with per player restricts
{
	for(new i = 0; i < totalrestricts; i++)
	{
		PrintToServer("ammount of awps %i if players is %i or less", awprestricts[i][1], awprestricts[i][0]);
	}
}
RunPerPlayerCheck()
{
	new val;
	if(GetTrieValue(AdminOverride, "awp", val))
	{
		perplayer = false;
		return;
	}
	if(perplayer)
	{
		new count = GetInGameCount();
		for(new i = 0; i < totalrestricts; i++)
		{
			if(count <= awprestricts[i][0])
			{
				//PrintToServer("set to %i", awprestricts[i][1]);
				SetTrieValue(WeaponTrieCT, "awp", awprestricts[i][1]);
				SetTrieValue(WeaponTrieT, "awp", awprestricts[i][1]);
				return;
			}
		}
	}
	SetTrieValue(WeaponTrieCT, "awp", defaultawpct);
	SetTrieValue(WeaponTrieT, "awp", defaultawpt);
}
public PerPlayerConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new value = GetConVarInt(cvar);
	if(value == 1)
	{
		GetPerPlayer();
		RunPerPlayerCheck();
	}
	if(value == 0)
	{
		perplayer = false;
		RunPerPlayerCheck();
	}
}
