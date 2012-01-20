//Config loader. Loads configs for specific map or prefix.
CheckConfig()
{
	decl String:file[300];
	decl String:map[100];
	decl String:pref[10];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "configs/restrict/%s.cfg", map);
	if(!RunFile(file))
	{
		SplitString(map, "_", pref, sizeof(pref));
		BuildPath(Path_SM, file, sizeof(file), "configs/restrict/%s_.cfg", pref);
		RunFile(file);
	}
}