state("PAPAO-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Papao: Legend of the Boogeyman";
    vars.Helper.Settings.CreateFromXml("Components/Papao_Settings.xml");
}

init
{
    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 8B 0D ???????? 66 0F 5A C9 E8");
    IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 05 ???????? eb ?? 48 8d 0d ???????? e8 ???????? c6 05");
    IntPtr gSyncLoadCount = vars.Helper.ScanRel(5, "89 43 60 8B 05 ?? ?? ?? ??");

    if (gWorld == IntPtr.Zero)
    {
        const string Msg = "GWorld Not Found.";
        throw new Exception(Msg);
    }

    if (gEngine == IntPtr.Zero)
    {
        const string Msg = "gEngine Not Found.";
        throw new Exception(Msg);
    }

    if (fNames == IntPtr.Zero)
    {
        const string Msg = "fNames Not Found.";
        throw new Exception(Msg);
    }

    if (gSyncLoadCount == IntPtr.Zero)
    {
        const string Msg = "gSyncLoadCount Not Found.";
        throw new Exception(Msg);
    }

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
    vars.Helper["Loading"] = vars.Helper.Make<bool>(gSyncLoadCount);
    // GEngine.TransitionType
    vars.Helper["TransitionType"] = vars.Helper.Make<bool>(gEngine, 0x8A8);
    // GEngine.GameInstance.LocalPlayer[0].PlayerController.MyHUD.CurrentScreen
    vars.Helper["CurrentScreen"] = vars.Helper.Make<byte>(gEngine, 0xD28, 0x38, 0x0, 0x30, 0x2B0, 0x320);
    // GEngine.GameInstance.LocalPlayer[0].PlayerController.Character.CapsuleComponent.RelativeLocation
    vars.Helper["CapsulePosition"] = vars.Helper.Make<Vector3f>(gEngine, 0xD28, 0x38, 0x0, 0x30, 0x260, 0x290, 0x11C);
    // Inventory Stuff
    vars.Helper["InventoryItems"]   = vars.Helper.Make<IntPtr>(gWorld, 0x120, 0x280, 0x38);
    vars.Helper["InventoryItemsCount"] = vars.Helper.Make<int>(gWorld, 0x120, 0x280, 0x40);

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

    vars.FNameToShortString = (Func<ulong, string>)(fName =>
    {
        string name = vars.FNameToString(fName);

        int dot = name.LastIndexOf('.');
        int slash = name.LastIndexOf('/');

        return name.Substring(Math.Max(dot, slash) + 1);
    });

    vars.FNameToShortString2 = (Func<ulong, string>)(fName =>
    {
        string name = vars.FNameToString(fName);

        int under = name.LastIndexOf('_');

        return name.Substring(0, under + 1);
    });

    vars.FNameToShortString3 = (Func<ulong, string>)(fName =>
    {
        string name = vars.FNameToString(fName);

        int check = name.IndexOf('.');

        return name.Substring(check + 1);
    });

    current.World = "";
    vars.ChapterPauseActive = false;
    vars.ChapterPauseStart = 0;
    vars.Chapters = new HashSet<string> { "Level2", "Level33", "Level44", "Level55" };
    vars.ChapterJustChanged = false;
    vars.LastInventoryItems = new List<string>();
    vars.SplitInventoryItems = new HashSet<string>();
    vars.SpoolsCollected = new HashSet<string>();
    vars.SpoolsSplitDone = false;
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None")
        current.World = world;
    if (old.World != current.World) vars.Log("Current Map Is: " + current.World);

    if (old.Loading != current.Loading) vars.Log("Loading: " + current.Loading);

    if (old.TransitionType != current.TransitionType) vars.Log("TransitionType: " + current.TransitionType);

    if (old.CurrentScreen != current.CurrentScreen) vars.Log("Current Screen: " + current.CurrentScreen);

    if (vars.Chapters.Contains(current.World) && old.World != current.World)
    {
        vars.ChapterJustChanged = true;
    }

    if (vars.ChapterJustChanged && current.CurrentScreen == 3 && !vars.ChapterPauseActive)
    {
        vars.ChapterPauseActive = true;
        vars.ChapterPauseStart = DateTime.Now.Ticks;
        vars.ChapterJustChanged = false;
        vars.Log("Chapter pause started for " + current.World);
    }

    if (vars.ChapterPauseActive)
    {
        long elapsedTicks = DateTime.Now.Ticks - vars.ChapterPauseStart;
        double elapsedSeconds = elapsedTicks / 10000000.0;
        if (elapsedSeconds > 7)
        {
            vars.ChapterPauseActive = false;
            vars.Log("Chapter pause ended for " + current.World);
        }
    }

    var currentItems = new List<string>();
    for (int i = 0; i < vars.Helper["InventoryItemsCount"].Current; i++)
    {
        string itemName = vars.Helper.ReadString(128, ReadStringType.UTF16, vars.Helper["InventoryItems"].Current + (i * 0x8), 0x38, 0x28, 0x0);
        currentItems.Add(itemName);
    }

    // Only track inventory additions when not loading
    if (!current.Loading)
    {
        foreach (var item in currentItems)
        {
            if (!vars.LastInventoryItems.Contains(item))
            {
                vars.Log("Inventory Item Added: " + item);
                if (item.Contains("spool of thread"))
                {
                    vars.SpoolsCollected.Add(item);
                }
            }
        }
    }

    foreach (var item in vars.LastInventoryItems)
    {
        if (!currentItems.Contains(item))
        {
            vars.Log("Inventory Item Removed: " + item);
        }
    }

    vars.LastInventoryItems = currentItems;
}

exit
{
    timer.IsGameTimePaused = true;
}

isLoading
{
    if (vars.ChapterPauseActive)
    {
        return true;
    }

    if (current.World == "Level55" && current.CurrentScreen == 3)
    {
        return false;
    }
    else if (current.World != "Level55" && current.CurrentScreen == 3)
    {
        return true;
    }

    return current.TransitionType || current.Loading || current.World == "MainMenu";
}

start
{
    if (current.World == "Level1" && current.CapsulePosition.X != old.CapsulePosition.X)
    {
        return true;
    }

    
}

split
{
    foreach (var item in vars.LastInventoryItems)
    {
        if (settings.ContainsKey(item) && settings[item] && !item.Contains("spool of thread"))
        {
            if (!vars.SplitInventoryItems.Contains(item))
            {
                vars.SplitInventoryItems.Add(item);
                return true;
            }
        }
    }

    if (settings.ContainsKey("Empty spool of thread") && settings["Empty spool of thread"])
    {
        if (vars.SpoolsCollected.Count >= 4 && !vars.SpoolsSplitDone)
        {
            vars.SpoolsSplitDone = true;
            return true;
        }
    }
}

reset
{
    if (settings["Reset"] && current.World == "MainMenu")
    {
        return true;
    }
}
