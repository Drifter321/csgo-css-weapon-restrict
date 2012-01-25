#if defined __css_weapons_inc__
#endinput
#endif
#define __css_weapons_inc__

#include "adt_trie.inc"
#include "string.inc"
#include "cstrike.inc"
#include "string.inc"

static Handle:hWeaponInfoTrie;

#define COUNTERTERRORISTTEAM 3
#define TERRORISTTEAM 2
#define BOTHTEAMS 0
#define UNKNOWNTEAM -1

enum WeaponID
{
	WEAPON_NONE,
    WEAPON_P228,
    WEAPON_GLOCK,
    WEAPON_SCOUT,
    WEAPON_HEGRENADE,
    WEAPON_XM1014,
    WEAPON_C4,
    WEAPON_MAC10,
    WEAPON_AUG,
    WEAPON_SMOKEGRENADE,
    WEAPON_ELITE,
    WEAPON_FIVESEVEN,
    WEAPON_UMP45,
    WEAPON_SG550,
    WEAPON_GALIL,
    WEAPON_FAMAS,
    WEAPON_USP,
    WEAPON_AWP,
    WEAPON_MP5NAVY,
    WEAPON_M249,
    WEAPON_M3,
    WEAPON_M4A1,
    WEAPON_TMP,
    WEAPON_G3SG1,
    WEAPON_FLASHBANG,
    WEAPON_DEAGLE,
    WEAPON_SG552,
    WEAPON_AK47,
    WEAPON_KNIFE,
    WEAPON_P90,
    WEAPON_SHIELD, //Dosnt exist
    WEAPON_KEVLAR, //item_
    WEAPON_ASSAULTSUIT,//item_
    WEAPON_NIGHTVISION,//item_
	WEAPON_DEFUSER //Not a valid ID for GetWeaponPrice
};
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
	WeaponTypeNone
};
enum WeaponSlot
{
	SlotNone = -1,
	SlotPrimmary = 0,
	SlotPistol = 1,
	SlotKnife = 2,
	SlotGrenade = 3,
	SlotC4 = 4,
	SlotUnknown = 5
};
enum WeaponInfo
{
	WeaponID:InfoID,
	WeaponSlot:InfoSlot,
	WeaponType:InfoType,
	InfoTeam
};

new const String:weaponNames[_:WeaponID][] = 
{ 
	"none",			"p228",			"glock",		"scout",		
	"hegrenade",	"xm1014",		"c4",			"mac10",		
	"aug",			"smokegrenade",	"elite",		"fiveseven",
	"ump45",		"sg550",		"galil",		"famas",
	"usp",			"awp",			"mp5navy",		"m249",
	"m3",			"m4a1",			"tmp",			"g3sg1",
	"flashbang",	"deagle",		"sg552",		"ak47",
	"knife",		"p90",			"shield",		"vest",			
	"vesthelm",		"nvgs",			"defuser"
};
new const WeaponType:weaponGroups[_:WeaponID] = 
{ 
	_:WeaponTypeNone,		_:WeaponTypePistol,		_:WeaponTypePistol,		_:WeaponTypeSniper,	
	_:WeaponTypeGrenade,	_:WeaponTypeShotgun,	_:WeaponTypeOther,		_:WeaponTypeSMG,
	_:WeaponTypeRifle,		_:WeaponTypeGrenade,	_:WeaponTypePistol,		_:WeaponTypePistol,
	_:WeaponTypeSMG,		_:WeaponTypeSniper,		_:WeaponTypeRifle,		_:WeaponTypeRifle,
	_:WeaponTypePistol,		_:WeaponTypeSniper,		_:WeaponTypeSMG,		_:WeaponTypeMachineGun,
	_:WeaponTypeShotgun,	_:WeaponTypeRifle,		_:WeaponTypeSMG,		_:WeaponTypeSniper,
	_:WeaponTypeGrenade,	_:WeaponTypePistol,     _:WeaponTypeRifle,		_:WeaponTypeRifle,
	_:WeaponTypeKnife,		_:WeaponTypeSMG,		_:WeaponTypeShield,		_:WeaponTypeArmor,
	_:WeaponTypeArmor,		_:WeaponTypeOther,		_:WeaponTypeOther
};
new const WeaponSlot:weaponSlots[_:WeaponID] = 
{ 
	_:SlotUnknown,		_:SlotPistol,		_:SlotPistol,		_:SlotPrimmary,	
	_:SlotGrenade,		_:SlotPrimmary,		_:SlotC4,			_:SlotPrimmary,
	_:SlotPrimmary,		_:SlotGrenade,		_:SlotPistol,		_:SlotPistol,
	_:SlotPrimmary,		_:SlotPrimmary,		_:SlotPrimmary,		_:SlotPrimmary,
	_:SlotPistol,		_:SlotPrimmary,		_:SlotPrimmary,		_:SlotPrimmary,
	_:SlotPrimmary,		_:SlotPrimmary,		_:SlotPrimmary,		_:SlotPrimmary,
	_:SlotGrenade,		_:SlotPistol,		_:SlotPrimmary,		_:SlotPrimmary,
	_:SlotKnife,		_:SlotPrimmary, 	_:SlotUnknown,		_:SlotNone,
	_:SlotNone,			_:SlotNone,			_:SlotNone
};
/*new const weaponPrices[_:WeaponID] = 
{//These are wrong i havent fixed them...
	0,		1000,	650,	0,	
	0,		200,	1250,	200,
	300,	300,	2000,	2500,
	2750,	3500,	4750,	5000,
	2250,	3100,	3500,	4200,
	400,	500,	600,	650,
	800,	750,	1700,	3000,
	1400,	1250,	1500,	1700,
	2350,	5750,	0
};*/
new const BuyTeams[_:WeaponID] = 
{ 
	UNKNOWNTEAM,			BOTHTEAMS,				BOTHTEAMS,				BOTHTEAMS,	
	BOTHTEAMS,				BOTHTEAMS,				TERRORISTTEAM,			TERRORISTTEAM,
	COUNTERTERRORISTTEAM,	BOTHTEAMS,				TERRORISTTEAM,			COUNTERTERRORISTTEAM,
	BOTHTEAMS,				COUNTERTERRORISTTEAM,	TERRORISTTEAM,			COUNTERTERRORISTTEAM,
	BOTHTEAMS,				BOTHTEAMS,				BOTHTEAMS,				BOTHTEAMS,
	BOTHTEAMS,				COUNTERTERRORISTTEAM,	COUNTERTERRORISTTEAM,	TERRORISTTEAM,
	BOTHTEAMS,				BOTHTEAMS,				TERRORISTTEAM,			TERRORISTTEAM,
	BOTHTEAMS,				BOTHTEAMS,				UNKNOWNTEAM,			BOTHTEAMS,
	BOTHTEAMS,				BOTHTEAMS,				COUNTERTERRORISTTEAM
};
stock CSWeapons_Init()
{
	if(hWeaponInfoTrie == INVALID_HANDLE)
	{
		InitWeaponInfoTrie();
	}
}
stock InitWeaponInfoTrie()
{
	hWeaponInfoTrie = CreateTrie();
	new info[WeaponInfo];
	for(new i = 0; i < _:WeaponID; i++)
	{
		info[InfoID] = WeaponID:i;
		info[InfoSlot] = weaponSlots[WeaponID:i];
		info[InfoType] = weaponGroups[WeaponID:i];
		info[InfoTeam] = BuyTeams[WeaponID:i]
		
		SetTrieArray(hWeaponInfoTrie, weaponNames[WeaponID:i], info[0], _:WeaponInfo);
	}
}
stock WeaponID:GetWeaponID(const String:weapon[])
{
	decl info[WeaponInfo];
	if(GetWeaponInfo(weapon, info))
		return info[InfoID]
	
	return WEAPON_NONE;
}
stock WeaponSlot:GetWeaponSlot(const String:weapon[])
{
	decl info[WeaponInfo];
	if(GetWeaponInfo(weapon, info))
		return info[InfoSlot]
	
	return SlotUnknown;
}
stock WeaponType:GetWeaponType(const String:weapon[])
{
	decl info[WeaponInfo];
	if(GetWeaponInfo(weapon, info))
		return info[InfoType]
	
	return WeaponTypeNone;
}
stock bool:CanTeamBuyWeapon(team, const String:weapon[])
{
	if(team < TERRORISTTEAM || team > COUNTERTERRORISTTEAM)
		return true;
	
	decl info[WeaponInfo];
	if(GetWeaponInfo(weapon, info))
	{	
		if(info[InfoTeam] == 0 || info[InfoTeam] == team)
			return true;
		
		return false;
	}
	return true;
}
stock GetWeaponPriceFromName(client, const String:weapon[], bool:defaultprice)
{
	new WeaponID:id = GetWeaponID(weapon);
	
	return GetWeaponPrice(client, id, defaultprice);
}
stock GetWeaponPrice(client, WeaponID:id, bool:defaultprice=false)
{	
	if(id > WEAPON_DEFUSER || id == WEAPON_NONE)
		return 0;
	if(id == WEAPON_DEFUSER)
		return 200;
	
	return CS_GetWeaponPrice(client, CSWeaponID:_:id, defaultprice);
}
stock WeaponSlot:GetSlotFromWeaponID(WeaponID:id)
{
	return weaponSlots[_:id]
}
stock WeaponType:GetWeaponTypeFromID(WeaponID:id)
{
	return weaponGroups[_:id]
} 
stock bool:GetWeaponInfo(const String:weapon[], info[WeaponInfo])
{
	if(hWeaponInfoTrie == INVALID_HANDLE)
		InitWeaponInfoTrie();
	
	decl String:CheckWeapon[64];
	strcopy(CheckWeapon, sizeof(CheckWeapon), weapon);
	new len = strlen(weapon);
	for(new i = 0; i < len; i++)
	{
		CheckWeapon[i] = CharToLower(weapon[i]);
	}

	if(GetTrieArray(hWeaponInfoTrie, CheckWeapon, info[0], _:WeaponInfo))
		return true;
	
	if(ReplaceString(CheckWeapon, sizeof(CheckWeapon), "weapon_", "", false) == 1 || ReplaceString(CheckWeapon, sizeof(CheckWeapon), "item_", "", false) == 1)
	{
		if(GetTrieArray(hWeaponInfoTrie, CheckWeapon, info[0], _:WeaponInfo))
			return true;
	}
	
	return false;
}