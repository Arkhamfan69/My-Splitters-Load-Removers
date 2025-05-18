state("Frest-Win64-Shipping")
{
    bool Loading2: "Frest-Win64-Shipping.exe", 0x8034291;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Frest";
    vars.Helper.AlertLoadless();

    settings.Add("Frest", true, "Frest Auto Splitter Settings");
        settings.Add("1-1", true, "Disable For 100% Speedruns");
        settings.Add("End", true, "Split On Final Cutscene Starting", "Frest");
        settings.SetToolTip("End", "Disable All Other Settings If You Only Have A Split For The Ending");
        settings.Add("Ben", true, "Split When Entering The Benjamin Boss Fight", "Frest");
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
    // GEngine.GameInstance.LocalPlayer[0].AcknowledgedPawn.PauseMenu.bIsActive
    vars.Helper["Paused"] = vars.Helper.Make<bool>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x338, 0x810, 0x368);
    vars.Helper["Paused"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

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

start
{
    return current.Area == "OpeningCutscene";
}

split
{
    if (current.Area == "HubWorld" && old.Area != "HubWorld" && !vars.CompletedSplits.Contains(current.Area))
    {
        vars.CompletedSplits.Add(current.Area);
        return settings["1-1"]; // Done To Split When Entering The Hub World After 1-1
    }

    if (current.Area == "4-Ben" && old.Area != "4-Ben" && !vars.CompletedSplits.Contains(current.Area))
    {
        vars.CompletedSplits.Add(current.Area);
        return settings["Ben"];
    }

    if (current.Area == "1-Hub" && old.Area != "1-Hub")
    {
        return settings["After"];
    }

    if (current.Area == "2-Hub" && old.Area != "2-Hub")
    {
        return settings["After2"];
    }

    if (current.Area == "3-Hub" && old.Area != "3-Hub")
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
    if (current.Paused || current.Area == "OpeningCutscene")
    {
        return true;
    }

    if (
        current.Area == "HubWorld" ||
        current.Area == "CaveLevel1Persistent" ||
        current.Area == "CaveLevel2Persistent" ||
        current.Area == "FrozenBeachLevel1" ||
        current.Area == "FrozenBeachLevel2" || 
        current.Area == "4-Ben"
    )
    {
        return false;
    }

    if (
        (
            current.Area == "CaveLevel1Persistent" ||
            current.Area == "CaveLevel2Persistent" ||
            current.Area == "BossLevelPersistent2" ||
            current.Area == "JungleLevel1Persistent" ||
            current.Area == "JungleLevel2Persistent" ||
            current.Area == "BossLevelPersistent3"
        )
        && current.Loading2 == true
    )
    {
        return true;
    }
    
    return current.Loading2;
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
    if (old.Loading2 != current.Loading2) vars.Log("Current Actutal Loads Is: " + current.Loading2);
}
