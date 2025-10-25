state("Ghost-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Titans of the Tide";
    vars.Helper.AlertLoadless();   

    dynamic[,] _settings =
    {
        { "Tott", true, "Titans of the Tide Auto-Splitter Settings", null},
        {"Area", true, "Where To Split?", "Tott"},
            {"BBR_HRA", true, "Bikini Bottom", "Area"},
            {"WP_GoldFishIsland", true, "Goldfish Island", "Area"},
            {"KKHubTest_Map", true, "Krabby Patty Float", "Area"},
    };

    vars.Helper.Settings.Create(_settings);
}


init
{
    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
	IntPtr gEngine = vars.Helper.ScanRel(3, "48 8B 0D ???????? 48 8B 89 ???????? E8");
	IntPtr fNames = vars.Helper.ScanRel(7, "8B D9 74 ?? 48 8D 15 ???????? EB");
	IntPtr gSyncLoad = vars.Helper.ScanRel(21, "33 C0 0F 57 C0 F2 0F 11 05");

	if (gWorld == IntPtr.Zero)
	{
		const string Msg = "GWorld.";
		throw new Exception(Msg);
	}

    if (gEngine == IntPtr.Zero)
	{
		const string Msg = "gEngine.";
		throw new Exception(Msg);
	}

    if (fNames == IntPtr.Zero)
	{
		const string Msg = "fNames.";
		throw new Exception(Msg);
	}

    if (gSyncLoad == IntPtr.Zero)
	{
		const string Msg = "gSyncLoadCount.";
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

	current.World = "";

    vars.FinishedLevels = new HashSet<string>();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None")
        current.World = world;
    if (old.World != current.World) vars.Log("Current Map Is: " + current.World);

    if (old.Loading != current.Loading)
    {
        vars.Log("Loading..." + current.Loading);
    }
}

isLoading
{
    return current.Loading;
}

start
{
    return current.World == "BBR_KrustyKrabRestaurant" && old.World == "P_MainMenu";
}

split
{
    if (current.World != old.World && settings[current.World] && !vars.FinishedLevels.Contains(current.World))
    {
        vars.FinishedLevels.Add(current.World);
        return true;
    }
}

reset
{
    return current.World == "P_MainMenu" && old.World != "P_MainMenu";
}

onReset
{
    vars.FinishedLevels.Clear();
}

// KKHubTest_Map - Krabby Patty Float
// BBR_KrustyKrabResturant - Intro
// BBR_HRA - Bikini Bottom
// WP_GoldFishIsland - Goldfish Island
