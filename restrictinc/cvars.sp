ConVar hAllowPickup = null;
ConVar hAWPAllowPickup = null;
ConVar hAdminImmunity = null;
ConVar hRestrictSound = null;

#if defined WARMUP
ConVar hWarmupEnabled = null;
ConVar hWarmupTime = null;
ConVar hInfiniteGrenade = null;
ConVar hFriendlyFire = null;
ConVar hWarmupFriendlyFire = null;
ConVar hWarmupRespawnTime = null;
ConVar hWarmupRespawn = null;
#endif

#if defined PERPLAYER
ConVar hPerPlayerRestrict = null;
ConVar hPerPlayerBots = null;
ConVar hPerPlayerSpecs = null;
#endif

//Convar Handles
enum
{
	CVarTeam_CT = 0,
	CVarTeam_T = 1,
	CVarTeam_MAX
}

ConVar hRestrictCVars[CSWeapon_MAX_WEAPONS][CVarTeam_MAX];
ConVar hVersion = null;

ConVar hMaxMoney = null;
ConVar hHeAmmo = null;
ConVar hFlashAmmo = null;
ConVar hSmokeAmmo = null;

ArrayList hWeaponNameList;//This contains all weapon names for easy looping.

void CreateConVars()
{
	static bool bCVarsCreated = false;
	
	if(!bCVarsCreated)
	{
		hWeaponNameList = new ArrayList(WEAPONARRAYSIZE);
		
		char cvar[128];
		char desc[256];
	
		for(int i = 1; i < view_as<int>(CSWeapon_MAX_WEAPONS); i++)
		{
			if(!CSWeapons_IsValidID(view_as<CSWeaponID>(i), true))
			{
				hRestrictCVars[i][CVarTeam_CT] = null;
				hRestrictCVars[i][CVarTeam_T] = null;
				continue;
			}
			
			char szName[80];
			CSWeapons_GetAlias(view_as<CSWeaponID>(i), szName, sizeof(szName), true);
			
			hWeaponNameList.PushString(szName);
			
			Format(cvar, sizeof(cvar), "sm_restrict_%s_t", szName);
			Format(desc, sizeof(desc), "-1 = unrestricted, 0 = restricted, positive numbers = number allowed for Terrorists . Weapon:%s", szName);
			hRestrictCVars[i][CVarTeam_T] = CreateConVar(cvar, "-1", desc);
			
			Format(cvar, sizeof(cvar), "sm_restrict_%s_ct", szName);
			Format(desc, sizeof(desc), "-1 = unrestricted, 0 = restricted, positive numbers = number allowed for Counter-Terrorists. Weapon:%s", szName);
			hRestrictCVars[i][CVarTeam_CT] = CreateConVar(cvar, "-1", desc);
		}
	
		hAllowPickup		= CreateConVar("sm_allow_restricted_pickup", "0", "Set to 0 to ONLY allow pickup if under the max allowed. Set to 1 to allow restricted weapon pickup");
		hAWPAllowPickup		= CreateConVar("sm_allow_awp_pickup", "1", "Set to 0 to allow awp pickup ONLY if it is under the max allowed. Set to 1 to use sm_allow_restricted_pickup method.");
		hAdminImmunity 		= CreateConVar("sm_weapon_restrict_immunity", "0", "Enables admin immunity so admins can buy restricted weapons");
		
		hRestrictSound		= CreateConVar("sm_restricted_sound", "sound/buttons/weapon_cant_buy.wav", "Sound to play when a weapon is restricted (leave blank to disable)");
			
		hMaxMoney	 		= FindConVar("mp_maxmoney");
		
		if(g_iEngineVersion == Engine_CSS)
		{
			hHeAmmo			= FindConVar("ammo_hegrenade_max");
			hFlashAmmo		= FindConVar("ammo_flashbang_max");
			hSmokeAmmo		= FindConVar("ammo_smokegrenade_max");
		}
		else
		{
			hFlashAmmo 		= FindConVar("ammo_grenade_limit_flashbang");
		}
		
		#if defined WARMUP
		hWarmupEnabled 		= CreateConVar("sm_warmup_enable", "1", "Enable warmup.");
		hWarmupTime			= CreateConVar("sm_warmup_time", "45", "How long in seconds warmup lasts");
		hInfiniteGrenade	= CreateConVar("sm_warmup_infinite", "1", "Weather or not give infinite grenades if warmup weapon is grenades");
		hWarmupFriendlyFire	= CreateConVar("sm_warmup_disable_ff", "1", "If 1 disables ff during warmup. If 0 leaves ff enabled");
		hWarmupRespawn		= CreateConVar("sm_warmup_respawn", "1", "Respawn players during warmup");
		hWarmupRespawnTime 	= CreateConVar("sm_warmup_respawn_time", "0.5", "Time after death before respawning player");
		hFriendlyFire		= FindConVar("mp_friendlyfire");
		#endif
		
		#if defined PERPLAYER
		hPerPlayerRestrict	= CreateConVar("sm_perplayer_restrict", "0", "If enabled will restrict awp per player count");
		hPerPlayerBots	 	= CreateConVar("sm_perplayer_bots", "1", "If enabled will count bots in per player restricts");
		hPerPlayerSpecs	  	= CreateConVar("sm_perplayer_specs", "1", "If enabled will count specs in per player restricts");
		
		RegServerCmd("sm_perplayer_debug", Perplayer_Debug, "Command used to debug per player stuff");
		
		hPerPlayerRestrict.AddChangeHook(PerPlayerConVarChange);
		hPerPlayerBots.AddChangeHook(PerPlayerConVarChange);
		hPerPlayerSpecs.AddChangeHook(PerPlayerConVarChange);
		#endif

		hVersion = CreateConVar("sm_weaponrestrict_version", PLUGIN_VERSION, "Weapon restrict version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		
		bCVarsCreated = true;
	}
	AutoExecConfig(true, "weapon_restrict");
}

#if defined PERPLAYER
public void PerPlayerConVarChange(ConVar convar, const char [] oldValue, const char [] newValue)
{
	CheckPerPlayer();
}
#endif