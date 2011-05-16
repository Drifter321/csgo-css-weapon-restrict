#define MAX_WEAPONS 33
#define PLUGIN_VERSION "2.3.5"

new Handle:WeaponTrieCT = INVALID_HANDLE;
new Handle:WeaponTrieT = INVALID_HANDLE;
new Handle:WeaponSlotTrie = INVALID_HANDLE;
new Handle:WeaponPriceTrie = INVALID_HANDLE;
new Handle:WeaponTeamTrie = INVALID_HANDLE;
new Handle:AllowPickup = INVALID_HANDLE;
new Handle:AdminImmunity = INVALID_HANDLE;
#if defined WARMUP
new Handle:WarmUp = INVALID_HANDLE;
new Handle:WarmupTime = INVALID_HANDLE;
new Handle:grenadegive = INVALID_HANDLE;
new Handle:ffcvar = INVALID_HANDLE;
new Handle:warmupff = INVALID_HANDLE;
new Handle:WarmupRespawnTime = INVALID_HANDLE;
new Handle:WarmupRespawn = INVALID_HANDLE;
#endif

#if defined PERPLAYER
new Handle:PerPlayerRestrict = INVALID_HANDLE;
#endif

//Weapon things
new String:g_WeaponNames[MAX_WEAPONS][64] = 
{ 
	"vesthelm",		 "vest",      "c4",			"knife",
	"defuser",       "nvgs",      "flashbang", "hegrenade",
	"smokegrenade",  "galil",     "ak47",      "scout",
	"sg552",         "awp",       "g3sg1",     "famas", 
	"m4a1",          "aug",       "sg550",     "glock",
	"usp",           "p228",      "deagle",    "elite",
	"fiveseven",     "m3",        "xm1014",    "mac10",
	"tmp",           "mp5navy",   "ump45",     "p90",
	"m249"
};
new g_WeaponSlot[MAX_WEAPONS] = 
{ 
	-1,		-1,		4,		2,
	-1,		-1,		3,		3,
	3,		0,     	0,      0,
	0,		0,		0,		0, 
	0,		0,		0,		1,
	1,		1,		1,		1,
	1,		0,		0,		0,
	0,		0,		0,		0,
	0
};
new g_WeaponPrice[MAX_WEAPONS] = 
{ 
	1000,	650,	0,			0,
	200,	1250,	200,		300,
	300,	2000,	2500,		2750,
	3500,	4750,	5000,		2250, 
	3100,	3500,	4200,		400,
	500,	600,	650,		800,
	750,	1700,	3000,		1400,
	1250,	1500,	1700,		2350,
	5750
};
new g_WeaponTeam[MAX_WEAPONS] = 
{ 
	0,		 0,      2,		0,
	3,       0,      0,		0,
	0,  	 2,      2,     0,
	2,       0,      2,     3, 
	3,       3,      3,     0,
	0,       0,      0,     2,
	3,       0,      0,     2,
	3,       0,      0,     0,
	0
};

//Weapon Handles
new Handle:vesthelmct = INVALID_HANDLE;
new Handle:vesthelmt = INVALID_HANDLE;
new Handle:vestct = INVALID_HANDLE;
new Handle:vestt = INVALID_HANDLE;
new Handle:nvgsct = INVALID_HANDLE;
new Handle:nvgst = INVALID_HANDLE;
new Handle:flashbangct = INVALID_HANDLE;
new Handle:flashbangt = INVALID_HANDLE;
new Handle:hegrenadect = INVALID_HANDLE;
new Handle:hegrenadet = INVALID_HANDLE;
new Handle:smokegrenadect = INVALID_HANDLE;
new Handle:smokegrenadet = INVALID_HANDLE;
new Handle:galilct = INVALID_HANDLE;
new Handle:galilt = INVALID_HANDLE;
new Handle:ak47ct = INVALID_HANDLE;
new Handle:ak47t = INVALID_HANDLE;
new Handle:scoutct = INVALID_HANDLE;
new Handle:scoutt = INVALID_HANDLE;
new Handle:sg552ct = INVALID_HANDLE;
new Handle:sg552t = INVALID_HANDLE;
new Handle:awpct = INVALID_HANDLE;
new Handle:awpt = INVALID_HANDLE;
new Handle:g3sg1ct = INVALID_HANDLE;
new Handle:g3sg1t = INVALID_HANDLE;
new Handle:famasct = INVALID_HANDLE;
new Handle:famast = INVALID_HANDLE;
new Handle:m4a1ct = INVALID_HANDLE;
new Handle:m4a1t = INVALID_HANDLE;
new Handle:augct = INVALID_HANDLE;
new Handle:augt = INVALID_HANDLE;
new Handle:sg550ct = INVALID_HANDLE;
new Handle:sg550t = INVALID_HANDLE;
new Handle:glockct = INVALID_HANDLE;
new Handle:glockt = INVALID_HANDLE;
new Handle:uspct = INVALID_HANDLE;
new Handle:uspt = INVALID_HANDLE;
new Handle:p228ct = INVALID_HANDLE;
new Handle:p228t = INVALID_HANDLE;
new Handle:elitect = INVALID_HANDLE;
new Handle:elitet = INVALID_HANDLE;
new Handle:deaglect = INVALID_HANDLE;
new Handle:deaglet = INVALID_HANDLE;
new Handle:fivesevenct = INVALID_HANDLE;
new Handle:fivesevent = INVALID_HANDLE;
new Handle:m3ct = INVALID_HANDLE;
new Handle:m3t = INVALID_HANDLE;
new Handle:xm1014ct = INVALID_HANDLE;
new Handle:xm1014t = INVALID_HANDLE;
new Handle:mac10ct = INVALID_HANDLE;
new Handle:mac10t = INVALID_HANDLE;
new Handle:tmpct = INVALID_HANDLE;
new Handle:tmpt = INVALID_HANDLE;
new Handle:mp5navyct = INVALID_HANDLE;
new Handle:mp5navyt = INVALID_HANDLE;
new Handle:ump45ct = INVALID_HANDLE;
new Handle:ump45t = INVALID_HANDLE;
new Handle:p90ct = INVALID_HANDLE;
new Handle:p90t = INVALID_HANDLE;
new Handle:m249ct = INVALID_HANDLE;
new Handle:m249t = INVALID_HANDLE;
new Handle:defuser = INVALID_HANDLE;
new Handle:c4 =INVALID_HANDLE;

//Convar Handles
new Handle:g_version = INVALID_HANDLE;

CreateWeaponTrie()
{
	WeaponPriceTrie = CreateTrie();
	WeaponSlotTrie = CreateTrie();
	WeaponTeamTrie = CreateTrie();
	WeaponTrieCT = CreateTrie();
	WeaponTrieT = CreateTrie();
	for(new i = 0; i < MAX_WEAPONS; i++)
	{
		if(!StrEqual(g_WeaponNames[i],  "knife", false))
		{
			if(!StrEqual(g_WeaponNames[i],  "c4", false))
				SetTrieValue(WeaponTrieCT, g_WeaponNames[i], -1);
			
			if(!StrEqual(g_WeaponNames[i],  "defuser", false))
				SetTrieValue(WeaponTrieT, g_WeaponNames[i], -1);
			
			SetTrieValue(WeaponPriceTrie, g_WeaponNames[i], g_WeaponPrice[i]);
			SetTrieValue(WeaponSlotTrie, g_WeaponNames[i], g_WeaponSlot[i]);
			SetTrieValue(WeaponTeamTrie, g_WeaponNames[i], g_WeaponTeam[i]);
		}
	}
	
	LoadConVars();
}
LoadConVars()
{
	vesthelmct 		= CreateConVar("sm_restrict_vesthelm_ct", "-1", "Restrict/Unrestrict -1 unrestricts vesthelm for ct");
	vesthelmt 		= CreateConVar("sm_restrict_vesthelm_t", "-1", "Restrict/Unrestrict -1 unrestricts vesthelm for t");
	vestct 			= CreateConVar("sm_restrict_vest_ct", "-1", "Restrict/Unrestrict -1 unrestricts vest for ct");
	vestt 			= CreateConVar("sm_restrict_vest_t", "-1", "Restrict/Unrestrict -1 unrestricts vest for t");
	nvgsct 			= CreateConVar("sm_restrict_nvgs_ct", "-1", "Restrict/Unrestrict -1 unrestricts nvgs for ct");
	nvgst 			= CreateConVar("sm_restrict_nvgs_t", "-1", "Restrict/Unrestrict -1 unrestricts nvgs for t");
	flashbangct 	= CreateConVar("sm_restrict_flashbang_ct", "-1", "Restrict/Unrestrict -1 unrestricts flashbang for ct");
	flashbangt 		= CreateConVar("sm_restrict_flashbang_t", "-1", "Restrict/Unrestrict -1 unrestricts flashbang for t");
	hegrenadect 	= CreateConVar("sm_restrict_hegrenade_ct", "-1", "Restrict/Unrestrict -1 unrestricts hegrenade for ct");
	hegrenadet 		= CreateConVar("sm_restrict_hegrenade_t", "-1", "Restrict/Unrestrict -1 unrestricts hegrenade for ct");
	smokegrenadect 	= CreateConVar("sm_restrict_smokegrenade_ct", "-1", "Restrict/Unrestrict -1 unrestricts smokegrenade for ct");
	smokegrenadet 	= CreateConVar("sm_restrict_smokegrenade_t", "-1", "Restrict/Unrestrict -1 unrestricts smokegrenade for t");
	galilct 		= CreateConVar("sm_restrict_galil_ct", "-1", "Restrict/Unrestrict -1 unrestricts galil for ct");
	galilt 			= CreateConVar("sm_restrict_galil_t", "-1", "Restrict/Unrestrict -1 unrestricts galil for t");
	ak47ct 			= CreateConVar("sm_restrict_ak47_ct", "-1", "Restrict/Unrestrict -1 unrestricts ak47 for ct");
	ak47t 			= CreateConVar("sm_restrict_ak47_t", "-1", "Restrict/Unrestrict -1 unrestricts ak47 for t");
	scoutct 		= CreateConVar("sm_restrict_scout_ct", "-1", "Restrict/Unrestrict -1 unrestricts scout for ct");
	scoutt 			= CreateConVar("sm_restrict_scout_t", "-1", "Restrict/Unrestrict -1 unrestricts scout for t");
	sg552ct 		= CreateConVar("sm_restrict_sg552_ct", "-1", "Restrict/Unrestrict -1 unrestricts sg552 for ct");
	sg552t 			= CreateConVar("sm_restrict_sg552_t", "-1", "Restrict/Unrestrict -1 unrestricts sg552 for t");
	awpct 			= CreateConVar("sm_restrict_awp_ct", "-1", "Restrict/Unrestrict -1 unrestricts awp for ct");
	awpt 			= CreateConVar("sm_restrict_awp_t", "-1", "Restrict/Unrestrict -1 unrestricts awp for t");
	g3sg1ct 		= CreateConVar("sm_restrict_g3sg1_ct", "-1", "Restrict/Unrestrict -1 unrestricts g3sg1 for ct");
	g3sg1t 			= CreateConVar("sm_restrict_g3sg1_t", "-1", "Restrict/Unrestrict -1 unrestricts g3sg1 for t");
	famasct 		= CreateConVar("sm_restrict_famas_ct", "-1", "Restrict/Unrestrict -1 unrestricts famas for ct");
	famast 			= CreateConVar("sm_restrict_famas_t", "-1", "Restrict/Unrestrict -1 unrestricts famas for t");
	m4a1ct 			= CreateConVar("sm_restrict_m4a1_ct", "-1", "Restrict/Unrestrict -1 unrestricts m4a1 for ct");
	m4a1t 			= CreateConVar("sm_restrict_m4a1_t", "-1", "Restrict/Unrestrict -1 unrestricts m4a1 for t");
	augct 			= CreateConVar("sm_restrict_aug_ct", "-1", "Restrict/Unrestrict -1 unrestricts aug for ct");
	augt 			= CreateConVar("sm_restrict_aug_t", "-1", "Restrict/Unrestrict -1 unrestricts aug for t");
	sg550ct 		= CreateConVar("sm_restrict_sg550_ct", "-1", "Restrict/Unrestrict -1 unrestricts sg550 for ct");
	sg550t 			= CreateConVar("sm_restrict_sg550_t", "-1", "Restrict/Unrestrict -1 unrestricts sg550 for t");
	glockct 		= CreateConVar("sm_restrict_glock_ct", "-1", "Restrict/Unrestrict -1 unrestricts glock for ct");
	glockt 			= CreateConVar("sm_restrict_glock_t", "-1", "Restrict/Unrestrict -1 unrestricts glock for t");
	uspct 			= CreateConVar("sm_restrict_usp_ct", "-1", "Restrict/Unrestrict -1 unrestricts usp for ct");
	uspt 			= CreateConVar("sm_restrict_usp_t", "-1", "Restrict/Unrestrict -1 unrestricts usp for t");
	p228ct 			= CreateConVar("sm_restrict_p228_ct", "-1", "Restrict/Unrestrict -1 unrestricts p228 for ct");
	p228t 			= CreateConVar("sm_restrict_p228_t", "-1", "Restrict/Unrestrict -1 unrestricts p228 for t");
	elitect 		= CreateConVar("sm_restrict_elite_ct", "-1", "Restrict/Unrestrict -1 unrestricts elite for ct");
	elitet 			= CreateConVar("sm_restrict_elite_t", "-1", "Restrict/Unrestrict -1 unrestricts elite for t");
	deaglect 		= CreateConVar("sm_restrict_deagle_ct", "-1", "Restrict/Unrestrict -1 unrestricts deagle for ct");
	deaglet 		= CreateConVar("sm_restrict_deagle_t", "-1", "Restrict/Unrestrict -1 unrestricts deagle for t");
	fivesevenct 	= CreateConVar("sm_restrict_fiveseven_ct", "-1", "Restrict/Unrestrict -1 unrestricts fiveseven for ct");
	fivesevent 		= CreateConVar("sm_restrict_fiveseven_t", "-1", "Restrict/Unrestrict -1 unrestricts fiveseven for t");
	m3ct 			= CreateConVar("sm_restrict_m3_ct", "-1", "Restrict/Unrestrict -1 unrestricts m3 for ct");
	m3t 			= CreateConVar("sm_restrict_m3_t", "-1", "Restrict/Unrestrict -1 unrestricts m3 for t");
	xm1014ct 		= CreateConVar("sm_restrict_xm1014_ct", "-1", "Restrict/Unrestrict -1 unrestricts xm1014 for ct");
	xm1014t 		= CreateConVar("sm_restrict_xm1014_t", "-1", "Restrict/Unrestrict -1 unrestricts xm1014 for t");
	scoutct 		= CreateConVar("sm_restrict_scout_ct", "-1", "Restrict/Unrestrict -1 unrestricts scout for ct");
	scoutt 			= CreateConVar("sm_restrict_scout_t", "-1", "Restrict/Unrestrict -1 unrestricts scout for t");
	mac10ct 		= CreateConVar("sm_restrict_mac10_ct", "-1", "Restrict/Unrestrict -1 unrestricts mac10 for ct");
	mac10t 			= CreateConVar("sm_restrict_mac10_t", "-1", "Restrict/Unrestrict -1 unrestricts mac10 for t");
	tmpct 			= CreateConVar("sm_restrict_tmp_ct", "-1", "Restrict/Unrestrict -1 unrestricts tmp for ct");
	tmpt 			= CreateConVar("sm_restrict_tmp_t", "-1", "Restrict/Unrestrict -1 unrestricts tmp for t");
	mp5navyct 		= CreateConVar("sm_restrict_mp5navy_ct", "-1", "Restrict/Unrestrict -1 unrestricts mp5navy for ct");
	mp5navyt 		= CreateConVar("sm_restrict_mp5navy_t", "-1", "Restrict/Unrestrict -1 unrestricts mp5navy for t");
	ump45ct 		= CreateConVar("sm_restrict_ump45_ct", "-1", "Restrict/Unrestrict -1 unrestricts ump45 for ct");
	ump45t 			= CreateConVar("sm_restrict_ump45_t", "-1", "Restrict/Unrestrict -1 unrestricts ump45 for t");
	p90ct 			= CreateConVar("sm_restrict_p90_ct", "-1", "Restrict/Unrestrict -1 unrestricts p90 for ct");
	p90t 			= CreateConVar("sm_restrict_p90_t", "-1", "Restrict/Unrestrict -1 unrestricts p90 for t");
	m249ct 			= CreateConVar("sm_restrict_m249_ct", "-1", "Restrict/Unrestrict -1 unrestricts m249 for ct");
	m249t 			= CreateConVar("sm_restrict_m249_t", "-1", "Restrict/Unrestrict -1 unrestricts m249 for t");
	defuser 		= CreateConVar("sm_restrict_defuser", "-1", "Restrict/Unrestrict -1 unrestricts defuser for ct");
	c4 				= CreateConVar("sm_restrict_c4", "-1", "Restrict/Unrestrict -1 unrestricts c4 for t");
	AllowPickup		= CreateConVar("sm_allow_restricted_pickup", "0", "If set to 1 it will NOT remove restricted weapons on pickup but rather on Round start, if set to 0 it will remove on pickup");
	AdminImmunity 	= CreateConVar("sm_weapon_restrict_immunity", "0", "Enables admin immunity so admins can buy restricted weapons");
	#if defined WARMUP
	WarmUp 			= CreateConVar("sm_warmup_enable", "1", "Enable warmup.");
	WarmupTime		= CreateConVar("sm_warmup_time", "45", "How long in seconds warmup lasts");
	grenadegive		= CreateConVar("sm_warmup_infinite", "1", "Weather or not give infinite grenades if warmup weapon is grenades");
	warmupff		= CreateConVar("sm_warmup_disable_ff", "1", "If 1 disables ff during warmup. If 0 leaves ff enabled");
	WarmupRespawn	= CreateConVar("sm_warmup_respawn", "1", "Respawn players during warmup");
	WarmupRespawnTime = CreateConVar("sm_warmup_respawn_time", "0.5", "Time after death before respawning player");
	ffcvar			= FindConVar("mp_friendlyfire");
	#endif
	#if defined PERPLAYER
	PerPlayerRestrict = CreateConVar("sm_perplayer_restrict", "0", "If enabled will restrict awp per player count");
	HookConVarChange(PerPlayerRestrict, PerPlayerConVarChange);
	#endif
	AutoExecConfig(true, "weapon_restrict");
	
	g_version = CreateConVar("sm_weaponrestrict_version", PLUGIN_VERSION, "Weapon restrict version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookConVars();
}
HookConVars()
{
	HookConVarChange(vestct, Vest_CT);
	HookConVarChange(vesthelmct, VestHelm_CT);
	HookConVarChange(defuser, Defuser);
	HookConVarChange(nvgsct, Nvgs_CT);
	HookConVarChange(flashbangct, FlashBang_CT);
	HookConVarChange(hegrenadect, HEGrenade_CT);
	HookConVarChange(smokegrenadect, SmokeGrenade_CT);
	HookConVarChange(galilct, Galil_CT);
	HookConVarChange(ak47ct, AK47_CT);
	HookConVarChange(scoutct, Scout_CT);
	HookConVarChange(sg552ct, SG552_CT);
	HookConVarChange(awpct, AWP_CT);
	HookConVarChange(g3sg1ct, G3SG1_CT);
	HookConVarChange(famasct, Famas_CT);
	HookConVarChange(m4a1ct, M4A1_CT);
	HookConVarChange(augct, Aug_CT);
	HookConVarChange(sg550ct, SG550_CT);
	HookConVarChange(glockct, Glock_CT);
	HookConVarChange(uspct, USP_CT);
	HookConVarChange(p228ct, P228_CT);
	HookConVarChange(deaglect, Deagle_CT);
	HookConVarChange(elitect, Elite_CT);
	HookConVarChange(fivesevenct, FiveSeven_CT);
	HookConVarChange(m3ct, M3_CT);
	HookConVarChange(xm1014ct, XM1014_CT);
	HookConVarChange(mac10ct, Mac10_CT);
	HookConVarChange(tmpct, Tmp_CT);
	HookConVarChange(mp5navyct, Mp5Navy_CT);
	HookConVarChange(ump45ct, Ump45_CT);
	HookConVarChange(p90ct, P90_CT);
	HookConVarChange(m249ct, M249_CT);
	
	HookConVarChange(vestt, Vest_T);
	HookConVarChange(vesthelmt, VestHelm_T);
	HookConVarChange(c4, Cfour);
	HookConVarChange(nvgst, Nvgs_T);
	HookConVarChange(flashbangt, FlashBang_T);
	HookConVarChange(hegrenadet, HEGrenade_T);
	HookConVarChange(smokegrenadet, SmokeGrenade_T);
	HookConVarChange(galilt, Galil_T);
	HookConVarChange(ak47t, AK47_T);
	HookConVarChange(scoutt, Scout_T);
	HookConVarChange(sg552t, SG552_T);
	HookConVarChange(awpt, AWP_T);
	HookConVarChange(g3sg1t, G3SG1_T);
	HookConVarChange(famast, Famas_T);
	HookConVarChange(m4a1t, M4A1_T);
	HookConVarChange(augt, Aug_T);
	HookConVarChange(sg550t, SG550_T);
	HookConVarChange(glockt, Glock_T);
	HookConVarChange(uspt, USP_T);
	HookConVarChange(p228t, P228_T);
	HookConVarChange(deaglet, Deagle_T);
	HookConVarChange(elitet, Elite_T);
	HookConVarChange(fivesevent, FiveSeven_T);
	HookConVarChange(m3t, M3_T);
	HookConVarChange(xm1014t, XM1014_T);
	HookConVarChange(mac10t, Mac10_T);
	HookConVarChange(tmpt, Tmp_T);
	HookConVarChange(mp5navyt, Mp5Navy_T);
	HookConVarChange(ump45t, Ump45_T);
	HookConVarChange(p90t, P90_T);
	HookConVarChange(m249t, M249_T);
}

UnHookConVars()
{
	UnhookConVarChange(vestct, Vest_CT);
	UnhookConVarChange(vesthelmct, VestHelm_CT);
	UnhookConVarChange(defuser, Defuser);
	UnhookConVarChange(nvgsct, Nvgs_CT);
	UnhookConVarChange(flashbangct, FlashBang_CT);
	UnhookConVarChange(hegrenadect, HEGrenade_CT);
	UnhookConVarChange(smokegrenadect, SmokeGrenade_CT);
	UnhookConVarChange(galilct, Galil_CT);
	UnhookConVarChange(ak47ct, AK47_CT);
	UnhookConVarChange(scoutct, Scout_CT);
	UnhookConVarChange(sg552ct, SG552_CT);
	UnhookConVarChange(awpct, AWP_CT);
	UnhookConVarChange(g3sg1ct, G3SG1_CT);
	UnhookConVarChange(famasct, Famas_CT);
	UnhookConVarChange(m4a1ct, M4A1_CT);
	UnhookConVarChange(augct, Aug_CT);
	UnhookConVarChange(sg550ct, SG550_CT);
	UnhookConVarChange(glockct, Glock_CT);
	UnhookConVarChange(uspct, USP_CT);
	UnhookConVarChange(p228ct, P228_CT);
	UnhookConVarChange(deaglect, Deagle_CT);
	UnhookConVarChange(elitect, Elite_CT);
	UnhookConVarChange(fivesevenct, FiveSeven_CT);
	UnhookConVarChange(m3ct, M3_CT);
	UnhookConVarChange(xm1014ct, XM1014_CT);
	UnhookConVarChange(mac10ct, Mac10_CT);
	UnhookConVarChange(tmpct, Tmp_CT);
	UnhookConVarChange(mp5navyct, Mp5Navy_CT);
	UnhookConVarChange(ump45ct, Ump45_CT);
	UnhookConVarChange(p90ct, P90_CT);
	UnhookConVarChange(m249ct, M249_CT);
	
	UnhookConVarChange(vestt, Vest_T);
	UnhookConVarChange(vesthelmt, VestHelm_T);
	UnhookConVarChange(c4, Cfour);
	UnhookConVarChange(nvgst, Nvgs_T);
	UnhookConVarChange(flashbangt, FlashBang_T);
	UnhookConVarChange(hegrenadet, HEGrenade_T);
	UnhookConVarChange(smokegrenadet, SmokeGrenade_T);
	UnhookConVarChange(galilt, Galil_T);
	UnhookConVarChange(ak47t, AK47_T);
	UnhookConVarChange(scoutt, Scout_T);
	UnhookConVarChange(sg552t, SG552_T);
	UnhookConVarChange(awpt, AWP_T);
	UnhookConVarChange(g3sg1t, G3SG1_T);
	UnhookConVarChange(famast, Famas_T);
	UnhookConVarChange(m4a1t, M4A1_T);
	UnhookConVarChange(augt, Aug_T);
	UnhookConVarChange(sg550t, SG550_T);
	UnhookConVarChange(glockt, Glock_T);
	UnhookConVarChange(uspt, USP_T);
	UnhookConVarChange(p228t, P228_T);
	UnhookConVarChange(deaglet, Deagle_T);
	UnhookConVarChange(elitet, Elite_T);
	UnhookConVarChange(fivesevent, FiveSeven_T);
	UnhookConVarChange(m3t, M3_T);
	UnhookConVarChange(xm1014t, XM1014_T);
	UnhookConVarChange(mac10t, Mac10_T);
	UnhookConVarChange(tmpt, Tmp_T);
	UnhookConVarChange(mp5navyt, Mp5Navy_T);
	UnhookConVarChange(ump45t, Ump45_T);
	UnhookConVarChange(p90t, P90_T);
	UnhookConVarChange(m249t, M249_T);
}

ResetConVars()
{
	UnHookConVars();
	
	ResetConVar(vestct);
	ResetConVar(vesthelmct);
	ResetConVar(defuser);
	ResetConVar(nvgsct);
	ResetConVar(flashbangct);
	ResetConVar(hegrenadect);
	ResetConVar(smokegrenadect);
	ResetConVar(galilct);
	ResetConVar(ak47ct);
	ResetConVar(scoutct);
	ResetConVar(sg552ct);
	ResetConVar(awpct);
	ResetConVar(g3sg1ct);
	ResetConVar(famasct);
	ResetConVar(m4a1ct);
	ResetConVar(augct);
	ResetConVar(sg550ct);
	ResetConVar(glockct);
	ResetConVar(uspct);
	ResetConVar(p228ct);
	ResetConVar(deaglect);
	ResetConVar(elitect);
	ResetConVar(fivesevenct);
	ResetConVar(m3ct);
	ResetConVar(xm1014ct);
	ResetConVar(mac10ct);
	ResetConVar(tmpct);
	ResetConVar(mp5navyct);
	ResetConVar(ump45ct);
	ResetConVar(p90ct);
	ResetConVar(m249ct);
	
	ResetConVar(vestt);
	ResetConVar(vesthelmt);
	ResetConVar(c4);
	ResetConVar(nvgst);
	ResetConVar(flashbangt);
	ResetConVar(hegrenadet);
	ResetConVar(smokegrenadet);
	ResetConVar(galilt);
	ResetConVar(ak47t);
	ResetConVar(scoutt);
	ResetConVar(sg552t);
	ResetConVar(awpt);
	ResetConVar(g3sg1t);
	ResetConVar(famast);
	ResetConVar(m4a1t);
	ResetConVar(augt);
	ResetConVar(sg550t);
	ResetConVar(glockt);
	ResetConVar(uspt);
	ResetConVar(p228t);
	ResetConVar(deaglet);
	ResetConVar(elitet);
	ResetConVar(fivesevent);
	ResetConVar(m3t);
	ResetConVar(xm1014t);
	ResetConVar(mac10t);
	ResetConVar(tmpt);
	ResetConVar(mp5navyt);
	ResetConVar(ump45t);
	ResetConVar(p90t);
	ResetConVar(m249t);
	
	HookConVars();
}

public Vest_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("vest", f_Value, 3, oldVal, cvar);
	
}

public VestHelm_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("vesthelm", f_Value, 3, oldVal, cvar);
}

public Defuser(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("defuser", f_Value, 3, oldVal, cvar);
}

public Nvgs_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("nvgs", f_Value, 3, oldVal, cvar);
}

public FlashBang_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("flashbang", f_Value, 3, oldVal, cvar);
}

public HEGrenade_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("hegrenade", f_Value, 3, oldVal, cvar);
}

public SmokeGrenade_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("smokegrenade", f_Value, 3, oldVal, cvar);
}

public Galil_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("galil", f_Value, 3, oldVal, cvar);
}

public AK47_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("ak47", f_Value, 3, oldVal, cvar);
}

public Scout_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("scout", f_Value, 3, oldVal, cvar);
}

public SG552_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("sg552", f_Value, 3, oldVal, cvar);
}

public AWP_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("awp", f_Value, 3, oldVal, cvar);
}

public G3SG1_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("g3sg1", f_Value, 3, oldVal, cvar);
}

public Famas_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("famas", f_Value, 3, oldVal, cvar);
}

public M4A1_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("m4a1", f_Value, 3, oldVal, cvar);
}

public Aug_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("aug", f_Value, 3, oldVal, cvar);
}

public SG550_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("sg550", f_Value, 3, oldVal, cvar);
}

public Glock_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("glock", f_Value, 3, oldVal, cvar);
}

public USP_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("usp", f_Value, 3, oldVal, cvar);
}

public P228_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("p228", f_Value, 3, oldVal, cvar);
}

public Deagle_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("deagle", f_Value, 3, oldVal, cvar);
}

public Elite_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("elite", f_Value, 3, oldVal, cvar);
}

public FiveSeven_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("fiveseven", f_Value, 3, oldVal, cvar);
}

public M3_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("m3", f_Value, 3, oldVal, cvar);
}

public XM1014_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("xm1014", f_Value, 3, oldVal, cvar);
}

public Mac10_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("mac10", f_Value, 3, oldVal, cvar);
}

public Tmp_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("tmp", f_Value, 3, oldVal, cvar);
}

public Mp5Navy_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("mp5navy", f_Value, 3, oldVal, cvar);
}

public Ump45_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("ump45", f_Value, 3, oldVal, cvar);
}

public P90_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("p90", f_Value, 3, oldVal, cvar);
}

public M249_CT(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("m249", f_Value, 3, oldVal, cvar);
}
//////////////
//////////////
////////////// Begin t
//////////////
//////////////
public Vest_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("vest", f_Value, 2, oldVal, cvar);
}

public VestHelm_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("vesthelm", f_Value, 2, oldVal, cvar);
}

public Cfour(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("c4", f_Value, 2, oldVal, cvar);
}

public Nvgs_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("nvgs", f_Value, 2, oldVal, cvar);
}

public FlashBang_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("flashbang", f_Value, 2, oldVal, cvar);
}

public HEGrenade_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("hegrenade", f_Value, 2, oldVal, cvar);
}

public SmokeGrenade_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("smokegrenade", f_Value, 2, oldVal, cvar);
}

public Galil_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("galil", f_Value, 2, oldVal, cvar);
}

public AK47_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("ak47", f_Value, 2, oldVal, cvar);
}

public Scout_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("scout", f_Value, 2, oldVal, cvar);
}

public SG552_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("sg552", f_Value, 2, oldVal, cvar);
}

public AWP_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("awp", f_Value, 2, oldVal, cvar);
}

public G3SG1_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("g3sg1", f_Value, 2, oldVal, cvar);
}

public Famas_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("famas", f_Value, 2, oldVal, cvar);
}

public M4A1_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("m4a1", f_Value, 2, oldVal, cvar);
}

public Aug_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("aug", f_Value, 2, oldVal, cvar);
}

public SG550_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("sg550", f_Value, 2, oldVal, cvar);
}

public Glock_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("glock", f_Value, 2, oldVal, cvar);
}

public USP_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("usp", f_Value, 2, oldVal, cvar);
}

public P228_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("p228", f_Value, 2, oldVal, cvar);
}

public Deagle_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("deagle", f_Value, 2, oldVal, cvar);
}

public Elite_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("elite", f_Value, 2, oldVal, cvar);
}

public FiveSeven_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("fiveseven", f_Value, 2, oldVal, cvar);
}

public M3_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("m3", f_Value, 2, oldVal, cvar);
}

public XM1014_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("xm1014", f_Value, 2, oldVal, cvar);
}

public Mac10_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("mac10", f_Value, 2, oldVal, cvar);
}

public Tmp_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("tmp", f_Value, 2, oldVal, cvar);
}

public Mp5Navy_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("mp5navy", f_Value, 2, oldVal, cvar);
}

public Ump45_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("ump45", f_Value, 2, oldVal, cvar);
}

public P90_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("p90", f_Value, 2, oldVal, cvar);
}

public M249_T(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:f_Value[10];
	GetConVarString(cvar, f_Value, sizeof(f_Value));
	
	HandleWeaponCvar("m249", f_Value, 2, oldVal, cvar);
}
//////////////
//////////////
////////////// Handle Cvar Changes
//////////////
//////////////
HandleWeaponCvar(String:weapon[100], String:value[], teamnum, const String:oldVal[], Handle:cvar)
{
	new ammount = StringToInt(value);
	new override;
	decl valuect;
	decl valuet;
	if(ammount < -1 || (!IsNum(value) && !StrEqual(value, "-1", false)))
	{
		PrintToServer("Invalid ammount");
		SetConVarString(cvar, oldVal);
		return;
	}
	if(GetTrieValue(AdminOverride, weapon, override) && (override == teamnum || override == 0))
	{
		PrintToServer("Adminoverride in place for %s", weapon);
		return;
	}
	if(GetTrieValue(WeaponTrieCT, weapon, valuect) && (teamnum == CT_TEAM || teamnum == 0))
	{
		SetTrieValue(WeaponTrieCT, weapon, ammount);
		SetConVarString(cvar, value);
	}
	if(GetTrieValue(WeaponTrieT, weapon, valuet) && (teamnum == T_TEAM || teamnum == 0))
	{
		SetTrieValue(WeaponTrieT, weapon, ammount);
		SetConVarString(cvar, value);
	}
}
IsNum(String:value[])
{
	for(new i = 0; i < strlen(value); i++)
		if(!IsCharNumeric(value[i]))
			return false;
	return true;
}