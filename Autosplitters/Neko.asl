state("NekoGhostJump-Win64-Shipping") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Neko Ghost, Jump!"; 
    vars.Helper.AlertLoadless();
    vars.Helper.Settings.CreateFromXml("Components/NekoSettings.xml");
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
