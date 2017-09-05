#if defined __cstrike_weapons_inc__
#endinput
#endif
#define __cstrike_weapons_inc__

#include "halflife.inc"
#include "adt_trie.inc"
#include "string.inc"
#include "cstrike.inc"
#include "string.inc"

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
};

static char cstrike_szClassnames[][] =
{
	"weapon_p228",				"weapon_glock",				"weapon_scout",				"weapon_hegrenade",
	"weapon_xm1014",			"weapon_c4",				"weapon_mac10",				"weapon_aug",		
	"weapon_smokegrenade",		"weapon_elite",				"weapon_fiveseven",			"weapon_ump45",
	"weapon_sg550",				"weapon_galil",				"weapon_famas",				"weapon_usp",
	"weapon_awp",				"weapon_mp5navy",			"weapon_m249",				"weapon_m3",
	"weapon_m4a1",				"weapon_tmp",				"weapon_g3sg1",				"weapon_flashbang",
	"weapon_deagle",			"weapon_sg552",				"weapon_ak47",				"weapon_knife",
	"weapon_p90",				"item_kevlar",				"item_assaultsuit",			"weapon_galilar",
	"weapon_bizon",				"weapon_mag7",				"weapon_negev",				"weapon_sawedoff",
	"weapon_tec9",				"weapon_taser",				"weapon_hkp2000",			"weapon_mp7",
	"weapon_mp9",				"weapon_nova",				"weapon_p250",				"weapon_scar20",
	"weapon_sg556",				"weapon_ssg08",				"weapon_knifegg",			"weapon_molotov",
	"weapon_decoy",				"weapon_incgrenade",		"item_defuser",				"item_heavyassaultsuit",
	"item_cutters",				"weapon_healthshot",		"weapon_knife_t",			"weapon_m4a1_silencer",
	"weapon_usp_silencer",		"weapon_cz75a",				"weapon_revolver",			"weapon_tagrenade",
	"weapon_bayonet",			"weapon_knife_flip",		"weapon_knife_gut",			"weapon_knife_karambit",
	"weapon_knife_m9_bayonet",	"weapon_knife_tactical",	"weapon_knife_falchion",	"weapon_knife_survival_bowie",
	"weapon_knife_butterfly",	"weapon_knife_push",		"item_nvg"
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
	WeaponTypeKnife,			WeaponTypeKnife,			WeaponTypeOther
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
	SlotPrimmary,				SlotInvalid,				SlotInvalid,				SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotPrimmary,				SlotPrimmary,
	SlotPistol,					SlotKnife,					SlotPistol,					SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotPistol,					SlotPrimmary,
	SlotPrimmary,				SlotPrimmary,				SlotKnife,					SlotGrenade,
	SlotGrenade,				SlotGrenade,				SlotInvalid,				SlotInvalid,
	SlotInvalid,				SlotC4,						SlotKnife,					SlotPrimmary,
	SlotPistol,					SlotPistol,					SlotPistol,					SlotGrenade,
	SlotKnife,					SlotKnife,					SlotKnife,					SlotKnife,
	SlotKnife,					SlotKnife,					SlotKnife,					SlotKnife,
	SlotKnife,					SlotKnife,					SlotInvalid
};

static const int cstrike_iBuyTeams[] =
{
	BOTH_TEAMS,					TERROR_TEAM,				BOTH_TEAMS,					BOTH_TEAMS,
	BOTH_TEAMS,					TERROR_TEAM,				TERROR_TEAM,				CT_TEAM,		
	BOTH_TEAMS,					TERROR_TEAM,				CT_TEAM,					BOTH_TEAMS,
	CT_TEAM,					TERROR_TEAM,				CT_TEAM,					CT_TEAM,
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS,
	CT_TEAM,					CT_TEAM,					TERROR_TEAM,				BOTH_TEAMS,
	BOTH_TEAMS,					TERROR_TEAM,				TERROR_TEAM,				BOTH_TEAMS,
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
	BOTH_TEAMS,					BOTH_TEAMS,					BOTH_TEAMS
};

enum TrieWeaponInfo
{
	TrieWeapon_Slot = 0,
	TrieWeapon_BuyTeam,
	TrieWeapon_WeaponType,
	TrieWeapon_ArryIdx,
	TrieWeapon_Max
};

static Handle hWeaponIDToInfoTrie = INVALID_HANDLE;

stock CSWeapons_Init()
{
	if(hWeaponIDToInfoTrie == INVALID_HANDLE)
	{
		InitWeaponInfoTrie();
	}
}

stock InitWeaponInfoTrie()
{
	hWeaponIDToInfoTrie = CreateTrie();
	
	int info[TrieWeapon_Max];
	
	for(int i = 0; i < sizeof(cstrike_szClassnames); i++)
	{
		CSWeaponID weaponID = CS_AliasToWeaponID(cstrike_szClassnames[i]);
		
		if(weaponID == CSWeapon_NONE)
			continue;
		
		info[TrieWeapon_Slot] = view_as<int>(cstrike_iWeaponSlots[i]);
		info[TrieWeapon_BuyTeam] = view_as<int>(cstrike_iBuyTeams[i]);
		info[TrieWeapon_WeaponType] = view_as<int>(cstrike_iWeaponTypes[i]);
		info[TrieWeapon_ArryIdx] = i;
		
		if(GetEngineVersion() == Engine_CSGO && weaponID == CSWeapon_ELITE)
		{
			info[TrieWeapon_BuyTeam] = view_as<int>(BOTH_TEAMS);
		}
		
		char key[10];
		IntToString(view_as<int>(weaponID), key, sizeof(key));
		
		SetTrieArray(hWeaponIDToInfoTrie, key, info[0], view_as<int>(TrieWeapon_Max));
	}
}

stock GetWeaponInfoArrySize()
{
	return GetTrieSize(hWeaponIDToInfoTrie);
}

static stock bool GetWeaponInfoFromID(CSWeaponID weaponID, int arry[TrieWeapon_Max])
{
	char key[10];
	IntToString(view_as<int>(weaponID), key, sizeof(key));
		
	return GetTrieArray(hWeaponIDToInfoTrie, key, arry[0], view_as<int>(TrieWeapon_Max));
}

stock int GetWeaponBuyTeam(CSWeaponID weaponID)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		return info[TrieWeapon_BuyTeam];
	}
	
	return INVALID_TEAM;
}

stock WeaponType GetWeaponType(CSWeaponID weaponID)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		return view_as<WeaponType>(info[TrieWeapon_WeaponType]);
	}
	
	return WeaponTypeNone;
}

stock WeaponSlot GetWeaponSlot(CSWeaponID weaponID)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		return view_as<WeaponSlot>(info[TrieWeapon_Slot]);
	}
	
	return SlotInvalid;
}

stock bool GetWeaponClassname(CSWeaponID weaponID, char [] buffer, int size)
{
	int info[TrieWeapon_Max];
	
	if(GetWeaponInfoFromID(weaponID, info))
	{
		strcopy(buffer, size, cstrike_szClassnames[info[TrieWeapon_ArryIdx]]);
		return true;
	}
	
	return false;
}

stock CSWeaponID GetWeaponIDFromSnapshot(int index)
{	
	if(index < 0 || index >= GetTrieSize(hWeaponIDToInfoTrie))
		return CSWeapon_NONE;
	
	Handle hTemp = CreateTrieSnapshot(hWeaponIDToInfoTrie);
	
	char key[10];
	
	GetTrieSnapshotKey(hTemp, index, key, sizeof(key));
	
	delete hTemp;
	
	return view_as<CSWeaponID>(StringToInt(key));
}