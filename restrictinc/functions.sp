stock WeaponType GetTypeGroup(const char [] szGroupName)
{
	for(int i = 0; i < sizeof(g_WeaponGroupNames); i++)
	{
		if(StrEqual(szGroupName, g_WeaponGroupNames[i]))
			return view_as<WeaponType>(i);
	}
	return WeaponTypeNone;
}

stock bool RunFile(const char [] szFile)
{
	if(!FileExists(szFile))
	{
		return false;
	}
	
	File hFile = OpenFile(szFile, "r");
	
	char szCommand[128];
	
	while(!hFile.EndOfFile())
	{
		hFile.ReadLine(szCommand, sizeof(szCommand));
		TrimString(szCommand);
		if(strncmp(szCommand, "//", 2) != 0 && strlen(szCommand) != 0)
		{
			ServerCommand("%s", szCommand);
		}
	}
	
	delete hFile;
	
	return true;
}

stock void GetCurrentMapEx(char [] szMapBuffer, int iSize)
{
	GetCurrentMap(szMapBuffer, iSize);
	
	int index = -1;
	
	for(int i = 0; i < strlen(szMapBuffer); i++)
	{
		if(StrContains(szMapBuffer[i], "/") != -1 || StrContains(szMapBuffer[i], "\\") != -1)
		{
			if(i != strlen(szMapBuffer) - 1)
				index = i;
		}
		else
		{
			break;
		}
	}
	strcopy(szMapBuffer, iSize, szMapBuffer[index+1]);
}

stock void RemoveForSpecialRound(int client)
{
	static int iMyWeaponsMax = -1;
	
	if(iMyWeaponsMax == -1)
	{
		if(IsClientInGame(client))
		{
			iMyWeaponsMax = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		}
		
		if(iMyWeaponsMax == -1)
		{
			LogError("Failed to get m_hMyWeapons array size");
			return;
		}
	}
	
	CSWeaponID id = CSWeapon_NONE;
	
	int iEnt;
	
	if(g_currentRoundSpecial == RoundType_Pistol)
	{
		id = Restrict_GetWeaponIDFromSlot(client, SlotPrimmary);
		if(id != CSWeapon_NONE)
		{
			iEnt = GetPlayerWeaponSlot(client, view_as<int>(SlotPrimmary));
			Restrict_RefundMoney(client, id);
			Restrict_RemoveWeaponDrop(client, iEnt);
		}
	}
	else if(g_currentRoundSpecial == RoundType_Knife)
	{
		id = Restrict_GetWeaponIDFromSlot(client, SlotPrimmary);
		if(id != CSWeapon_NONE)
		{
			iEnt = GetPlayerWeaponSlot(client, view_as<int>(SlotPrimmary));
			Restrict_RefundMoney(client, id);
			Restrict_RemoveWeaponDrop(client, iEnt);
		}
		id = Restrict_GetWeaponIDFromSlot(client, SlotPistol);
		if(id != CSWeapon_NONE)
		{
			iEnt = GetPlayerWeaponSlot(client, view_as<int>(SlotPistol));
			Restrict_RefundMoney(client, id);
			Restrict_RemoveWeaponDrop(client, iEnt);
		}
		int index = 0;
		for(int x = 0; x < iMyWeaponsMax; x++)
		{
			index = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", x);
			if(index && IsValidEdict(index))
			{
				id = GetWeaponIDFromEnt(index);
				if(id != CSWeapon_NONE && CSWeapons_GetWeaponSlot(id) == SlotGrenade)
				{
					int iCount = Restrict_GetClientGrenadeCount(client, id);
					for(int i = 1; i <= iCount; i++)
						Restrict_RefundMoney(client, id);
					
					Restrict_RemoveWeaponDrop(client, index);
				}
			}
		}
	}
}

stock void GetWeaponRestrictSound()
{
	g_bRestrictSound = false;
	char szFile[PLATFORM_MAX_PATH];
	
	hRestrictSound.GetString(szFile, sizeof(szFile));
	
	if(strlen(szFile) > 0 && FileExists(szFile, true))
	{
		AddFileToDownloadsTable(szFile);
		if(StrContains(szFile, "sound/", false) == 0)
		{
			ReplaceStringEx(szFile, sizeof(szFile), "sound/", "", -1, -1, false);
			strcopy(g_sCachedSound, sizeof(g_sCachedSound), szFile);
		}
		if(PrecacheSound(g_sCachedSound, true))
		{
			g_bRestrictSound = true;
		}
		else
		{
			LogError("Failed to precache restrict sound please make sure path is correct in %s and sound is in the sounds folder", szFile);
		}
	}
	else if(strlen(szFile) > 0)
	{
		LogError("Sound %s dosnt exist", szFile);
	}
}

stock bool IsGoingToPickup(int client, CSWeaponID id)
{
	WeaponSlot slot = CSWeapons_GetWeaponSlot(id);
	
	if(slot != SlotInvalid && slot != SlotNone)
	{
		if(slot == SlotGrenade)
		{
			int iCount = Restrict_GetClientGrenadeCount(client, id);
			
			if(g_iEngineVersion == Engine_CSS)
			{
				if(hHeAmmo == null || hFlashAmmo == null || hSmokeAmmo == null)
				{
					if(((id == CSWeapon_HEGRENADE || id == CSWeapon_SMOKEGRENADE) && iCount == 0) || (id == CSWeapon_FLASHBANG && iCount < 2))
						return true;
				}
				else
				{
					if((id == CSWeapon_HEGRENADE && iCount < hHeAmmo.IntValue) || (id == CSWeapon_SMOKEGRENADE && iCount < hSmokeAmmo.IntValue) || (id == CSWeapon_FLASHBANG && iCount < hFlashAmmo.IntValue))
						return true;
				}
			}
			else if(g_iEngineVersion == Engine_CSGO)
			{
				int iFlashAmmo = 1;
				
				if(hFlashAmmo != null)
				{
					iFlashAmmo = hFlashAmmo.IntValue;
				}
				
				if(((id == CSWeapon_HEGRENADE || id == CSWeapon_SMOKEGRENADE || id == CSWeapon_MOLOTOV || id == CSWeapon_DECOY || id == CSWeapon_INCGRENADE || id == CSWeapon_TAGGRENADE) && iCount == 0) || (id == CSWeapon_FLASHBANG && iCount < iFlashAmmo))
					return true;
			}
		}
		else
		{
			int iWeapon = GetPlayerWeaponSlot(client, view_as<int>(slot));
			if(iWeapon == -1)
				return true;
		}
	}
	return false;
}

stock void ClearOverride()
{
	for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		CSWeaponID id = view_as<CSWeaponID>(i);
		
		if(!CSWeapons_IsValidID(id, true))
			continue;
		
		Restrict_RemoveFromOverride(CS_TEAM_T, id);
		Restrict_RemoveFromOverride(CS_TEAM_CT, id);
	}
}
stock int GetMaxGrenades()
{
	int iFlashAmmo = hFlashAmmo == null ? 2 : hFlashAmmo.IntValue;
	int iHeAmmo = hHeAmmo == null ? 1 : hHeAmmo.IntValue;
	int iSmokeAmmo = hSmokeAmmo == null ? 1 : hSmokeAmmo.IntValue;
	
	return (iHeAmmo > iFlashAmmo) ? ((iHeAmmo > iSmokeAmmo) ? iHeAmmo : iSmokeAmmo) : ((iFlashAmmo > iSmokeAmmo) ? iFlashAmmo : iSmokeAmmo);
}

stock bool IsValidClient(int client, bool isZeroValid=false)
{
	if(isZeroValid && client == 0)
		return true;
	
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
		return false;
	
	return true;
}

stock bool IsValidTeam(int team, bool isSpecValid=false)
{
	if(isSpecValid && (team == CS_TEAM_NONE || team == CS_TEAM_SPECTATOR))
		return true;
	else if(team == CS_TEAM_NONE || team == CS_TEAM_SPECTATOR)
		return false;
	
	return true;
}

stock bool IsValidWeaponGroup(WeaponType group)
{
	if(group > WeaponTypeOther || group < WeaponTypePistol)
		return false;
	return true;
}