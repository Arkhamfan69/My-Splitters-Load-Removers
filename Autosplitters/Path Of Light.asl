state("PathToLight-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Path Of Light";

    settings.Add("staff", false, "Split On Staff Obtained");
    settings.Add("keys", false, "Split On Keys Obtained");
}

init
{
    IntPtr gWorld = vars.Helper.ScanRel(10, "80 7C 24 ?? 00 ?? ?? 48 8B 3D ???????? 48");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
    IntPtr fNames = vars.Helper.ScanRel(7, "8B D9 74 ?? 48 8D 15 ?? ?? ?? ?? EB");

    if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero || fNames == IntPtr.Zero)
    {
        const string Msg = "Not all required addresses could be found by scanning.";
        throw new Exception(Msg);
    }

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
    // GEngine.TransitionType
    vars.Helper["Paused"] = vars.Helper.Make<bool>(gEngine, 0xBBB);
    // GEngine.GameInstace.LocalPlayer[0].PlayerController.AcknowledgedPawn.HasStaff
    vars.Helper["HasStaff"] = vars.Helper.Make<bool>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x338, 0x89D);
    // GEngine.GameInstace.LocalPlayer[0].PlayerController.AcknowledgedPawn.KeysObtained
    vars.Helper["KeysObtained"] = vars.Helper.Make<int>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x338, 0x84C);
    // Gengine.GameInstance.LocalPlayer[0].PlayerController.AcknowledgedPawn.IsJournalOpened
    vars.Helper["IsJournalOpened"] = vars.Helper.Make<bool>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x338, 0xAE6);

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

    vars.CompletedSplits = new HashSet<string>();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    // Uncomment debug information in the event of an update.
	// print(modules.First().ModuleMemorySize.ToString());

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.Area = world;
    if (old.Area != current.Area) vars.Log("Area: " + current.Area);

    if (old.Paused != current.Paused) vars.Log("Current Paused Is " + current.Paused);
    if (old.HasStaff != current.HasStaff) vars.Log("Has Staff: " + current.HasStaff);
    if (old.KeysObtained != current.KeysObtained) vars.Log("Keys Obtained: " + current.KeysObtained);
    if (old.IsJournalOpened != current.IsJournalOpened) vars.Log("Is Journal Opened: " + current.IsJournalOpened);
}

start
{
    return current.Area == "WB_Cavern" && old.Area == "Main_Menu_PT";
}

split
{
    if (settings["staff"] && old.HasStaff != current.HasStaff && current.HasStaff)
    {
        vars.Log("Staff Obtained!");
        return true;
    }

    if (settings["keys"] && old.KeysObtained != current.KeysObtained && current.KeysObtained > 0)
    {
        vars.Log("Keys Obtained: " + current.KeysObtained);
        return true;
    }

    if (old.Area != current.Area)
    {
        return true;
    }
}

isLoading
{
    return current.Paused || current.IsJournalOpened;
}

exit
{
    timer.IsGameTimePaused = true;
}

reset
{
    return current.Area == "Main_Menu_PT";
}
