//Config loader. Loads configs for specific map or prefix.
CheckConfig()
{
	decl String:file[300];
	decl String:map[100];
	decl String:pref[10];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "configs/restrict/%s.cfg", map);
	if(!FileExists(file))// lets try another config the map one dosnt exist.
	{
		SplitString(map, "_", pref, sizeof(pref));
		BuildPath(Path_SM, file, sizeof(file), "configs/restrict/%s_.cfg", pref);
		if(!FileExists(file))//neither exists EXIT!
			return;
	}
	new Handle:FileHandle = OpenFile(file, "r");
	new String:Command[200];
	while(!IsEndOfFile(FileHandle))
	{
		ReadFileLine(FileHandle, Command, sizeof(Command));
		TrimString(Command);
		if(strncmp(Command, "//", 2) != 0)
		{
			ServerCommand("%s", Command);// We can really expand on this but simple is always good..
		}
	}
	CloseHandle(FileHandle);
}