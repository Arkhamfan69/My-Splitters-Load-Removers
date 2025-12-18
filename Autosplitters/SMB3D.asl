state("SMB-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.AlertLoadless(); 
    vars.Uhara.EnableDebug();
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
            {"L_W2_L03", true, "Level 9", "Area"},
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

    vars.Events.FunctionFlag("FinalLevel", "BP_LevelGoal_C", "BP_LevelGoal_C", "AfterOneFrame_5034C4DF43B0FF9AC4A9B39A2E9FE973");

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
    return current.World == "L_W1_L01" && current.IsLoading;
}

split
{
    if (vars.Resolver.CheckFlag("FinalLevel") && !vars.CompletedSplits.Contains("FinalLevel") && settings["FinalLevel"] && current.World == "L_W2_L05")
    {
        vars.CompletedSplits.Add("FinalLevel");
        return true;
    }

    if (old.World != current.World && !vars.CompletedSplits.Contains(current.World) && settings.ContainsKey(current.World) && settings[current.World])
    {
        vars.CompletedSplits.Add(current.World);
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
