state("SMB-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.AlertLoadless(); 
    vars.CompletedSplits = new List<string>();  

    dynamic[,] _settings =
    {
        { "SMB3D", true, "Super Mario Bros 3D Auto-Splitter Settings", null},
        {"Area", true, "Level Splits", "SMB3D"},
            {"L_W1_L02", true, "Level 2", "Area"},
            {"L_W1_L03", true, "Level 3", "Area"},
            {"L_W1_L04", true, "Level 4", "Area"},
            {"L_W1_L05", true, "Level 5", "Area"},
            {"L_W1_L09", true, "Level 6", "Area"},
            {"L_W1_L14", true, "Level 7", "Area"},
            {"L_W2_L01", true, "Level 8", "Area"},
            {"L_W2_LO3", true, "Level 9", "Area"},
            {"L_W2_L05", true, "Level 10", "Area"}
    };
    vars.Uhara.Settings.Create(_settings);
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    vars.Resolver.Watch<bool>("IsLoading", vars.Utils.GSync);

    vars.Events.FunctionFlag("Start", "PC_MainMenu_C", "PC_MainMenu_C", "BIESwitchToGame");
    vars.Events.FunctionFlag("FinalLevel", "BP_LevelGoal_C","[BP_LevelGoal_C", "CE_StartReplay");


    current.World = "";
}

update
{
	vars.Uhara.Update();


    var world = vars.Utils.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
    if (old.World != current.World) vars.Uhara.Log("World Change: " + current.World);
}

start
{
    return vars.Resolver.CheckFlag("Start");
}

split
{
    if (vars.Resolver.CheckFlag("FinalLevel") && !vars.CompletedSplits.Contains("FinalLevel") && settings["FinalLevel"] && current.World == "L_W2_L05")
    {
        vars.CompletedSplits.Add("FinalLevel");
        return true;
    }

    if (old.World != current.World && !vars.CompletedSplits.Contains(old.World) && settings.ContainsKey(old.World) && settings[old.World])
    {
        vars.CompletedSplits.Add(old.World);
        return true;
    }
}

onReset
{
    vars.CompletedSplits.Clear();
}

isLoading
{
    return current.IsLoading;
}