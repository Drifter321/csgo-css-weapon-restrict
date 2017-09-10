//Keeps track of weapons created and saves their id for easy look up. Requires SDKHooks.
enum
{
	Tracker_EntityIndex = 0,
	Tracker_WeaponIDIndex,
	Tracker_MAXIndex
};

static ArrayList hWeaponTracker = null;

void CheckWeaponArrays()
{
	if(hWeaponTracker == null)
		hWeaponTracker = new ArrayList(Tracker_MAXIndex);
	else
		hWeaponTracker.Clear();
	
	//Add any items that already are spawned
	int iMaxEntities = GetMaxEntities();
	
	char szWeaponName[WEAPONARRAYSIZE];
	
	int aTracker[Tracker_MAXIndex];
	
	for(int i = MaxClients; i <= iMaxEntities; i++)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, szWeaponName, sizeof(szWeaponName));
			
			CSWeaponID id = CS_AliasToWeaponID(szWeaponName);
			
			if(CSWeapons_IsValidID(id, true) && hWeaponTracker.FindValue(i, Tracker_EntityIndex) == -1)
			{
				aTracker[Tracker_EntityIndex] = i;
				aTracker[Tracker_WeaponIDIndex] = view_as<int>(id);
				
				hWeaponTracker.PushArray(aTracker);
			}
		}
	}
}

public void OnEntityCreated(int entity, const char [] classname)
{
	if(hWeaponTracker == null)
		return;
	
	CSWeaponID id = Restrict_GetWeaponIDExtended(classname);
	
	if(g_iEngineVersion == Engine_CSGO && CSWeapons_IsValidID(id, true) && id != CSWeapon_KNIFE)
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost); //Correct it if possiible
	}
	
	if(CSWeapons_IsValidID(id, true) && hWeaponTracker.FindValue(entity, Tracker_EntityIndex) == -1)
	{
		int aTracker[Tracker_MAXIndex];
		aTracker[Tracker_EntityIndex] = entity;
		aTracker[Tracker_WeaponIDIndex] = view_as<int>(id);
		
		hWeaponTracker.PushArray(aTracker);
	}
}

public void SpawnPost(int entity)
{
	int iItemDefIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	
	if(iItemDefIndex == 0)
		return;
	
	CSWeaponID id = CS_ItemDefIndexToID(iItemDefIndex); // Get the real one.
	
	int index = hWeaponTracker.FindValue(entity, Tracker_EntityIndex);
	
	if(CSWeapons_IsValidID(id, true) &&  index != -1)
	{
		hWeaponTracker.Set(index, id, Tracker_WeaponIDIndex);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(hWeaponTracker == null)
		return;
	
	int index = hWeaponTracker.FindValue(entity, Tracker_EntityIndex);
	
	if(index != -1)
		hWeaponTracker.Erase(index);
}

CSWeaponID GetWeaponIDFromEnt(int entity)
{
	if(!IsValidEdict(entity))
		return CSWeapon_NONE;
	
	int index = hWeaponTracker.FindValue(entity, Tracker_EntityIndex);
	
	if(index != -1)
	{
		return hWeaponTracker.Get(index, Tracker_WeaponIDIndex);
	}
	
	return CSWeapon_NONE;
}
