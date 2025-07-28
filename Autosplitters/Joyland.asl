state("JoyLandPrototype-Win64-Shipping")
{
    int Paused: 0x4C08154;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Joyland";  
    vars.Helper.AlertLoadless();

    dynamic[,] _settings =
    {
        { "Area", true, "Splitting Areas", null },
            { "LobbyMap", true, "Split When Entering Joyland", "Area" },
            { "2ndMAP", true, "Split When Entering The TV Question Area", "Area" },
            { "3rdMAP", true, "Split When Entering The Elevator", "Area" },
            { "4thMAP", true, "Split After Finishing The First Set Of Puzzles", "Area" },
            { "ShadowMAP", true, "Split After Grabbing The 4 Fuses", "Area" },
            { "5thMAP", true, "Split After Finishing The Shadow Section", "Area" },
            { "6thMAP", true, "Split After Finishing The Giant Puzzle", "Area" },
            { "7thMAP", true, "Split After Finishing The Chase Scene", "Area" },
    };
    vars.Helper.Settings.Create(_settings);
}

init
{
    IntPtr gWorld = vars.Helper.ScanRel(10, "80 7C 24 ?? 00 ?? ?? 48 8B 3D ???????? 48");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
    IntPtr fNames = vars.Helper.ScanRel(13, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15");
    IntPtr gSyncLoad = vars.Helper.ScanRel(21, "33 C0 0F 57 C0 F2 0F 11 05");

	if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero || fNames == IntPtr.Zero)
	{
		const string Msg = "Not all required addresses could be found by scanning.";
		throw new Exception(Msg);
	}

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);

    vars.Helper["Loading"] = vars.Helper.Make<bool>(gSyncLoad);

	vars.FNameToString = (Func<ulong, string>)(fName =>
	{
		var nameIdx = (fName & 0x000000000000FFFF) >> 0x00;
		var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
		var number = (fName & 0xFFFFFFFF00000000) >> 0x20;

		IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
		IntPtr entry = chunk + (int)nameIdx * sizeof(short);

		int length = vars.Helper.Read<short>(entry) >> 6;
		string name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + sizeof(short));

		return number == 0 ? name : name + "_" + number;
	});

	current.Area = "";
    vars.CompletedSplits = new HashSet<string>();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None")
        current.Area = world;

    if (old.Area != current.Area)
    {
        vars.Log("Current Area Is " + current.Area);
    }

    string checkName = vars.GetCutsceneName((ulong)(vars.sequencePlayer));
	if (checkName != "") current.Cutscene = checkName;

	if (old.Cutscene != current.Cutscene)
		vars.Log("Cutscene: " + old.Cutscene + " -> " + current.Cutscene);

    if (old.Loading != current.Loading)
        vars.Log("Loading: " + current.Loading);

    if (old.Paused != current.Paused)
        vars.Log("Current Paused Is " + current.Paused);
}

split
{
    if (current.Area != old.Area && settings[current.Area] && !vars.CompletedSplits.Contains(current.Area))
    {
        vars.CompletedSplits.Add(current.Area);
        return true;
    }
}

start
{
    return current.Area == "IntroLevel";
}

onStart
{
    vars.CompletedSplits.Clear();
}

isLoading
{
    return current.Loading || current.Paused == 3|| current.Area == "IntroLevel" || current.Area == "MainMenuMapTEST" || current.Area == "GameOver" ;
}

exit
{
    timer.IsGameTimePaused = true;
}
