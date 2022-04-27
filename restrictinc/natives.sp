static Handle hCanBuyForward = null;
static Handle hCanPickupForward = null;
static Handle hRestrictSoundForward = null;
static Handle hWarmupStartForward = null;
static Handle hWarmupEndForward = null;

#if defined PERPLAYER
static bool g_bOverrideValues[CSWeapon_MAX_WEAPONS_NO_KNIFES][CVarTeam_MAX];
#endif

//m_iAmmo array index
static int iGrenadeAmmoIndex[view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES)] = {-1, ...};

void RegisterNatives()
{
	RegPluginLibrary("weaponrestrict");
	
	CreateNative("Restrict_RefundMoney", Native_RefundMoney);
	CreateNative("Restrict_RemoveRandom", Native_RemoveRandom);
	CreateNative("Restrict_GetTeamWeaponCount", Native_GetTeamWeaponCount);
	CreateNative("Restrict_GetRestrictValue", Native_GetRestrictValue);
	CreateNative("Restrict_GetWeaponIDExtended", Native_GetWeaponIDExtended);
	CreateNative("Restrict_GetClientGrenadeCount", Native_GetClientGrenadeCount);
	CreateNative("Restrict_GetWeaponIDFromSlot", Native_GetWeaponIDFromSlot);
	CreateNative("Restrict_RemoveSpecialItem", Native_RemoveSpecialItem);
	CreateNative("Restrict_CanBuyWeapon", Native_CanBuyWeapon);
	CreateNative("Restrict_CanPickupWeapon", Native_CanPickupWeapon);
	CreateNative("Restrict_IsSpecialRound", Native_IsSpecialRound);
	CreateNative("Restrict_IsWarmupRound", Native_IsWarmupRound);
	CreateNative("Restrict_HasSpecialItem", Native_HasSpecialItem);
	CreateNative("Restrict_SetRestriction", Native_SetRestriction);
	CreateNative("Restrict_SetGroupRestriction", Native_SetGroupRestriction);
	CreateNative("Restrict_GetRoundType", Native_GetRoundType);
	CreateNative("Restrict_CheckPlayerWeapons", Native_CheckPlayerWeapons);
	CreateNative("Restrict_RemoveWeaponDrop", Native_RemoveWeaponDrop);
	CreateNative("Restrict_ImmunityCheck", Native_ImmunityCheck);
	CreateNative("Restrict_AllowedForSpecialRound", Native_IsAllowedForSpecialRound);
	CreateNative("Restrict_PlayRestrictSound", Native_PlayRestrictSound);
	CreateNative("Restrict_AddToOverride", Native_AddToOverride);
	CreateNative("Restrict_RemoveFromOverride", Native_RemoveFromOverride);
	CreateNative("Restrict_IsWeaponInOverride", Native_IsWeaponInOverride);
	CreateNative("Restrict_IsWarmupWeapon", Native_IsWarmupWeapon);
}

void RegisterForwards()
{
	hCanBuyForward = CreateGlobalForward("Restrict_OnCanBuyWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
	hCanPickupForward = CreateGlobalForward("Restrict_OnCanPickupWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
	hRestrictSoundForward = CreateGlobalForward("Restrict_OnPlayRestrictSound", ET_Event, Param_Cell, Param_Cell, Param_String);
	hWarmupStartForward = CreateGlobalForward("Restrict_OnWarmupStart_Post", ET_Ignore);
	hWarmupEndForward = CreateGlobalForward("Restrict_OnWarmupEnd_Post", ET_Ignore);
}

void RegisterGrenades()
{
	static bool bAmmoChecked = false;
	
	if(!bAmmoChecked)
	{
		for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
		{
			static char szClassname[128];
			if(CSWeapons_IsValidID(view_as<CSWeaponID>(i), true) && CSWeapons_GetWeaponType(view_as<CSWeaponID>(i)) == WeaponTypeGrenade && CSWeapons_GetWeaponClassname(view_as<CSWeaponID>(i), szClassname, sizeof(szClassname)))
			{
				int iEnt = CreateEntityByName(szClassname);
			
				if(iEnt)
				{
					DispatchSpawn(iEnt);
					iGrenadeAmmoIndex[i] = GetEntProp(iEnt, Prop_Send, "m_iPrimaryAmmoType");
					AcceptEntityInput(iEnt, "Kill");
				}
			}
			else
			{
				iGrenadeAmmoIndex[i] = -1;
			}
		}
		bAmmoChecked = true;
	}
}

stock void OnWarmupStart_Post()
{
	Call_StartForward(hWarmupStartForward);
	Call_Finish();
}

stock void OnWarmupEnd_Post()
{
	Call_StartForward(hWarmupEndForward);
	Call_Finish();
}

public int Native_RefundMoney(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	int amount = CSWeapons_GetWeaponPrice(client, id, true);
		
	int max = 16000;
	
	if(hMaxMoney != null)
		max = hMaxMoney.IntValue;
	
	int account = GetEntProp(client, Prop_Send, "m_iAccount");
	account += amount;
	
	if(account < max)
		SetEntProp(client, Prop_Send, "m_iAccount", account);
	else
		SetEntProp(client, Prop_Send, "m_iAccount", max);
		
	char szWeaponName[WEAPONARRAYSIZE];
	CSWeapons_GetAlias(id, szWeaponName, sizeof(szWeaponName), true);
	
	PrintToChat(client, "\x01[\x04SM\x01]\x04 %T %T", "Refunded", client, amount,  szWeaponName, client);
	
	return 1;
}

public int Native_RemoveRandom(Handle hPlugin, int iNumParams)
{
	static int iMyWeaponsMax = -1;
	
	if(iMyWeaponsMax == -1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				iMyWeaponsMax = GetEntPropArraySize(i, Prop_Send, "m_hMyWeapons");
				break;
			}
		}
		
		if(iMyWeaponsMax == -1)
		{
			return ThrowNativeError(SP_ERROR_NATIVE, "Failed to get m_hMyWeapons array size");
		}
	}

	int iCount = GetNativeCell(1);
	int iTeam = GetNativeCell(2);
	CSWeaponID id = GetNativeCell(3);
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	WeaponSlot slot = CSWeapons_GetWeaponSlot(id);
	
	int [] iRemoveEnts = new int[MAXPLAYERS*GetMaxGrenades()];//Times X since a player can have X flashes/he/smokes x being the value of the ammo cvars
	
	int index = 0;
	
	if(slot == SlotInvalid)
		return ThrowNativeError(SP_ERROR_NATIVE, "Unknown weapon slot returned.");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || Restrict_ImmunityCheck(i) || GetClientTeam(i) != iTeam)
			continue;
		
		if(slot == SlotGrenade || slot == SlotKnife)// CSGO has 2 "knives" slots
		{
			int iWeaponCount = 1;
			
			if(slot == SlotGrenade)
			{
				iWeaponCount = Restrict_GetClientGrenadeCount(i, id);
			}
			
			int iEnt = 0;
			for(int x = 0; x < iMyWeaponsMax; x++)
			{
				iEnt = GetEntPropEnt(i, Prop_Send, "m_hMyWeapons", x);
				if(iEnt != -1 && iEnt && IsValidEdict(iEnt) && GetWeaponIDFromEnt(iEnt) == id)
				{
					for(int z = 0; z < iWeaponCount; z++)
					{
						iRemoveEnts[index] = iEnt;
						index++;
					}
				}
			}
		}
		else if(slot == SlotNone)
		{
			if(Restrict_HasSpecialItem(i, id))
			{
				iRemoveEnts[index] = i;
				index++;
			}
		}
		else
		{
			int iEnt = GetPlayerWeaponSlot(i, view_as<int>(slot));
			if(iEnt != -1 && GetWeaponIDFromEnt(iEnt) == id)
			{
				iRemoveEnts[index] = iEnt;
				index++;
			}
		}
	}
	SortIntegers(iRemoveEnts, index-1, Sort_Random);
	
	if(slot == SlotGrenade)
	{
		int iAmmoIndex = -1;
		iAmmoIndex = iGrenadeAmmoIndex[id];

		if(iAmmoIndex == -1)
			return ThrowNativeError(SP_ERROR_NATIVE, "Failed to get m_iAmmo index for %d", id);
		
		for(int i = 0; i < iCount; i++)
		{
			if(i < index && IsValidEdict(iRemoveEnts[i]))
			{
				int client = GetEntPropEnt(iRemoveEnts[i], Prop_Data, "m_hOwnerEntity");
				
				if(client != -1)
				{
					int iGrenadeCount = Restrict_GetClientGrenadeCount(client, id);
					
					if(iGrenadeCount == 0)
						continue;
					
					if(iGrenadeCount == 1)
					{
						if(Restrict_RemoveWeaponDrop(client, iRemoveEnts[i]))
						{
							Restrict_RefundMoney(client, id);
						}
					}
					else
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", iGrenadeCount-1, _, iAmmoIndex);
						Restrict_RefundMoney(client, id);
					}
				}
			}
		}
	}
	else if(slot != SlotNone)
	{
		for(int i = 0; i < iCount; i++)
		{
			if(i < index && IsValidEdict(iRemoveEnts[i]))
			{
				int client = GetEntPropEnt(iRemoveEnts[i], Prop_Data, "m_hOwnerEntity");
				if(client != -1)
				{
					if(Restrict_RemoveWeaponDrop(client, iRemoveEnts[i]))
					{
						Restrict_RefundMoney(client, id);
					}
				}
			}
		}
	}
	else
	{
		for(int i = 0; i < iCount; i++)
		{
			if(i < index && IsClientInGame(iRemoveEnts[i]))
			{
				if(Restrict_RemoveSpecialItem(iRemoveEnts[i], id))
				{
					Restrict_RefundMoney(iRemoveEnts[i], id);
				}
			}
		}
	}
	return 1;
}

public int Native_GetTeamWeaponCount(Handle hPlugin, int iNumParams)
{
	int iTeam = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	int iWeaponCount = 0;
	WeaponSlot slot = CSWeapons_GetWeaponSlot(id);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || Restrict_ImmunityCheck(i) || GetClientTeam(i) != iTeam)
			continue;
		
		if(slot == SlotGrenade)
		{
			iWeaponCount += Restrict_GetClientGrenadeCount(i, id);
		}
		else if(slot == SlotNone)
		{
			if(Restrict_HasSpecialItem(i, id))
				iWeaponCount++;
		}
		else
		{
			if(Restrict_GetWeaponIDFromSlot(i, slot) == id)
				iWeaponCount++;
		}
	}
	return iWeaponCount;
}

public int Native_GetRestrictValue(Handle hPlugin, int iNumParams)
{
	int iTeam = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(id >= CSWeapon_MAX_WEAPONS_NO_KNIFES)
		return -1;
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	int iRestrictValue = -1;
	
	if(iTeam == CS_TEAM_T && hRestrictCVars[view_as<int>(id)][CVarTeam_T])
	{
		iRestrictValue = hRestrictCVars[view_as<int>(id)][CVarTeam_T].IntValue;
	}
	else if(iTeam == CS_TEAM_CT && hRestrictCVars[view_as<int>(id)][CVarTeam_CT])
	{
		iRestrictValue = hRestrictCVars[view_as<int>(id)][CVarTeam_CT].IntValue;
	}
	
	if(iRestrictValue <= -1)
		return -1;
		
	return iRestrictValue;
}

public int Native_GetWeaponIDExtended(Handle hPlugin, int iNumParams)
{
	char szWeapon[WEAPONARRAYSIZE];
	GetNativeString(1, szWeapon, sizeof(szWeapon));
	
	CSWeaponID id = CS_AliasToWeaponID(szWeapon);
	
	if(id != CSWeapon_NONE || g_iEngineVersion == Engine_CSGO) // CS:GO has no aliases nor does it call WeaponIDFromClassname()
	{
		if(CSWeapons_GetWeaponType(id) == WeaponTypeKnife)
			return  view_as<int>(CSWeapon_KNIFE);
		
		return view_as<int>(id);
	}
	
	// CS:S has aliases and allows for bizzare buy strings such as buy myamazingak47;
	char szAlias[WEAPONARRAYSIZE];
	CS_GetTranslatedWeaponAlias(szWeapon, szAlias, sizeof(szAlias));
	
	id = CS_AliasToWeaponID(szAlias);
	
	if(id != CSWeapon_NONE)
		return view_as<int>(id);
	
	//Oh god...
	for(int i = 0; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		if(CSWeapons_IsValidID(view_as<CSWeaponID>(i), true))
		{
			CSWeapons_GetAlias(view_as<CSWeaponID>(i), szAlias, sizeof(szAlias), true);
			
			if(StrContains(szWeapon, szAlias, false) != -1)
				return view_as<int>(i);
		}
	}
	
	return view_as<int>(CSWeapon_NONE);
}

public int Native_GetClientGrenadeCount(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	
	if(!CSWeapons_IsValidID(id))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	int iAmmoIndex = -1;
	
	if(CSWeapons_GetWeaponType(id) == WeaponTypeGrenade)
	{
		iAmmoIndex = iGrenadeAmmoIndex[id];
	}
	else
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is not a grenade.", id);
	}
	
	if(iAmmoIndex == -1)
		return ThrowNativeError(SP_ERROR_NATIVE, "Failed to get m_iAmmo index for %d", id);
	
	return GetEntProp(client, Prop_Send, "m_iAmmo", _, iAmmoIndex);
}

public int Native_GetWeaponIDFromSlot(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	WeaponSlot slot = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	
	if(slot == SlotInvalid || slot == SlotNone)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon slot index %d is invalid.", slot);
	}
	
	int ent = GetPlayerWeaponSlot(client, view_as<int>(slot));
		
	if(ent != -1)
	{
		return view_as<int>(GetWeaponIDFromEnt(ent));
	}
	
	return 0;
}

public int Native_RemoveSpecialItem(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	if((id == CSWeapon_DEFUSER || id == CSWeapon_CUTTERS) && GetEntProp(client, Prop_Send, "m_bHasDefuser") !=0)
	{
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
		return true;
	}
	else if(id == CSWeapon_ASSAULTSUIT && GetEntProp(client, Prop_Send, "m_ArmorValue") != 0 && GetEntProp(client, Prop_Send, "m_bHasHelmet") != 0)
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
		return true;
	}
	else if(id == CSWeapon_KEVLAR && GetEntProp(client, Prop_Send, "m_ArmorValue") != 0 && GetEntProp(client, Prop_Send, "m_bHasHelmet") == 0)
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
		return true;
	}
	else if(id == CSWeapon_NIGHTVISION && GetEntProp(client, Prop_Send, "m_bHasNightVision") !=0)
	{
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 0);
		return true;
	}
	else if(id == CSWeapon_HEAVYASSAULTSUIT && GetEntProp(client, Prop_Send, "m_bHasHeavyArmor") != 0)
	{
		SetEntProp(client, Prop_Send, "m_bHasHeavyArmor", 0);
		return true;
	}
	return false;
}

public int Native_CanBuyWeapon(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	int iTeam = GetNativeCell(2);
	CSWeaponID id = GetNativeCell(3);
	bool blockhook = GetNativeCell(4);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	CanBuyResult result = CanBuy_Block;
	int iRestrictVal = Restrict_GetRestrictValue(iTeam, id);
	
	if(!Restrict_IsSpecialRound())
	{
		if(iRestrictVal == -1 || Restrict_ImmunityCheck(client) || (Restrict_GetTeamWeaponCount(iTeam, id) < iRestrictVal))
			result = CanBuy_Allow;
	}
	else if(Restrict_AllowedForSpecialRound(id))
	{
		//If pistol round always allow any pistol
		//If knife round always allow knife
		//If Warmup always allow warmup weapon
		WeaponType type = CSWeapons_GetWeaponType(id);
		
		#if defined WARMUP
		if((g_currentRoundSpecial == RoundType_Pistol && type == WeaponTypePistol) || (g_currentRoundSpecial == RoundType_Knife && type == WeaponTypeKnife ) || (g_currentRoundSpecial == RoundType_Warmup && id == g_iWarmupWeapon))
		#else
		if((g_currentRoundSpecial == RoundType_Pistol && type == WeaponTypePistol) || (g_currentRoundSpecial == RoundType_Knife && type == WeaponTypeKnife))
		#endif
			result = CanBuy_Allow;
		else if(iRestrictVal == -1 || Restrict_ImmunityCheck(client) || (Restrict_GetTeamWeaponCount(iTeam, id) < iRestrictVal))
			result = CanBuy_Allow;
	}
	
	if(!blockhook)
	{
		CanBuyResult orgresult = result;
		Action res = Plugin_Continue;
		
		Call_StartForward(hCanBuyForward);
		Call_PushCell(client);
		Call_PushCell(iTeam);
		Call_PushCell(id);
		Call_PushCellRef(result);
		Call_Finish(res);
		
		if(res == Plugin_Continue)
			return view_as<int>(orgresult);
		if(res >= Plugin_Handled)
			return view_as<int>(CanBuy_Block);
	}
	return view_as<int>(result);
}

public int Native_CanPickupWeapon(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	int iTeam = GetNativeCell(2);
	CSWeaponID id = GetNativeCell(3);
	bool blockhook = GetNativeCell(4);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	bool result = false;
	int iRestrictVal = Restrict_GetRestrictValue(iTeam, id);
	int iCount = Restrict_GetTeamWeaponCount(iTeam, id);
	
	if(Restrict_IsWarmupRound())
	{
		WeaponType type = CSWeapons_GetWeaponType(id);
		
		if(Restrict_IsWarmupWeapon(id) || (type == WeaponTypeKnife))
			result = true;
	}
	else if(!Restrict_IsSpecialRound())
	{
		if(id == CSWeapon_AWP && !hAWPAllowPickup.BoolValue)
		{
			if(iRestrictVal == -1 || Restrict_ImmunityCheck(client) || (iCount < iRestrictVal))
				result = true;
		}
		else if(iRestrictVal == -1 || Restrict_ImmunityCheck(client) || (iCount < iRestrictVal) || hAllowPickup.BoolValue)
			result = true;
	}
	else if(Restrict_AllowedForSpecialRound(id))
	{
		//If pistol round always allow any pistol
		//If knife round always allow knife
		//If Warmup always allow warmup weapon
		WeaponType type = CSWeapons_GetWeaponType(id);
		
		#if defined WARMUP
		if((g_currentRoundSpecial == RoundType_Pistol && type == WeaponTypePistol) || (g_currentRoundSpecial == RoundType_Knife && type == WeaponTypeKnife) || (g_currentRoundSpecial == RoundType_Warmup && id == g_iWarmupWeapon))
		#else
		if((g_currentRoundSpecial == RoundType_Pistol && type == WeaponTypePistol) || (g_currentRoundSpecial == RoundType_Knife && type == WeaponTypeKnife))
		#endif
			result = true;
		else if(iRestrictVal == -1 || Restrict_ImmunityCheck(client) || (iCount < iRestrictVal))
			result = true;
	}
	if(!blockhook)
	{
		bool orgresult = result;
		Action res = Plugin_Continue;
		Call_StartForward(hCanPickupForward);
		Call_PushCell(client);
		Call_PushCell(iTeam);
		Call_PushCell(id);
		Call_PushCellRef(result);
		Call_Finish(res);
		
		if(res == Plugin_Continue)
			return orgresult;
		if(res >= Plugin_Handled)
			return false;
	}
	return result;
}

public int Native_IsSpecialRound(Handle hPlugin, int iNumParams)
{
	if(g_currentRoundSpecial == RoundType_None)
		return false;
	return true;
}

public int Native_IsWarmupRound(Handle hPlugin, int iNumParams)
{
	#if defined WARMUP
	if(g_currentRoundSpecial == RoundType_Warmup)
		return true;
	#endif
	return false;
}

public int Native_HasSpecialItem(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	if(id == CSWeapon_DEFUSER && GetEntProp(client, Prop_Send, "m_bHasDefuser") != 0)
		return true;
	else if(id == CSWeapon_ASSAULTSUIT && GetEntProp(client, Prop_Send, "m_ArmorValue") != 0 && GetEntProp(client, Prop_Send, "m_bHasHelmet") != 0)
		return true;
	else if(id == CSWeapon_KEVLAR && GetEntProp(client, Prop_Send, "m_ArmorValue") != 0 && GetEntProp(client, Prop_Send, "m_bHasHelmet") == 0)
		return true;
	else if(id == CSWeapon_NIGHTVISION && GetEntProp(client, Prop_Send, "m_bHasNightVision") != 0)
		return true;
	else if(id == CSWeapon_HEAVYASSAULTSUIT && GetEntProp(client, Prop_Send, "m_bHasHeavyArmor") != 0)
		return true;
	
	return false;
}

public int Native_SetRestriction(Handle hPlugin, int iNumParams)
{
	CSWeaponID id = GetNativeCell(1);
	int iTeam = GetNativeCell(2);
	int iAmount = GetNativeCell(3);
	
	if(id >= CSWeapon_MAX_WEAPONS_NO_KNIFES)
		return true;
	
	#if defined PERPLAYER //avoid warnings this is only needed if perplayer is compiled in.
	bool bOverride = GetNativeCell(4);
	#endif
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	if(iAmount < -1)
		iAmount = -1;
	
	if(iTeam == CS_TEAM_T)
	{
		hRestrictCVars[view_as<int>(id)][CVarTeam_T].SetInt(iAmount, true, false);
	}
	else if(iTeam == CS_TEAM_CT)
	{
		hRestrictCVars[view_as<int>(id)][CVarTeam_CT].SetInt(iAmount, true, false);
	}
	
	#if defined PERPLAYER
	if(bOverride)
	{
		Restrict_AddToOverride(iTeam, id);
	}
	#endif
	
	return true;
}

public int Native_SetGroupRestriction(Handle hPlugin, int iNumParams)
{
	WeaponType type = GetNativeCell(1);
	int iTeam = GetNativeCell(2);
	int iAmount = GetNativeCell(3);
	bool bOverride = GetNativeCell(4);
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!IsValidWeaponGroup(type))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon group index %d is invalid.", type);
	}
	
	for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
	{
		CSWeaponID id = view_as<CSWeaponID>(i);
		
		if(CSWeapons_IsValidID(id, true) && type == CSWeapons_GetWeaponType(id))
			Restrict_SetRestriction(id, iTeam, iAmount, bOverride);
	}
	return true;
}

public int Native_GetRoundType(Handle hPlugin, int iNumParams)
{
	return view_as<int>(g_currentRoundSpecial);
}

public int Native_CheckPlayerWeapons(Handle hPlugin, int iNumParams)
{
	int iVal;
	int iCount;
	
	for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES); i++)
    {
		CSWeaponID id = view_as<CSWeaponID>(i);
		
		if(!CSWeapons_IsValidID(id, true))
			continue;
		
		for(int iTeam = CS_TEAM_T; iTeam <= CS_TEAM_CT; iTeam++)
		{
			iVal = Restrict_GetRestrictValue(iTeam, id);
			
			if(iVal == -1)
				continue;
			
			iCount = Restrict_GetTeamWeaponCount(iTeam, id);
			
			if(iCount > iVal)
				Restrict_RemoveRandom(iCount-iVal, iTeam, id);
		}
	}
}

public int Native_RemoveWeaponDrop(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	int entity = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	if(!IsValidEdict(entity))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon index %d is invalid.", entity);
	}
	
	CS_DropWeapon(client, entity, true, true);
	if(AcceptEntityInput(entity, "Kill"))
		return true;
	
	return false;
}

public int Native_ImmunityCheck(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	
	if(hAdminImmunity.BoolValue && CheckCommandAccess(client, "sm_restrict_immunity_level", ADMFLAG_RESERVATION))
		return true;
	
	return false;
}

public int Native_IsAllowedForSpecialRound(Handle hPlugin, int iNumParams)
{
	CSWeaponID id = GetNativeCell(1);
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	WeaponType type = CSWeapons_GetWeaponType(id);
	
	if(type == WeaponTypeKnife)
		return true;
	
	//For pistol round and knife allow kevlar and stuff
	if((g_currentRoundSpecial == RoundType_Pistol || g_currentRoundSpecial == RoundType_Knife) && (type == WeaponTypeArmor || type == WeaponTypeOther))
		return true;
	//Pistol round allow anything in slot 1
	if(g_currentRoundSpecial == RoundType_Pistol && (type == WeaponTypePistol || type == WeaponTypeGrenade))
		return true;
	
	#if defined WARMUP
	if(g_currentRoundSpecial == RoundType_Warmup && id == g_iWarmupWeapon)
		return true;
	#endif
	
	return false;
}

public int Native_PlayRestrictSound(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid.", client);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	Action res = Plugin_Continue;
	char szForwardFile[PLATFORM_MAX_PATH];
	
	strcopy(szForwardFile, sizeof(szForwardFile), g_sCachedSound);
	
	Call_StartForward(hRestrictSoundForward);
	Call_PushCell(client);
	Call_PushCell(id);
	Call_PushStringEx(szForwardFile, sizeof(szForwardFile), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(res);
	if(res == Plugin_Continue && g_bRestrictSound)
		EmitSoundToClient(client, g_sCachedSound);
	if(res == Plugin_Changed)
		EmitSoundToClient(client, szForwardFile);
	
	return 1;
}

public int Native_AddToOverride(Handle hPlugin, int iNumParams)
{	
	#if defined PERPLAYER
	int iTeam = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	if(iTeam == CS_TEAM_T)
		g_bOverrideValues[view_as<int>(id)][CVarTeam_T] = true;
	if(iTeam == CS_TEAM_CT)
		g_bOverrideValues[view_as<int>(id)][CVarTeam_CT] = true;
	#endif
	return 1;
}

public int Native_RemoveFromOverride(Handle hPlugin, int iNumParams)
{	
	#if defined PERPLAYER
	int iTeam = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	if(iTeam == CS_TEAM_T)
		g_bOverrideValues[view_as<int>(id)][CVarTeam_T] = false;
	if(iTeam == CS_TEAM_CT)
		g_bOverrideValues[view_as<int>(id)][CVarTeam_CT] = false;
	#endif
	return 1;
}

public int Native_IsWeaponInOverride(Handle hPlugin, int iNumParams)
{	
	#if defined PERPLAYER
	int iTeam = GetNativeCell(1);
	CSWeaponID id = GetNativeCell(2);
	
	if(!IsValidTeam(iTeam))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Team index %d is invalid.", iTeam);
	}
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	if(iTeam == CS_TEAM_T && g_bOverrideValues[view_as<int>(id)][CVarTeam_T])
		return true;
	if(iTeam == CS_TEAM_CT && g_bOverrideValues[view_as<int>(id)][CVarTeam_CT])
		return true;
	#endif
	return false;
}

public int Native_IsWarmupWeapon(Handle hPlugin, int iNumParams)
{	
	#if defined WARMUP
	CSWeaponID id = GetNativeCell(1);
	
	if(!CSWeapons_IsValidID(id, true))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Weapon id %d is invalid.", id);
	}
	
	return (g_iWarmupWeapon == id && Restrict_IsWarmupRound())? true:false;
	#else
	return false;
	#endif
}
