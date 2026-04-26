// Created By Arkham & Syrk
// Arkham - Settings Function
// Syrk - Literally Everything Else
state("SMB-Win64-Shipping", "1.5")
{
    float igt : "SMB-Win64-Shipping.exe", 0x0A9993E8, 0x10, 0x104;
}

state("SMB-Win64-Shipping", "1.2")
{
    float igt : "SMB-Win64-Shipping.exe", 0x0A99B3E8, 0x10, 0x104;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.EnableDebug();
    vars.Log = (Action<object>)((output) => print("[Super Meat Boy 3D] " + output));
    vars.CompletedSplits = new List<string>();

    try
    {
        vars.LogPath = System.IO.Path.Combine(
            System.IO.Path.GetDirectoryName(
                System.Reflection.Assembly.GetExecutingAssembly().Location),
                "debug_log.txt"
        );
        System.IO.File.WriteAllText(vars.LogPath, "[SMB3D] Log started\n");
    }
    catch
    {
        vars.LogPath = null;
    }


    var settingsList = new List<object[]>();

    settingsList.Add(new object[] { "SMB3D", true, "Super Meat Boy 3D", null });
    settingsList.Add(new object[] { "LightWorld", true, "Light World", "SMB3D" });

    Action<List<object[]>, string, string, string, bool> AddWorldLevels = (list, worldNum, worldName, parent, isDark) => {
        string prefix = isDark ? "D_" : "L_";
        list.Add(new object[] { worldName, true, worldName.Replace("DW_", "").Replace("World", "World "), parent });
        for (int i = 1; i <= 15; i++) {
            string level = prefix + "W" + worldNum + "_L" + i.ToString("D2");
            list.Add(new object[] { "Start_" + level, false, "[START] Level " + i, worldName });
            bool enabled = i <= 10;
            list.Add(new object[] { level, enabled, "[END] Level " + i, worldName });
        }
        if (!isDark) {
            list.Add(new object[] { "Start_" + prefix + "W" + worldNum + "_Boss", false, "[START] Boss", worldName });
            list.Add(new object[] { prefix + "W" + worldNum + "_Boss", true, "[QUIT] Boss", worldName });
        }
    };

    AddWorldLevels(settingsList, "1", "World1", "LightWorld", false);
    AddWorldLevels(settingsList, "2", "World2", "LightWorld", false);
    AddWorldLevels(settingsList, "3", "World3", "LightWorld", false);
    AddWorldLevels(settingsList, "4", "World4", "LightWorld", false);
    AddWorldLevels(settingsList, "5", "World5", "LightWorld", false);


    settingsList.Add(new object[] { "L_W5_Escape", true, "[END] Escape", "World5" });

    settingsList.Add(new object[] { "DarkWorld", false, "Dark World", "SMB3D" });

    AddWorldLevels(settingsList, "1", "DW_World1", "DarkWorld", true);
    AddWorldLevels(settingsList, "2", "DW_World2", "DarkWorld", true);
    AddWorldLevels(settingsList, "3", "DW_World3", "DarkWorld", true);
    AddWorldLevels(settingsList, "4", "DW_World4", "DarkWorld", true);
    AddWorldLevels(settingsList, "5", "DW_World5", "DarkWorld", true);

    dynamic[,] _settings = new dynamic[settingsList.Count, 4];
    for (int i = 0; i < settingsList.Count; i++) {
        _settings[i, 0] = settingsList[i][0];
        _settings[i, 1] = settingsList[i][1];
        _settings[i, 2] = settingsList[i][2];
        _settings[i, 3] = settingsList[i][3];
    }

    vars.Uhara.Settings.Create(_settings);
}

init
{
    int size = modules.First().ModuleMemorySize;
    vars.Log("[SMB3D] Module size: " + size + " (0x" + size.ToString("X") + ")");

    if (size == 0xB47F000)
    {
        version = "1.2";
    }
    else if (size == 0xB47E000)
    {
        version = "1.5";
    }
    else
    {
        version = "1.2";
        vars.Log("[SMB3D] WARNING: Unknown module size, defaulting version to 1.2");
    }

    vars.Log("[SMB3D] Using version: " + version);

    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    vars.Resolver.Watch<bool>("IsLoading", vars.Utils.GSync);

    vars.IsDarkWorld = false;
    vars.HubTransitionPending = false;
    vars.IgnoreNextHubToggleCycle = true;

    vars.Events.FunctionFlag("FinalLevel", "BP_LevelGoal_C", "BP_LevelGoal_C", "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");
    vars.Events.FunctionFlag("GoalPortal",  "LevelGoal_Portal_C",    "LevelGoal_Portal_C",    "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");
    vars.Events.FunctionFlag("GoalSkeleton","LevelGoal_Skeleton_C",  "LevelGoal_Skeleton_C",  "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");
    vars.Events.FunctionFlag("SecretEntry", "BP_SecretLevelEntry_C", "BP_SecretLevelEntry_C", "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");
    vars.Events.FunctionFlag("EscapeGoal",  "BP_W5_Escape_C",        "BP_W5_Escape_C",        "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");
    vars.Events.FunctionFlag("EscapeGoal2", "BP_EscapeGoal_C",       "BP_EscapeGoal_C",       "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");

    vars.EscapeLoaded = false;
    vars.EscapeStableSinceTicks = 0L;
    vars.EscapeStableMsRequired = 1000;
    vars.BossLoaded = false;
    vars.BossStableSinceTicks = 0L;
    vars.BossStableMsRequired = 1000;
    vars.BossExitPending = false;
    vars.EscapeExitPending = false;
    vars.EscapeExitPendingLoadingSinceTicks = 0L;
    vars.EscapeExitPendingLoadingMsRequired = 50;
    vars.EscapePulseConfirmed = false;
    current.World = "";

    vars.Log("[SMB3D] Game detected");
}

update
{
    vars.Uhara.Update();
    long nowTicks = DateTime.UtcNow.Ticks;

    var world = vars.Utils.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None")
    {
        current.World = world;
    }
    
    if (old.World != current.World)
    {
        vars.Log("World: " + old.World + " -> " + current.World + " (FNameID=" + current.GWorldName + ")");

        if (vars.HubTransitionPending && old.World == "L_WorldMap" && current.World.StartsWith("L_W"))
        {
            vars.HubTransitionPending = false;
        }
    }

    if (current.World == "L_WorldMap" && old.IsLoading == false && current.IsLoading == true)
    {
        vars.HubTransitionPending = true;
    }

    if (vars.HubTransitionPending && current.World == "L_WorldMap" && old.IsLoading == true && current.IsLoading == false)
    {
        if (vars.IgnoreNextHubToggleCycle)
        {
            vars.IgnoreNextHubToggleCycle = false;
            vars.Log("[SMB3D] Hub toggle ignored [startup cycle]");
        }
        else
        {
            vars.IsDarkWorld = !vars.IsDarkWorld;
            vars.Log("[SMB3D] IsDarkWorld=" + vars.IsDarkWorld + " [hub toggle]");
        }

        vars.HubTransitionPending = false;
    }

    if (old.IsLoading != current.IsLoading)
    {
        vars.Log("Loading: " + current.IsLoading + " in " + current.World);
    }

    if (
        vars.BossExitPending
        && old.IsLoading == true
        && current.IsLoading == false
        && old.World == current.World
        && !string.IsNullOrEmpty(current.World)
        && current.World.EndsWith("_Boss"))
    {
        vars.BossExitPending = false;
        vars.Log("[SMB3D] Boss exit disarmed [returned to same boss]");
    }

    if (
        vars.EscapeExitPending
        && old.IsLoading == true
        && current.IsLoading == false
        && old.World == current.World
        && current.World == "L_W5_Escape")
    {
        long loadingTicks = (vars.EscapeExitPendingLoadingSinceTicks == 0L)
            ? 0L
            : nowTicks - vars.EscapeExitPendingLoadingSinceTicks;
        long loadingMs = loadingTicks / TimeSpan.TicksPerMillisecond;

        if (loadingMs < vars.EscapeExitPendingLoadingMsRequired)
        {
            vars.EscapeExitPending = false;
            vars.Log("[SMB3D] Escape exit disarmed [short pulse in Escape]");
        }
        else
        {
            vars.EscapePulseConfirmed = true;
            vars.EscapeExitPending = false;
            vars.Log("[SMB3D] Escape pulse confirmed [ms=" + loadingMs + "]");
        }

        vars.EscapeExitPendingLoadingSinceTicks = 0L;
    }

    if (vars.EscapeExitPending && current.World == "L_W5_Escape" && current.IsLoading)
    {
        if (vars.EscapeExitPendingLoadingSinceTicks == 0L)
        {
            vars.EscapeExitPendingLoadingSinceTicks = nowTicks;
        }
    }

    foreach (string probe in new[] { "FinalLevel", "GoalPortal", "GoalSkeleton", "SecretEntry", "EscapeGoal", "EscapeGoal2" })
    {
        if (vars.Resolver.CheckFlag(probe))
        {
            vars.Log("Probe [" + probe + "] in " + current.World + " loading=" + current.IsLoading);
        }
    }

    if (current.World == "L_W5_Escape")
    {
        if (current.IsLoading == false)
        {
            if (vars.EscapeStableSinceTicks == 0L)
            {
                vars.EscapeStableSinceTicks = nowTicks;
            }

            long stableTicks = nowTicks - vars.EscapeStableSinceTicks;
            long stableMs = stableTicks / TimeSpan.TicksPerMillisecond;

            if (stableMs >= vars.EscapeStableMsRequired)
            {
                vars.EscapeLoaded = true;
            }
        }
    }
    else
    {
        vars.EscapeLoaded = false;
        vars.EscapeStableSinceTicks = 0L;
    }

    if (!string.IsNullOrEmpty(current.World) && current.World.EndsWith("_Boss"))
    {
        if (current.IsLoading == false)
        {
            if (vars.BossStableSinceTicks == 0L)
            {
                vars.BossStableSinceTicks = nowTicks;
            }

            long stableTicks = nowTicks - vars.BossStableSinceTicks;
            long stableMs = stableTicks / TimeSpan.TicksPerMillisecond;

            if (stableMs >= vars.BossStableMsRequired)
            {
                vars.BossLoaded = true;
            }
        }
    }
    else
    {
        vars.BossLoaded = false;
        vars.BossStableSinceTicks = 0L;
    }
}

start
{
    bool entering = old.World != current.World && current.World == "L_WorldMap";

    if (entering)
    {
        vars.CompletedSplits.Clear();
        vars.IsDarkWorld = false;
        vars.HubTransitionPending = false;
        vars.IgnoreNextHubToggleCycle = true;
        vars.BossExitPending = false;
        vars.EscapeExitPending = false;
        vars.EscapeExitPendingLoadingSinceTicks = 0L;
        vars.EscapePulseConfirmed = false;

        vars.Log("=== RUN STARTED ===");
        vars.Log("[SMB3D] IsDarkWorld=False [run start default]");
    }

    return entering;
}

split
{
    string lightKey = current.World;
    string darkKey = (!string.IsNullOrEmpty(current.World) && current.World.StartsWith("L_"))
        ? "D_" + current.World.Substring(2)
        : current.World;

    bool useDarkRealm = settings["DarkWorld"] && vars.IsDarkWorld;
    string splitKey = useDarkRealm ? darkKey : lightKey;
    bool worldGroupEnabled = useDarkRealm ? settings["DarkWorld"] : settings["LightWorld"];

    string startKey = "Start_" + splitKey;
    bool enteringEnabledLevel = old.World != current.World
        && !string.IsNullOrEmpty(current.World)
        && worldGroupEnabled
        && settings.ContainsKey(startKey)
        && settings[startKey];

    if (enteringEnabledLevel)
    {
        vars.Log("Split enter [" + splitKey + "]");

        return true;
    }

    if (
        vars.BossExitPending
        && !string.IsNullOrEmpty(old.World)
        && old.World.EndsWith("_Boss")
        && old.World != current.World
        && !vars.CompletedSplits.Contains(old.World)
        && settings.ContainsKey(old.World)
        && settings[old.World])
    {
        vars.CompletedSplits.Add(old.World);
        vars.BossExitPending = false;
        vars.BossLoaded = false;
        vars.BossStableSinceTicks = 0L;
        vars.Log("Split [" + old.World + "] bossExit=true");

        return true;
    }

    if (!string.IsNullOrEmpty(current.World) && current.World.EndsWith("_Boss"))
    {
        bool bossLoadOut = vars.BossLoaded && old.IsLoading == false && current.IsLoading == true;

        if (
            bossLoadOut
            && !vars.CompletedSplits.Contains(current.World)
            && settings.ContainsKey(current.World)
            && settings[current.World])
        {
            vars.BossExitPending = true;
            vars.Log("[SMB3D] Boss exit armed [" + current.World + "] bossLoadOut=" + bossLoadOut);
        }
    }

    if (
        vars.EscapeExitPending
        && old.World == "L_W5_Escape"
        && old.World != current.World)
    {
        bool escapeEnabled = settings.ContainsKey("L_W5_Escape") && settings["L_W5_Escape"];
        vars.EscapeExitPending = false;
        vars.EscapeExitPendingLoadingSinceTicks = 0L;
        vars.EscapeLoaded = false;
        vars.EscapeStableSinceTicks = 0L;

        if (escapeEnabled && !vars.CompletedSplits.Contains("L_W5_Escape"))
        {
            vars.CompletedSplits.Add("L_W5_Escape");
            vars.Log("Split [L_W5_Escape] escapeExit=true");

            return true;
        }
    }

    if (current.World == "L_W5_Escape")
    {
        bool escapeProbe = vars.Resolver.CheckFlag("EscapeGoal") || vars.Resolver.CheckFlag("EscapeGoal2");
        bool escapeLoadOut = vars.EscapeLoaded && old.IsLoading == false && current.IsLoading == true;
        bool escapePendingLongLoad = vars.EscapeExitPending
            && current.IsLoading
            && vars.EscapeExitPendingLoadingSinceTicks != 0L
            && (DateTime.UtcNow.Ticks - vars.EscapeExitPendingLoadingSinceTicks)
                >= TimeSpan.FromMilliseconds(vars.EscapeExitPendingLoadingMsRequired).Ticks;

        if (
            escapeProbe
            && !vars.CompletedSplits.Contains("L_W5_Escape")
            && settings.ContainsKey("L_W5_Escape")
            && settings["L_W5_Escape"])
        {
            vars.CompletedSplits.Add("L_W5_Escape");
            vars.EscapeExitPending = false;
            vars.EscapeExitPendingLoadingSinceTicks = 0L;
            vars.EscapeLoaded = false;
            vars.EscapeStableSinceTicks = 0L;
            vars.Log("Split [L_W5_Escape] probe=true");

            return true;
        }

        if (
            vars.EscapePulseConfirmed
            && !vars.CompletedSplits.Contains("L_W5_Escape")
            && settings.ContainsKey("L_W5_Escape")
            && settings["L_W5_Escape"])
        {
            vars.CompletedSplits.Add("L_W5_Escape");
            vars.EscapePulseConfirmed = false;
            vars.EscapeExitPending = false;
            vars.EscapeExitPendingLoadingSinceTicks = 0L;
            vars.EscapeLoaded = false;
            vars.EscapeStableSinceTicks = 0L;
            vars.Log("Split [L_W5_Escape] escapePulseConfirmed=true");

            return true;
        }

        if (
            escapeLoadOut
            && !vars.EscapeExitPending
            && !vars.CompletedSplits.Contains("L_W5_Escape")
            && settings.ContainsKey("L_W5_Escape")
            && settings["L_W5_Escape"])
        {
            vars.EscapeExitPending = true;
            vars.EscapeExitPendingLoadingSinceTicks = 0L;
            vars.Log("[SMB3D] Escape exit armed [loadOut=true]");
        }

        if (
            escapePendingLongLoad
            && !vars.CompletedSplits.Contains("L_W5_Escape")
            && settings.ContainsKey("L_W5_Escape")
            && settings["L_W5_Escape"])
        {
            long longLoadMs = (DateTime.UtcNow.Ticks - vars.EscapeExitPendingLoadingSinceTicks) / TimeSpan.TicksPerMillisecond;
            vars.CompletedSplits.Add("L_W5_Escape");
            vars.EscapeExitPending = false;
            vars.EscapeExitPendingLoadingSinceTicks = 0L;
            vars.EscapeLoaded = false;
            vars.EscapeStableSinceTicks = 0L;
            vars.Log("Split [L_W5_Escape] escapePendingLongLoad=true ms=" + longLoadMs);

            return true;
        }

        return false;
    }

    if (
        vars.Resolver.CheckFlag("FinalLevel")
        && worldGroupEnabled
        && !vars.CompletedSplits.Contains(splitKey)
        && settings.ContainsKey(splitKey)
        && settings[splitKey])
    {
        vars.CompletedSplits.Add(splitKey);
        vars.Log("Split [" + splitKey + "]");

        return true;
    }
}

onReset
{
    vars.CompletedSplits.Clear();

    vars.IsDarkWorld = false;
    vars.HubTransitionPending = false;
    vars.IgnoreNextHubToggleCycle = true;
    vars.EscapeLoaded = false;
    vars.EscapeStableSinceTicks = 0L;
    vars.BossLoaded = false;
    vars.BossStableSinceTicks = 0L;
    vars.BossExitPending = false;
    vars.EscapeExitPending = false;
    vars.EscapeExitPendingLoadingSinceTicks = 0L;
    vars.EscapePulseConfirmed = false;

    vars.Log("=== RUN RESET ===");
    vars.Log("[SMB3D] IsDarkWorld=False [manual reset default]");
}

isLoading
{
    return false;
}

gameTime
{
    return TimeSpan.FromSeconds(current.igt);
}
