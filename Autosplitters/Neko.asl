state("NekoGhostJump-Win64-Shipping") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Neko Ghost, Jump!"; 
    vars.Helper.AlertLoadless();

    dynamic[,] _settings =
	{
	  { "Levels", true, "Splitting Settings", null },
		{ "Tutorial_L2", false, "Split When Entering 1-2", "Levels" },
		{ "Tutorial_L3", false, "Split When Entering 1-3", "Levels" },
		{ "Tutorial_L4", false, "Split When Entering 1-4", "Levels" },
		{ "Tutorial_L5", false, "Split When Entering 1-5", "Levels" },
		{ "Desert_L1", true, "Split When Entering 2-1", "Levels" },
		{ "Desert_L2", false, "Split When Entering 2-2", "Levels" },
	    	{ "Desert_L3", false, "Split When Entering 2-3", "Levels" },
	    	{ "Desert_L4", false, "Split When Entering 2-4", "Levels" },
	    	{ "Desert_L5", false, "Split When Entering 2-5", "Levels" },                        
	    	{ "Jungle_L1", true, "Split When Entering 3-1", "Levels" },
            	{ "Jungle_L2", false, "Split When Entering 3-2", "Levels" },
            	{ "Jungle_L3", false, "Split When Entering 3-3", "Levels" },
            	{ "Jungle_L4", false, "Split When Entering 3-4", "Levels" },
           	{ "Jungle_L5", false, "Split When Entering 3-5", "Levels" },
            	{ "Ice_L1", true, "Split When Entering 4-1", "Levels" },
            	{ "Ice_L2", false, "Split When Entering 4-2", "Levels" },
            	{ "Ice_L3", false, "Split When Entering 4-3", "Levels" },
            	{ "Ice_L4", false, "Split When Entering 4-4", "Levels" },
            	{ "Ice_L5", false, "Split When Entering 4-5", "Levels" },
            	{ "Hell_L1", true, "Split When Entering 5-1", "Levels" },
            	{ "Hell_L2", false, "Split When Entering 5-2", "Levels" }, 
            	{ "Hell_L3", false, "Split When Entering 5-3", "Levels" },
            	{ "Hell_L4", false, "Split When Entering 5-4", "Levels" },
            	{ "Hell_L5", false, "Split When Entering 5-5", "Levels" },
            	{ "Heaven_L1", true, "Split When Entering 6-1", "Levels" },
            	{ "Heaven_L2", false, "Split When Entering 6-2", "Levels" },
            	{ "Heaven_L3", false, "Split When Entering 6-3", "Levels" },
            	{ "Heaven_L4", false, "Split When Entering 6-4", "Levels" },
            	{ "Heaven_L5", true, "Split When Entering 6-5", "Levels" },
            	{ "Space_L1", true, "Split When Entering 7-1", "Levels" },
            	{ "Space_L2", false, "Split When Entering 7-2", "Levels" },
            	{ "Space_L3", false, "Split When Entering 7-3", "Levels" },
            	{ "Space_L4", false, "Split When Entering 7-4", "Levels" },
            	{ "Space_L5", true, "Split When Entering 7-5", "Levels" },
            	{ "PirateShip_L1", true, "Split When Entering 8-1", "Levels" },
            	{ "PirateShip_L2", false, "Split When Entering 8-2", "Levels" },
            	{ "PirateShip_L3", false, "Split When Entering 8-3", "Levels" },
            	{ "PirateShip_L4", false, "Split When Entering 8-4", "Levels" },
            	{ "PirateShip_L5", false, "Split When Entering 8-5", "Levels" },
		{ "FarmBattle", false, "Split When Starting The Farm Battle Minigame (FOR 100%)", "Levels"},
    };
	vars.Helper.Settings.Create(_settings);
    vars.CompletedSplits = new HashSet<string>();
}

init
{
    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 05 ???????? 48 3B C? 48 0F 44 C? 48 89 05 ???????? E8");
	IntPtr gEngine = vars.Helper.ScanRel(3, "48 39 35 ?? ?? ?? ?? 0F 85 ?? ?? ?? ?? 48 8B 0D");
	IntPtr fNames = vars.Helper.ScanRel(13, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15");

    if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero || fNames == IntPtr.Zero)
    {
        const string Msg = "Not all required addresses could be found by scanning.";
        throw new Exception(Msg);
    }

    vars.Helper["GWorld"] = vars.Helper.Make<ulong>(gWorld, 0x18);

    // vars.Helper["Loads"] = vars.Helper.Make<bool>();

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

    current.Map = "";
    vars.CompletedSplits = new HashSet<string>();
}

start
{
    return current.Map == "Intro_Main";
}

onStart
{
    vars.CompletedSplits.Clear();
}

reset
{
    return current.Map == "MainMenu"; // This is there for the people who have the reset tab ticked
}

split
{
    if (current.Map != old.Map && settings[current.Map] && !vars.CompletedSplits.Contains(current.Map))
    {
        vars.CompletedSplits.Add(current.Map);
        return true;
    };
}

isLoading
{
    return current.Map == "Intro_Main" || current.Map == "Village" || current.Map == "Home" || current.Map == "Farm" || current.Map == "Bank" || current.Map == "Shop" || current.Map == "TutorialLevelSelect" || current.Map == "HeavenLevelSelect" || current.Map == "WorldBiomeSelect" || current.Map == "SpaceLevelSelect" || current.Map == "PirateShipLevelSelect" || current.Map == "HellLevelSelect" || current.Map == "IceLevelSelect" || current.Map == "JungleLevelSelect" || current.Map == "DesertLevelSelect" || current.Map == "MainMenu";
}

exit
{
    timer.IsGameTimePaused = true;
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorld);
    if (!string.IsNullOrEmpty(world) && world != "None") current.Map = world;
    if (old.Map != current.Map) vars.Log("Current Map Is: " + current.Map);
    // if (old.Loads != current.Loads) vars.Log("Current Loads: " + current.Loads);
}
