#if defined __cstrike_weapons_inc__
#endinput
#endif
#define __cstrike_weapons_inc__

#include "halflife.inc"
#include "adt_trie.inc"
#include "string.inc"
#include "cstrike.inc"

#define CT_TEAM 3
#define TERROR_TEAM 2
#define BOTH_TEAMS 1
#define INVALID_TEAM -1

enum WeaponType
{
	WeaponTypePistol,
	WeaponTypeSMG,
	WeaponTypeShotgun,
	WeaponTypeRifle,
	WeaponTypeSniper,
	WeaponTypeGrenade,
	WeaponTypeArmor,
	WeaponTypeMachineGun,
	WeaponTypeKnife,
	WeaponTypeOther,
	WeaponTypeShield,
	WeaponTypeNone,
	WeaponTypeTaser
};

enum WeaponSlot
{
	SlotInvalid = -1,
	SlotPrimmary = 0,
	SlotPistol = 1,
	SlotKnife = 2,
	SlotGrenade = 3,
	SlotC4 = 4,
	SlotNone = 5,
};

static char cstrike_szClassnames[][] =
{
	"weapon_p228",					"weapon_glock",				"weapon_scout",				"weapon_hegrenade",
	"weapon_xm1014",				"weapon_c4",				"weapon_mac10",				"weapon_aug",		
	"weapon_smokegrenade",			"weapon_elite",				"weapon_fiveseven",			"weapon_ump45",
	"weapon_sg550",					"weapon_galil",				"weapon_famas",				"weapon_usp",
	"weapon_awp",					"weapon_mp5navy",			"weapon_m249",				"weapon_m3",
	"weapon_m4a1",					"weapon_tmp",				"weapon_g3sg1",				"weapon_flashbang",
	"weapon_deagle",				"weapon_sg552",				"weapon_ak47",				"weapon_knife",
	"weapon_p90",					"item_kevlar",				"item_assaultsuit",			"weapon_galilar",
	"weapon_bizon",					"weapon_mag7",				"weapon_negev",				"weapon_sawedoff",
	"weapon_tec9",					"weapon_taser",				"weapon_hkp2000",			"weapon_mp7",
	"weapon_mp9",					"weapon_nova",				"weapon_p250",				"weapon_scar20",
	"weapon_sg556",					"weapon_ssg08",				"weapon_knifegg",			"weapon_molotov",
	"weapon_decoy",					"weapon_incgrenade",		"item_defuser",				"item_heavyassaultsuit",
	"item_cutters",					"weapon_healthshot",		"weapon_knife_t",			"weapon_m4a1_silencer",
	"weapon_usp_silencer",			"weapon_cz75a",				"weapon_revolver",			"weapon_tagrenade",
	"weapon_bayonet",				"weapon_knife_flip",		"weapon_knife_gut",			"weapon_knife_karambit",
	"weapon_knife_m9_bayonet",		"weapon_knife_tactical",	"weapon_knife_falchion",	"weapon_knife_survival_bowie",
	"weapon_knife_butterfly",		"weapon_knife_push",		"item_nvg", 				"weapon_knife_ursus",
	"weapon_knife_gypsy_jackknife", "weapon_knife_stiletto",	"weapon_knife_widowmaker",	"weapon_fists",
	"weapon_breachcharge",			"weapon_tablet",			"weapon_melee",				"weapon_axe",
	"weapon_hammer",				"weapon_spanner",			"weapon_knife_ghost",		"weapon_firebomb",
	"weapon_diversion",				"weapon_frag_grenade",		"weapon_snowball",			"weapon_bumpmine",
};

static const WeaponType cstrike_iWeaponTypes[] =
{
	WeaponTypePistol,			WeaponTypePistol,			WeaponTypeSniper,			WeaponTypeGrenade,
	WeaponTypeShotgun,			WeaponTypeOther,			WeaponTypeSMG,				WeaponTypeRifle,		
	WeaponTypeGrenade,			WeaponTypePistol,			WeaponTypePistol,			WeaponTypeSMG,
	WeaponTypeSniper,			WeaponTypeRifle,			WeaponTypeRifle,			WeaponTypePistol,
	WeaponTypeSniper,			WeaponTypeSMG,				WeaponTypeMachineGun,		WeaponTypeShotgun,
	WeaponTypeRifle,			WeaponTypeSMG,				WeaponTypeSniper,			WeaponTypeGrenade,
	WeaponTypePistol,			WeaponTypeRifle,			WeaponTypeRifle,			WeaponTypeKnife,
	WeaponTypeSMG,				WeaponTypeArmor,			WeaponTypeArmor,			WeaponTypeRifle,
	WeaponTypeSMG,				WeaponTypeShotgun,			WeaponTypeMachineGun,		WeaponTypeShotgun,
	WeaponTypePistol,			WeaponTypeTaser,			WeaponTypePistol,			WeaponTypeSMG,
	WeaponTypeSMG,				WeaponTypeShotgun,			WeaponTypePistol,			WeaponTypeSniper,
	WeaponTypeRifle,			WeaponTypeSniper,			WeaponTypeKnife,			WeaponTypeGrenade,
	WeaponTypeGrenade,			WeaponTypeGrenade,			WeaponTypeOther,			WeaponTypeArmor,
	WeaponTypeOther,			WeaponTypeOther,			WeaponTypeKnife,			WeaponTypeRifle,
	WeaponTypePistol,			WeaponTypePistol,			WeaponTypePistol,			WeaponTypeGrenade,
	WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,
	WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,
	WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeOther,			WeaponTypeKnife,
	WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,
	WeaponTypeGrenade,			WeaponTypeOther,			WeaponTypeKnife,			WeaponTypeKnife,
	WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeGrenade,
	WeaponTypeGrenade,			WeaponTypeGrenade,			WeaponTypeGrenade,			WeaponTypeGrenade,
};

static const WeaponSlot cstrike_iWeaponSlots[] =
{
	SlotPistol,					SlotPistol,					SlotPrimmary,				SlotGrenade,
	SlotPrimmary,				SlotC4,						SlotPrimmary,				SlotPrimmary,		
	SlotGrenade,				SlotPistol,					SlotPistol,					SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotPrimmary,				SlotPistol,
	SlotPrimmary,				SlotPrimmary,				SlotPrimmary,				SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotPrimmary,				SlotGrenade,
	SlotPistol,					SlotPrimmary,				SlotPrimmary,				SlotKnife,
	SlotPrimmary,				SlotNone,					SlotNone,					SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotPrimmary,				SlotPrimmary,
	SlotPistol,					SlotKnife,					SlotPistol,					SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotPistol,					SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotKnife,					SlotGrenade,
	SlotGrenade,				SlotGrenade,				SlotNone,					SlotNone,
	SlotNone,					SlotC4,						SlotKnife,					SlotPrimmary,
	SlotPistol,					SlotPistol,					SlotPistol,					SlotGrenade,
	SlotKnife,					SlotKnife,					SlotKnife,					SlotKnife,
	SlotKnife,					SlotKnife,					SlotKnife,					SlotKnife,
	SlotKnife,					SlotKnife,					SlotNone,					SlotKnife,
	SlotKnife,					SlotKnife,					SlotKnife,					SlotKnife,
	SlotGrenade,				SlotNone,					SlotKnife,					SlotKnife,
	SlotKnife,					SlotKnife,					SlotKnife,					SlotGrenade,
	SlotGrenade,				SlotGrenade,				SlotGrenade,				SlotGrenade,
};

static const int cstrike_iBuyTeams[] =
{
	BOTH_TEAMS,					TERROR_TEAM,				BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					TERROR_TEAM,				TERROR_TEAM,				CT_TEAM,		
	BOTH_TEAMS,					TERROR_TEAM,				CT_TEAM,					BOTH_TEAMS,
	CT_TEAM,					TERROR_TEAM,				CT_TEAM,					CT_TEAM,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	CT_TEAM,					CT_TEAM,					TERROR_TEAM,				BOTH_TEAMS,
	BOTH_TEAMS,					TERROR_TEAM,				TERROR_TEAM,				CT_TEAM,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					TERROR_TEAM,
	BOTH_TEAMS,					CT_TEAM,					BOTH_TEAMS,					TERROR_TEAM,
	TERROR_TEAM,				BOTH_TEAMS,					CT_TEAM,					BOTH_TEAMS,
	CT_TEAM,					BOTH_TEAMS,					BOTH_TEAMS,					CT_TEAM,
	TERROR_TEAM,				BOTH_TEAMS,					BOTH_TEAMS,					TERROR_TEAM,
	BOTH_TEAMS,					CT_TEAM,					CT_TEAM,					BOTH_TEAMS,
	CT_TEAM,					BOTH_TEAMS,					TERROR_TEAM,				CT_TEAM,
	CT_TEAM,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
};

enum TrieWeaponInfo
{
	TrieWeapon_Slot = 0,
	TrieWeapon_BuyTeam,
	TrieWeapon_WeaponType,
	TrieWeapon_Max
};

static StringMap hWeaponIDToInfoTrie = null;
static StringMap hWeaponIDToClassname = null;
static StringMap hWeaponSlotMap = null;
static EngineVersion iEngineVersion;

stock void CSWeapons_Init()
{
	if(hWeaponIDToInfoTrie == null)
	{
		iEngineVersion = GetEngineVersion();
		InitWeaponInfoTrie();
	}
}

static stock CSWeaponID AliastToID(const char [] szClassname) //Internal use only.
{
	if(StrEqual(szClassname, "item_defuser"))
		return CSWeapon_DEFUSER;
		
	return CS_AliasToWeaponID(szClassname);
}

static stock void InitWeaponInfoTrie()
{
	hWeaponIDToInfoTrie = new StringMap();
	hWeaponIDToClassname = new StringMap();

	CreateSlotMap();

	int info[TrieWeapon_Max];
	
	for(int i = 0; i < sizeof(cstrike_szClassnames); i++)
	{
		CSWeaponID weaponID = CSWeapon_NONE;
		
		if(iEngineVersion == Engine_CSGO && StrEqual("weapon_mp5navy", cstrike_szClassnames[i]))
		{
			weaponID = CS_AliasToWeaponID("weapon_mp5sd");
		}
		else
		{
			weaponID = CS_AliasToWeaponID(cstrike_szClassnames[i]);
		}
		
		if(weaponID == CSWeapon_NONE)
			continue;
		
		info[TrieWeapon_Slot] = view_as<int>(cstrike_iWeaponSlots[i]);
		info[TrieWeapon_BuyTeam] = view_as<int>(cstrike_iBuyTeams[i]);
		info[TrieWeapon_WeaponType] = view_as<int>(cstrike_iWeaponTypes[i]);
		//info[TrieWeapon_ArryIdx] = i;
		
		if(iEngineVersion == Engine_CSGO && weaponID == CSWeapon_ELITE)
		{
			info[TrieWeapon_BuyTeam] = view_as<int>(BOTH_TEAMS);
		}
		
		char key[10];
		IntToString(view_as<int>(weaponID), key, sizeof(key));
		
		hWeaponIDToInfoTrie.SetArray(key, info[0], view_as<int>(TrieWeapon_Max));
		hWeaponIDToClassname.SetString(key, cstrike_szClassnames[i]);
	}

	if(iEngineVersion == Engine_CSGO)
	{
		//Parse items_games.txt and add items.
		KeyValues kvItems = new KeyValues("");
		KeyValues kvPrefabs = new KeyValues("");

		kvItems.ImportFromFile("scripts/items/items_game.txt");
		kvPrefabs.ImportFromFile("scripts/items/items_game.txt");

		if(kvItems.JumpToKey("items") && kvPrefabs.JumpToKey("prefabs"))
		{
			if(kvItems.GotoFirstSubKey(true))
			{
				addWeaponFromItems(kvItems, kvPrefabs);

				while(kvItems.GotoNextKey(true))
				{
					addWeaponFromItems(kvItems, kvPrefabs);
				}
			}
		}
		
		delete kvItems;
		delete kvPrefabs
	}
}

static stock void addWeaponFromItems(KeyValues kvItems, KeyValues kvPrefabs)
{
	char szSectionName[10];
	
	if(kvItems.GetSectionName(szSectionName, sizeof(szSectionName)))
	{
		int iDefIndex = StringToInt(szSectionName);
		char szClassname[128];
		char szPrefab[128];

		if(!iDefIndex || !kvItems.GetString("name", szClassname, sizeof(szClassname)) || (StrContains(szClassname, "weapon_") == -1 && StrContains(szClassname, "item_") == -1) || !kvItems.GetString("prefab", szPrefab, sizeof(szPrefab)))
			return;

		WeaponType iItemType;

		if(!hWeaponSlotMap.GetValue(szClassname, iItemType))
		{
			if(!hWeaponSlotMap.GetValue(szPrefab, iItemType))
			{
				char szItemType[128];
				kvItems.GetString("item_sub_position", szItemType, sizeof(szItemType));

				if(!hWeaponSlotMap.GetValue(szItemType, iItemType))
					iItemType = WeaponTypeOther;
			}
		}

		int iBuyTeam = BOTH_TEAMS;

		if(kvItems.JumpToKey("used_by_classes"))
		{
			int iTerroroists = kvItems.GetNum("terrorists", -1)
			int iCounterTerroroists = kvItems.GetNum("counter-terrorists", -1)
			iBuyTeam = (iTerroroists == 1 && iCounterTerroroists == 1) ? BOTH_TEAMS : iTerroroists == 1 ? TERROR_TEAM : iCounterTerroroists == 1 ? CT_TEAM : BOTH_TEAMS;
			kvItems.GoBack();
		}
		else if(kvPrefabs.JumpToKey(szPrefab))
		{
			if(kvPrefabs.JumpToKey("used_by_classes"))
			{
				int iTerroroists = kvPrefabs.GetNum("terrorists", -1)
				int iCounterTerroroists = kvPrefabs.GetNum("counter-terrorists", -1)
				iBuyTeam = (iTerroroists == 1 && iCounterTerroroists == 1) ? BOTH_TEAMS : iTerroroists == 1 ? TERROR_TEAM : iCounterTerroroists == 1 ? CT_TEAM : BOTH_TEAMS;
				kvPrefabs.GoBack();
			}
			kvPrefabs.GoBack();
		}

		WeaponSlot iSlot = StrEqual(szClassname, "weapon_c4") || StrEqual(szClassname, "weapon_healthshot") ? SlotC4 : iItemType == WeaponTypePistol ? SlotPistol : (iItemType == WeaponTypeKnife || iItemType == WeaponTypeTaser) ? SlotKnife : iItemType == WeaponTypeGrenade ? SlotGrenade : (iItemType == WeaponTypeArmor || iItemType == WeaponTypeOther || iItemType == WeaponTypeShield) ? SlotNone : SlotPrimmary;

		int info[TrieWeapon_Max];
		info[TrieWeapon_Slot] = view_as<int>(iSlot);
		info[TrieWeapon_BuyTeam] = view_as<int>(iBuyTeam);
		info[TrieWeapon_WeaponType] = view_as<int>(iItemType);

		CSWeaponID weaponID = CS_AliasToWeaponID(szClassname);
		if(weaponID)
		{
			char key[10];
			IntToString(view_as<int>(weaponID), key, sizeof(key));
			hWeaponIDToInfoTrie.SetArray(key, info[0], view_as<int>(TrieWeapon_Max));
			hWeaponIDToClassname.SetString(key, szClassname);
		}
	}
}

static stock void CreateSlotMap()
{
	hWeaponSlotMap = new StringMap();
	hWeaponSlotMap.SetValue("grenade0", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("grenade1", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("grenade2", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("grenade3", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("grenade4", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("smg0", WeaponTypeSMG);
	hWeaponSlotMap.SetValue("smg1", WeaponTypeSMG);
	hWeaponSlotMap.SetValue("smg2", WeaponTypeSMG);
	hWeaponSlotMap.SetValue("smg3", WeaponTypeSMG);
	hWeaponSlotMap.SetValue("smg4", WeaponTypeSMG);
	hWeaponSlotMap.SetValue("heavy0", WeaponTypeShotgun);
	hWeaponSlotMap.SetValue("heavy1", WeaponTypeShotgun);
	hWeaponSlotMap.SetValue("heavy2", WeaponTypeShotgun);
	hWeaponSlotMap.SetValue("heavy3", WeaponTypeMachineGun);
	hWeaponSlotMap.SetValue("heavy4", WeaponTypeMachineGun);
	hWeaponSlotMap.SetValue("rifle0", WeaponTypeRifle);
	hWeaponSlotMap.SetValue("rifle1", WeaponTypeRifle);
	hWeaponSlotMap.SetValue("rifle2", WeaponTypeSniper);
	hWeaponSlotMap.SetValue("rifle3", WeaponTypeRifle);
	hWeaponSlotMap.SetValue("rifle4", WeaponTypeSniper);
	hWeaponSlotMap.SetValue("rifle5", WeaponTypeSniper);
	hWeaponSlotMap.SetValue("secondary0", WeaponTypePistol);
	hWeaponSlotMap.SetValue("secondary1", WeaponTypePistol);
	hWeaponSlotMap.SetValue("secondary2", WeaponTypePistol);
	hWeaponSlotMap.SetValue("secondary3", WeaponTypePistol);
	hWeaponSlotMap.SetValue("secondary4", WeaponTypePistol);
	hWeaponSlotMap.SetValue("none", WeaponTypeOther);

	hWeaponSlotMap.SetValue("item_kevlar", WeaponTypeArmor);
	hWeaponSlotMap.SetValue("item_assaultsuit", WeaponTypeArmor);
	hWeaponSlotMap.SetValue("item_heavyassaultsuit", WeaponTypeArmor);
	hWeaponSlotMap.SetValue("weapon_taser", WeaponTypeTaser);
	hWeaponSlotMap.SetValue("weapon_shield", WeaponTypeShield);
	hWeaponSlotMap.SetValue("weapon_tagrenade", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_breachcharge", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_firebomb", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_diversion", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_frag_grenade", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_snowball", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_bumpmine", WeaponTypeGrenade);
	hWeaponSlotMap.SetValue("weapon_fists", WeaponTypeKnife);
	hWeaponSlotMap.SetValue("melee", WeaponTypeKnife);
	hWeaponSlotMap.SetValue("melee_unusual", WeaponTypeKnife);
	hWeaponSlotMap.SetValue("weapon_melee_prefab", WeaponTypeKnife);
	hWeaponSlotMap.SetValue("weapon_tablet", WeaponTypeOther);
	hWeaponSlotMap.SetValue("weapon_zone_repulsor", WeaponTypeOther);
}

stock int CSWeapons_GetWeaponInfoArrySize()
{
	return hWeaponIDToInfoTrie.Size;
}

static stock bool GetWeaponInfoFromID(CSWeaponID weaponID, int arry[TrieWeapon_Max])
{
	char key[10];
	IntToString(view_as<int>(weaponID), key, sizeof(key));
	
	return hWeaponIDToInfoTrie.GetArray(key, arry[0], sizeof(arry));
}

stock int CSWeapons_GetWeaponBuyTeam(CSWeaponID weaponID)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		return info[TrieWeapon_BuyTeam];
	}
	
	return INVALID_TEAM;
}

stock WeaponType CSWeapons_GetWeaponType(CSWeaponID weaponID)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		return view_as<WeaponType>(info[TrieWeapon_WeaponType]);
	}
	
	return WeaponTypeNone;
}

stock WeaponSlot CSWeapons_GetWeaponSlot(CSWeaponID weaponID)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		return view_as<WeaponSlot>(info[TrieWeapon_Slot]);
	}
	
	return SlotInvalid;
}

stock bool CSWeapons_GetWeaponClassname(CSWeaponID weaponID, char [] buffer, int size)
{
	if(GetEngineVersion() == Engine_CSGO && weaponID == CSWeapon_MP5NAVY)
	{
		strcopy(buffer, size, "weapon_mp5sd");
		return true;
	}
	
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		char key[10];
		IntToString(view_as<int>(weaponID), key, sizeof(key));
		hWeaponIDToClassname.GetString(key, buffer, size);
		return true;
	}
	
	return false;
}

stock int CSWeapons_GetWeaponPrice(int client, CSWeaponID weaponID, bool defaultprice = false)
{
	if(!CSWeapons_IsValidID(weaponID, true))
		return 0;
	else if(iEngineVersion == Engine_CSS && weaponID == CSWeapon_DEFUSER)
		return 200;

	return CS_GetWeaponPrice(client, weaponID, defaultprice);
}

stock bool CSWeapons_IsValidID(CSWeaponID weaponID, bool defuserValid = false, bool allKnifesValid = false)
{
	if(!allKnifesValid && weaponID != CSWeapon_KNIFE && CSWeapons_GetWeaponType(weaponID) == WeaponTypeKnife)
		return false;
	else if(defuserValid && weaponID == CSWeapon_DEFUSER) //This is for CS:S
		return true;
	else if(weaponID >= CSWeapon_MAX_WEAPONS_NO_KNIFES)
		return false;
	
	return CS_IsValidWeaponID(weaponID);
}

stock int CSWeapons_GetAlias(CSWeaponID weaponID, char [] szBuffer, int size, bool defuserValid = false)
{
	if(CSWeapons_IsValidID(weaponID, defuserValid))
	{
		if(weaponID == CSWeapon_DEFUSER)
			return strcopy(szBuffer, size, "defuser");
			
		return CS_WeaponIDToAlias(weaponID, szBuffer, size);
	}
	return strcopy(szBuffer, size, "");
}

stock CSWeaponID CSWeapons_GetWeaponIDFromSnapshot(int index)
{	
	if(index < 0 || index >= hWeaponIDToInfoTrie.Size)
		return CSWeapon_NONE;
	
	static StringMapSnapshot snap = null;
	
	if(snap == null)
	{
		snap = hWeaponIDToInfoTrie.Snapshot();
	}
	
	char key[10];
	
	snap.GetKey(index, key, sizeof(key));
	
	return view_as<CSWeaponID>(StringToInt(key));
}