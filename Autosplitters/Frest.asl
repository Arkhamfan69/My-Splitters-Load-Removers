state("Frest-Win64-Shipping")
{
    bool Paused: "gameoverlayrenderer64.dll", 0x152862;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Frest";
    settings.Add("Frest", true, "Frest Auto Splitter Settings");
        settings.Add("End", false, "Trigger This Setting If You Only Are Splitting On Final Cutscene", "Frest");
        settings.Add("100%", false, "Split After Returning To Hub After Every Challenge", "Frest");
        settings.Add("After", true, "Split After Finishing A Level In World 1", "Frest");
        settings.Add("After2", true, "Split After Finishing A Level In World 2", "Frest");
        settings.Add("After3", true, "Split After Finishing A Level In World 3", "Frest");
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
    if (!string.IsNullOrEmpty(world) && world != "None") current.Area = world;
    if (old.Area != current.Area) vars.Log("Area: " + current.Area);
}


start
{
    return current.Area == "OpeningCutscene";
}

split
{
    if (current.Area == "1-Hub" && old.Area != "1-Hub")
    {
        return settings["After"];
    }

    if (current.Area == "2-Hub" && old.Area != "2-Hub")
    {
        return settings["After2"];
    }

    if (current.Area == "3-Hub" && old.Area == "3-Hub")
    {
        return settings["After3"];
    }

    if (current.Area == "Finale")
    {
        return settings["End"];
    }

    if (current.Area == "HubWorld" && old.Area != "HubWorld")
    {
        return settings["100%"];
    }
}

isLoading
{
    return current.Paused;
}

reset
{
    return current.Area == "MainMenu";
}

onReset
{
    vars.CompletedSplits.Clear();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.Area = world;
    if (old.Area != current.Area) vars.Log("Current Map Is: " + current.Area);
    if (old.Paused != current.Paused) vars.Log("Current Paused Is: " + current.Paused);
}
