state("FNAF_SOTM-Win64-Shipping") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Five Nights At Freddy's: Secret of The Mimic";
    vars.Helper.AlertLoadless();
    vars.ZoneCooldown = new Stopwatch();

    dynamic[,] _settings =
    {
        { "split", true, "Splitting", null },
            { "MAP_Outro_InteractiveCredits_Infinite", true, "Final Split - Works on all 3 Endings", "split" },
        { "text", false, "Display Game Info On A Text Component", null },
            { "Remove", false, "Remove Text Component On Exit", "text" },
            {"Seen", false, "Show If The Player Is Seen By Ai", "text"},
        { "loads", true, "Load Removal", null },
            { "pause", true, "Pause when on the Loads", "loads" },
    };

    vars.Helper.Settings.Create(_settings);
    vars.CompletedSplits = new HashSet<string>();
    vars.lcCache = new Dictionary<string, LiveSplit.UI.Components.ILayoutComponent>();

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) =>
    {
        var currentValue = currentLookup.ContainsKey(key) ? (currentLookup[key] ?? "(null)") : null;
        var oldValue = oldLookup.ContainsKey(key) ? (oldLookup[key] ?? "(null)") : null;

        if (oldValue != null && currentValue != null && !oldValue.Equals(currentValue)) {
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
        }

        if (oldValue == null && currentValue != null) {
            vars.Log(key + ": " + currentValue);
        }
    });

    vars.SetText = (Action<string, object>)((text1, text2) =>
    {
        const string FileName = "LiveSplit.Text.dll";
        LiveSplit.UI.Components.ILayoutComponent lc;

        if (!vars.lcCache.TryGetValue(text1, out lc))
        {
            lc = timer.Layout.LayoutComponents.Reverse().Cast<dynamic>()
                .FirstOrDefault(llc => llc.Path.EndsWith(FileName) && llc.Component.Settings.Text1 == text1)
                ?? LiveSplit.UI.Components.ComponentManager.LoadLayoutComponent(FileName, timer);

            vars.lcCache.Add(text1, lc);
        }

        if (!timer.Layout.LayoutComponents.Contains(lc))
            timer.Layout.LayoutComponents.Add(lc);

        dynamic tc = lc.Component;
        tc.Settings.Text1 = text1;
        tc.Settings.Text2 = text2.ToString();
    });

    vars.RemoveText = (Action<string>)(text1 =>
    {
        LiveSplit.UI.Components.ILayoutComponent lc;

        if (vars.lcCache.TryGetValue(text1, out lc))
        {
            timer.Layout.LayoutComponents.Remove(lc);
            vars.lcCache.Remove(text1);
        }
    });

    vars.RemoveAllTexts = (Action)(() =>
    {
        foreach (var lc in vars.lcCache.Values)
            timer.Layout.LayoutComponents.Remove(lc);
        vars.lcCache.Clear();
    });

    vars.InZone = (Func<Vector3f, float, float, float, float, bool>)((pos, minX, maxX, minY, maxY) =>
    {
        return pos.X >= minX && pos.X <= maxX
            && pos.Y >= minY && pos.Y <= maxY;
    });
}

init
{
    IntPtr namePoolData = vars.Helper.ScanRel(13, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15");
    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 8B 0D ???????? 66 0F 5A C9 E8");

    if (namePoolData == IntPtr.Zero || gWorld == IntPtr.Zero || gEngine == IntPtr.Zero)
    {
        throw new InvalidOperationException("Not all signatures resolved.");
    }

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->Character->CapsuleComponent->RelativeLocation
    vars.Helper["PlayerPosition"] = vars.Helper.Make<Vector3f>(gEngine, 0xD28, 0x38, 0x0, 0x30, 0x260, 0x290, 0x11C);

    // GEngine->TransitionType
    vars.Helper["TransitionType"] = vars.Helper.Make<byte>(gEngine, 0x8A8);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn->ShowingReticle
    vars.Helper["ShowingReticle"] = vars.Helper.Make<bool>(gEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x69A);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn->HasInteractionStarted
    vars.Helper["HasInterctionStarted"] = vars.Helper.Make<bool>(gEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x6C8);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn->IsSeenByAi
    vars.Helper["IsSeen"] = vars.Helper.Make<bool>(gEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x60C);

    // NamePool stuff
    const int FNameBlockOffsetBits = 16;
    const uint FNameBlockOffsetMask = ushort.MaxValue; // (1 << FNameBlockOffsetBits) - 1

    const int FNameIndexBits = 32;
    const uint FNameIndexMask = uint.MaxValue; // (1 << FNameIndexBits) - 1

    var nameCache = new Dictionary<int, string> { { 0, "None" } };

    vars.FNameToString = (Func<ulong, string>)(fName =>
    {
        var number          = (int)(fName >> FNameIndexBits);
        var comparisonIndex = (int)(fName &  FNameIndexMask);

        string name;
        if (!nameCache.TryGetValue(comparisonIndex, out name))
        {
            var blockIndex = (ushort)(comparisonIndex >> FNameBlockOffsetBits);
            var offset     = (ushort)(comparisonIndex &  FNameBlockOffsetMask);

            var block = vars.Helper.Read<IntPtr>(namePoolData + 0x10 + blockIndex * 0x8);
            var entry = block + 2 * offset;

            var length = vars.Helper.Read<short>(entry) >> 6;
            name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + 2);

            nameCache.Add(comparisonIndex, name);
        }

        return number == 0 ? name : name + "_" + (number - 1);
    });

    vars.FNameToShortString = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int dot = name.LastIndexOf('.');
		int slash = name.LastIndexOf('/');

		return name.Substring(Math.Max(dot, slash) + 1);
	});

    vars.FindSubsystem = (Func<string, IntPtr>)(name =>
    {
        var subsystems = vars.Helper.Read<int>(gEngine, 0xD28, 0xF8);
        for (int i = 0; i < subsystems; i++)
        {
            var subsystem = vars.Helper.Deref(gEngine, 0xD28, 0xF0, 0x18 * i + 0x8);
            var sysName = vars.FNameToString(vars.Helper.Read<ulong>(subsystem, 0x18));

            if (sysName.StartsWith(name))
            {
                return subsystem;
            }
        }

        throw new InvalidOperationException("Subsystem not found: " + name);
    });

    vars.SetTextIfEnabled = (Action<string, object>)((text1, text2) =>
    {
        if (settings[text1])            
            vars.SetText(text1, text2); 
        else
            vars.RemoveText(text1);     
    });

    vars.GameManager = IntPtr.Zero;
}

update
{
    IntPtr gm;
    if (!vars.Helper.TryRead<IntPtr>(out gm, vars.GameManager))
    {
        vars.GameManager = vars.FindSubsystem("CarnivalGameManager");

        // UCarnivalGameManager->LoadingScreenManager->0x48
        vars.Helper["LoadingState"] = vars.Helper.Make<int>(vars.GameManager, 0x168, 0x48);
    }

    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None")
        current.World = world;
    
    if (old.LoadingState != current.LoadingState)
    {
        vars.Log("LoadingState: " + old.LoadingState + " -> " + current.LoadingState);
    }

    if (old.ShowingReticle != current.ShowingReticle)
    {
        vars.Log("ShowingReticle: " + old.ShowingReticle + " -> " + current.ShowingReticle);
    }

    if (old.HasInterctionStarted != current.HasInterctionStarted)
    {
        vars.Log("Interaction: " + current.HasInterctionStarted);
    }

    vars.Watch(old, current, "IsSeen");

    vars.SetTextIfEnabled("Seen", current.IsSeen);
}

exit
{
    timer.IsGameTimePaused = true;
    if (settings["Remove"])
    vars.RemoveAllTexts();
}

start
{
    return old.PlayerPosition.X != current.PlayerPosition.X && current.World == "MAP_TheWorld" && current.ShowingReticle;
}

onStart
{
    vars.CompletedSplits.Clear();
}

split
{
    return old.World != current.World && settings[current.World] && vars.CompletedSplits.Add(current.World);
}

isLoading
{
    bool inZone = current.HasInterctionStarted && (
        vars.InZone(current.PlayerPosition, 808.2f, 963.6f, -6729.9f, -6506.3f) || // Big Top Sub Area
        vars.InZone(current.PlayerPosition, -122.9f, 96.9f, -8051.8f, -7937.2f) || // Workshop
        vars.InZone(current.PlayerPosition, -2113.2f, -1894.7f, -8627.8f, -8515.8f) || // Big Top Rooftop
        vars.InZone(current.PlayerPosition, 10155.4f, 10345.4f, 9833.1f, 9896.7f) || // Big Top Chase
        vars.InZone(current.PlayerPosition, 2709.1f, 2816.0f, -6460.7f, -6353.4f) || // Warehouse
        vars.InZone(current.PlayerPosition, 1375.9f, 1595.7f, -8029.6f, -7906.0f) || // Other Warehouse
        vars.InZone(current.PlayerPosition, -2469.4f, -2354.9f, -5944.3f, -5880.5f) || // Nurse Dollie
        vars.InZone(current.PlayerPosition, 324.5f, 380.6f, -5149.7f, -4903.6f) || // Theater
        vars.InZone(current.PlayerPosition, -412.9f, -199.3f, -6491.9f, -6430.1f) || // Theater Sub Area
        vars.InZone(current.PlayerPosition, -1055.8f, -809.4f, -6482.5f, -6408.3f) || // Other Theater Sub
        vars.InZone(current.PlayerPosition, 6659.7f, 6833.7f, -6055.5f, -5957.0f) || // Above Welcome Show
        vars.InZone(current.PlayerPosition, 5744.7f, 5946.8f, -6357.7f, -6210.7f) || // Showroom
        vars.InZone(current.PlayerPosition, 1239.9f, 1472.4f, -12152.9f, -12005.2f) || // Admin Wing
        vars.InZone(current.PlayerPosition, 8239.7f, 8307.2f, -5626.2f, -5370.3f) || // R&D Floor
        vars.InZone(current.PlayerPosition, 6650.0f, 6866.0f, -6021.0f, -5915.0f) || // Welcome Show Stage
        vars.InZone(current.PlayerPosition, 6594.047f, 6672.446f, -3835.06f, -3585.102f) // Retail Showroom
    );

    if (inZone && !vars.ZoneCooldown.IsRunning)
    {
        vars.ZoneCooldown.Restart();
    }

    if (!inZone && vars.ZoneCooldown.IsRunning)
    {
        vars.ZoneCooldown.Reset();
    }

    return current.LoadingState == 1
        || current.World == "MAP_MainMenu"
        || current.World == "MAP_Outro_InteractiveCredits_Infinite"
        || (settings["pause"] && current.TransitionType == 1)
        || (vars.ZoneCooldown.IsRunning && vars.ZoneCooldown.Elapsed.TotalSeconds >= 2.50);
}

// Workshop 
// PlayerPositionY: -122.8391 -8051.774 80.53419 PlayerPositionX: -122.8718 -8051.774 80.5342
// PlayerPositionX: -114.4379 -7937.171 77.33859 PlayerPositionY: -114.4379 -7937.171 77.33859
// PlayerPositionY: 86.71659 -7948.221 80.50621 PlayerPositionX: 86.71659 -7948.221 80.50621
// PlayerPositionY: 96.8587 -8051.775 80.53416 PlayerPositionX: 96.8587 -8051.775 80.53416

// Loading Into Big Top Rooftop
// PlayerPositionY: -2113.246 -8627.005 1846.443 PlayerPositionX: -2113.21 -8627.005 1846.443
// PlayerPositionX: -2102.691 -8529.669 1818.119 PlayerPositionY: -2102.691 -8529.669 1818.119
// PlayerPositionX: -1894.738 -8627.802 1818.085 PlayerPositionY: -1894.738 -8627.802 1818.085
// PlayerPositionX: -1909.313 -8515.754 1818.248 PlayerPositionY: -1909.313 -8515.754 1818.248

// Loading Into Big Top Chase
// PlayerPositionX: 10184.59 9838.099 2881.802 PlayerPositionY: 10184.59 9838.099 2881.802
// PlayerPositionX: 10155.49 9896.688 2881.802 PlayerPositionY: 10155.49 9896.688 2881.802
// PlayerPositionX: 10345.44 9833.178 2881.802 PlayerPositionY: 10345.44 9833.178 2881.802
// PlayerPositionY: 10320.83 9896.693 2924.85 PlayerPositionX: 10320.85 9896.693 2924.85

// Warehouse
// PlayerPositionX: 2808.8 -6460.664 77.83086 PlayerPositionY: 2808.837 -6460.216 77.83086
// PlayerPositionX: 2816.053 -6353.413 138.9375 PlayerPositionY: 2816.053 -6353.413 138.9375
// PlayerPositionX: 2709.158 -6459.862 77.83086 PlayerPositionY: 2709.158 -6459.862 77.83086
// PlayerPositionX: 2712.338 -6362.602 77.74259 PlayerPositionY: 2712.338 -6362.602 77.74259

// Other Warehouse Entrance
// PlayerPositionX: 1375.939 -8029.553 77.8307 PlayerPositionY: 1375.939 -8029.553 77.8307
// PlayerPositionX: 1595.695 -8031.342 77.83066 PlayerPositionY: 1595.695 -8031.342 77.83066
// PlayerPositionX: 1591.386 -7906.238 74.89925 PlayerPositionY: 1591.386 -7906.238 74.89925
// PlayerPositionX: 1387.087 -7906.022 74.89925 PlayerPositionY: 1387.087 -7906.022 74.89925

// Nurse Dollie Load
// PlayerPositionX: -2355.913 -5880.728 -647.4041 PlayerPositionY: -2355.883 -5880.728 -647.3757
// PlayerPositionX: -2354.887 -5944.302 -673.2116 PlayerPositionY: -2354.887 -5944.302 -673.2116
// PlayerPositionX: -2469.382 -5880.478 -646.7298 PlayerPositionY: -2469.382 -5880.478 -646.7298
// PlayerPositionX: -2468.239 -5936.79 -650.9088 PlayerPositionY: -2468.239 -5936.79 -650.9088

// Theater
// PlayerPositionX: 324.6134 -4903.65 81.50179 PlayerPositionY: 324.6134 -4903.65 81.50179
// PlayerPositionX: 324.5158 -5149.71 77.60801 PlayerPositionY: 324.5158 -5149.716 77.608
// PlayerPositionX: 380.5608 -5140.909 77.60803 PlayerPositionY: 380.5608 -5140.909 77.60803
// PlayerPositionX: 380.4023 -4916.263 77.60804 PlayerPositionY: 380.4023 -4916.263 77.60804

// Theater Sub Area
// PlayerPositionX: -199.3789 -6430.163 82.00066 PlayerPositionY: -199.3789 -6430.163 82.00066
// PlayerPositionX: -199.516 -6487.696 82.00066 PlayerPositionY: -199.516 -6487.696 82.00066
// PlayerPositionX: -199.5101 -6491.907 82.00066 PlayerPositionY: -199.5101 -6491.907 82.00066
// PlayerPositionX: -412.995 -6483.074 82.00063 PlayerPositionY: -412.995 -6483.074 82.00063

// Other Theater Sub Area
// PlayerPositionX: -809.4258 -6408.316 77.60139 PlayerPositionY: -809.4258 -6408.316 77.60139
// PlayerPositionX: -1055.818 -6408.453 81.84852 PlayerPositionY: -1055.818 -6408.453 81.84852
// PlayerPositionX: -1055.356 -6482.503 77.6014 PlayerPositionY: -1055.356 -6482.503 77.6014
// PlayerPositionX: -824.7519 -6468.951 77.60138 PlayerPositionY: -824.7519 -6468.951 77.60138

// Above Welcome Show 
// PlayerPositionX: 6660.171 -6055.467 1127.904 PlayerPositionY 6660.171 -6055.467 1127.904
// PlayerPositionX: 6659.755 -5957.012 1127.904 PlayerPositionY: 6659.755 -5957.012 1127.904
// PlayerPositionX: 6833.708 -5955.366 1128.054 PlayerPositionY: 6833.708 -5955.366 1128.054
// PlayerPositionX: 6830.909 -6055.467 1127.904 PlayerPositionY: 6830.909 -6055.467 1127.904

// Showroom
// PlayerPositionX: 5744.704 -6357.729 1122.831 PlayerPositionY: 5744.704 -6357.729 1122.831
// PlayerPositionX: 5751.899 -6210.7 1119.639 PlayerPositionY: 5751.899 -6210.7 1119.639
// PlayerPositionX: 5944.828 -6231.351 1121.481 PlayerPositionY: 5944.828 -6231.351 1121.481
// PlayerPositionX: 5946.829 -6357.682 1122.831 PlayerPositionY: 5946.829 -6357.682 1122.831

// Admin Wing
// PlayerPositionX: 1245.849 -12152.87 77.82666 PlayerPositionY: 1245.849 -12152.87 77.82666
// PlayerPositionX: 1239.987 -12005.21 76.22102 PlayerPositionY: 1239.987 -12005.21 76.22102
// PlayerPositionX: 1467.802 -12016.37 76.22102 PlayerPositionY: 1467.802 -12016.37 76.22102
// PlayerPositionX: 1472.368 -12152.92 77.8267 PlayerPositionY: 1472.368 -12152.92 77.8267

// R&D Floor
// PlayerPositionX: 8239.716 -5370.393 -4865.359 PlayerPositionY: 8239.716 -5370.393 -4865.359
// PlayerPositionX: 8239.723 -5626.227 -4864.091 PlayerPositionY: 8239.723 -5626.227 -4864.091
// PlayerPositionX: 8304.358 -5615.003 -4866.039 PlayerPositionY: 8304.358 -5615.003 -4866.039
// PlayerPositionX: 8307.193 -5385.494 -4866.039 PlayerPositionY: 8307.193 -5385.494 -4866.039

// Retail Showroom
// PlayerPositionX: 6672.441 PlayerPositionY: -3835.06
// PlayerPositionX: 6594.047 playerPositionY: -3834.238
// PlayerPositionX: 6672.446 PlayerPositionY: -3585.102
// PlayerPositionX: 6596.219 PlayerPositionY: -3597.073
