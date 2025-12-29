state("FNAF_SOTM-Win64-Shipping") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
    vars.ZoneCooldown = new Stopwatch();
    vars.ElevatorStopwatch = new Stopwatch();
    vars.CurrentElevatorName = "";
    vars.ElevatorStartedThisTick = false;
    vars.MailboxThisTick = false;
    vars.UpgradeStationPending = 0;  // queued UpgradeStation splits
    vars.UpgradeStationMax = 5;      // allow up to 5 splits per run

    dynamic[,] _settings =
    {
        { "split", true, "Splitting", null },
            { "MAP_Outro_InteractiveCredits_Infinite", true, "Final Split - Works on all 3 Endings", "split" },
            { "UpgradeStation", false, "Upgrade Station Split", "split" },
            { "Mailbox",  false, "Split On Getting A Mailbox", "split" },
        { "text", false, "Display Game Info On A Text Component", null },
            { "Remove", false, "Remove Text Component On Exit", "text" },
            {"Seen", false, "Show If The Player Is Seen By Ai", "text"},
        { "loads", true, "Load Removal", null },
            { "pause", true, "Pause when on the Loads", "loads" },
    };

    vars.Uhara.Settings.Create(_settings);
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

    vars.GetElevatorName = (Func<Vector3f, string>)(pos =>
    {
        if (vars.InZone(pos, -415f, -185f, -10170f, -9890f)) return "Elevator_Jackie";
        if (vars.InZone(pos, 5112.163f, 5358.639f, -7084.621f, -6895.581f)) return "Elevator_BigTop";
        if (vars.InZone(pos, 2151.378f, 2402.004f, -12852.01f, -12638.08f)) return "Elevator_EnteringTigerRock";
        if (vars.InZone(pos, 22372.08f, 22586.03f, -12275.96f, -12025.33f)) return "Elevator_LeavingTigerRock";
        if (vars.InZone(pos, 18866.88f, 19117.49f, -6120.364f, -5906.428f)) return "Elevator_GoingToMoon";
        if (vars.InZone(pos, -6560.449f, -6219.757f, 7219.589f, 7514.636f)) return "Elevator_GoingToManor";
        return "Elevator_Unknown";
    });
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
	vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    // Mailbox Splitting Function
    vars.Events.FunctionFlag("Mailbox", "BP_TerminalLogCollector_C", "BP_TerminalLogCollector3", "OnLogAcquired");
    // Upgrade Station Splitting Function
    vars.Events.FunctionFlag("UpgradeStation", "BP_VNT_DD_UpgradePermStation_C", "BP_VNT_DD_UpgradePermStation", "OnPawnFinishedBlendingOut");

    // Elevator Loads Maybe
    vars.Events.FunctionFlag("ElevatorStarted", "BP_ElevatorDoor_C", "", "DoorCloseStart");
    vars.Events.FunctionFlag("ElevatorEnded", "BP_ElevatorDoor_C", "", "DoorOpenStart");

    // Lift Load Removal
    vars.Events.FunctionFlag("LiftLoadStart", "BP_Springlock_Lift_C", "BP_Springlock_Lift", "Start Enter A");
    vars.Events.FunctionFlag("LiftLoadEnd", "BP_Springlock_Lift_C", "BP_Springlock_Lift", "On FFinished Enter A");
    vars.Events.FunctionFlag("SpringSuitLoad", "BP_Springlock_Lift_C", "BP_Springlock_Lift", "Start Enter B");
    vars.Events.FunctionFlag("SpringSuitLoadEnd", "BP_Springlock_LiftPad_C", "BP_Springlock_LiftPad", "On Finished Exit Sequence");
    // vars.Events.FunctionFlag("PuppetShowLoadStart", )
    // vars.Events.FunctionFlag("PuppetShowLoadEnd", "BP_Springlock_LiftPad_C", "BP_Springlock_LiftPad4", "On Finished Exit Sequence");


    vars.Resolver.Watch<ulong>("GWorldName", vars.Utils.GWorld, 0x18);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->Character->CapsuleComponent->RelativeLocation
    vars.Resolver.Watch<Vector3f>("PlayerPosition", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x260, 0x290, 0x11C);
    
    // GEngine->TransitionType
    vars.Resolver.Watch<byte>("TransitionType", vars.Utils.GEngine, 0x8A8);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn->ShowingReticle
    vars.Resolver.Watch<bool>("ShowingReticle", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x69A);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn->HasInteractionStarted
    vars.Resolver.Watch<bool>("HasInterctionStarted", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x6C8);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn->IsSeenByAi
    vars.Resolver.Watch<bool>("IsSeen", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x60C);

    // GEngine->GameInstance->LocalPlayers[0]->PlayerController->AcknowledgedPawn.Fname
    vars.Resolver.Watch<uint>("Pawn", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x2A0, 0x18);

    vars.FindSubsystem = (Func<string, IntPtr>)(name =>
    {
        var subsystems = vars.Resolver.Read<int>(vars.Utils.GEngine, 0xD28, 0xF8);
        for (int i = 0; i < subsystems; i++)
        {
            var subsystem = vars.Resolver.Deref(vars.Utils.GEngine, 0xD28, 0xF0, 0x18 * i + 0x8);
            var sysName = vars.Utils.FNameToString(vars.Resolver.Read<uint>(subsystem, 0x18));

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
    vars.Jumpscare = "";
    current.World = "";
    vars.ElevatorLoad = false;
}

update
{
    vars.Uhara.Update();
    vars.Helper.Update();

    IntPtr gm;
    if (!vars.Resolver.TryRead<IntPtr>(out gm, vars.GameManager))
    {
        vars.GameManager = vars.FindSubsystem("CarnivalGameManager");
        // UCarnivalGameManager->LoadingScreenManager->0x48
        vars.Resolver.Watch<int>("LoadingState", vars.GameManager, 0x168, 0x48);
    }

    string world = vars.Utils.FNameToString(current.GWorldName);
	if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
	if (old.World != current.World) vars.Uhara.Log("World Change: " + current.World);

    string Jumpscare = vars.Utils.FNameToString(current.Pawn);
    if (!string.IsNullOrEmpty(Jumpscare) && Jumpscare != "None")
        current.Jumpscare = Jumpscare;

    if (vars.Resolver.CheckFlag("ElevatorStarted"))
    {
        if (!vars.ElevatorLoad)
        {
            var elevatorName = vars.GetElevatorName(current.PlayerPosition);
            if (elevatorName != "Elevator_Unknown")
            {
                vars.ElevatorLoad = true;
                vars.ElevatorStopwatch.Restart();
                vars.CurrentElevatorName = elevatorName;
                vars.ElevatorStartedThisTick = true;
                vars.Uhara.Log("Elevator Started: " + vars.CurrentElevatorName);
            }
        }
    }

    if (vars.Resolver.CheckFlag("ElevatorEnded"))
    {
        if (vars.ElevatorLoad)
        {
            vars.ElevatorLoad = false;
            vars.ElevatorStopwatch.Reset();
            vars.Uhara.Log("Elevator Ended: " + vars.CurrentElevatorName);
            vars.CurrentElevatorName = "";
        }
        else
        {
            vars.Uhara.Log("Elevator Ended Happened but vars.ElevatorLoad is already false");
        }
    }
    if (vars.Resolver.CheckFlag("Mailbox"))
    {
        vars.MailboxThisTick = true;
    }

    if (vars.Resolver.CheckFlag("UpgradeStation"))
    {
        if (vars.UpgradeStationPending < vars.UpgradeStationMax)
        {
            vars.UpgradeStationPending++;
        }
    }

    vars.Watch(old, current, "IsSeen");

    vars.SetTextIfEnabled("Seen", current.IsSeen);
}

exit
{
    timer.IsGameTimePaused = true;
    if (settings["Remove"]) vars.RemoveAllTexts();
}

start
{
    return old.PlayerPosition.X != current.PlayerPosition.X && current.World == "MAP_TheWorld" && current.ShowingReticle;
}

onStart
{
    vars.CompletedSplits.Clear();
    vars.UpgradeStationPending = 0;
}

split
{
    if (old.World != current.World && settings[current.World] && vars.CompletedSplits.Add(current.World))
        return true;

    if (vars.ElevatorStartedThisTick)
    {
        vars.ElevatorStartedThisTick = false;
        if (!string.IsNullOrEmpty(vars.CurrentElevatorName) && settings[vars.CurrentElevatorName] && vars.CompletedSplits.Add(vars.CurrentElevatorName))
            return true;
    }

    if (vars.MailboxThisTick)
    {
        vars.MailboxThisTick = false;
        if (settings["Mailbox"])
            return true;
    }

    if (vars.UpgradeStationPending > 0 && settings["UpgradeStation"])
    {
        vars.UpgradeStationPending--;
        return true;
    }
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

    if (vars.ElevatorLoad)
    {
        return true;
    }

    if (current.Jumpscare.Contains("JumpscarePawn"))
    {
        return true;
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

// Elevators

// Jackie Elevator
// PlayerPositionX: -215.5157 PlayerPositionY: -9904.332
// PlayerPositionX: -407.7143 PlayerPositionY: -9904.332
// PlayerPositionX: -407.7509 PlayerPositionY: -10154.96
// PlayerPositionX: -193.813 PlayerPositionY: -10154.95

// Big Top Elevator
// PlayerPositionX: 5112.163 PlayerPositiony: -7081.495
// PlayerPositionX: 5112.164 PlayerPositionY: -6916.096
// PlayerPositionX: 5358.639 PlayerPositionY: -6895.581
// PlayerPositionX: 5358.638 PlayerPositionY: -7084.621

// Entering Tiger Rock
// PlayerPositionX: 2152.682 PlayerPositionY: -12666.67
// PlayerPositionX: 2151.378 PlayerPositionY: -12852.01
// PlayerPositionX: 2402.004 PlayerPositionY: -12852.01
// PlayerPositionX: 2402.001 PlayerPositionY: -12638.08

// Leaving Tiger Rock
// PlayerPositionX: 22398.18 PlayerPositionY: -12275.96
// PlayerPositionX: 22586.03 PlayerPositionY: -12275.83
// PlayerPositionX: 22586.02 PlayerPositionY: -12025.33
// PlayerPositionX: 22372.08 PlayerPositionY: -12025.39

// Going To Moon
// PlayerPositionX: 18866.88 PlayerPositionY: -5933.735
// PlayerPositionX: 18866.88 PlayerPositionY: -6120.364
// PlayerPositionX: 19117.49 PlayerPositionY: -6120.363
// PlayerPositionX: 19117.49 PlayerPositionY: -5906.428

// Going To Manor
// PlayerPositionX: -6235.226 PlayerPositionY: 7514.62
// PlayerPositionX: -6560.448 PlayerPositionY: 7514.636
// PlayerPositionX: -6560.449 PlayerPositionY: 7219.589
// PlayerPositionX: -6219.757 PlayerPositionY: 7219.594
