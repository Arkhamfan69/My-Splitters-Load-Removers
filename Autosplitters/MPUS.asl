state("valentine-Win64-Shipping")
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
        { "MPUS", true, "Miraclous: Paris Under Siege Auto-Splitter Settings", null},
            {"IL", false, "Start Timer On Any Level", "MPUS"},
                {"Split", true, "Where To Split?", "MPUS"},
                        {"New", true, "Split On Level Stats Popup", "Split"},
                            {"Plaza", false, "Plaza", "New"},
                                {"MAP_INTRO_2", false, "Plaza 2", "Plaza"},
                                {"MAP_INTRO_3", false, "Plaza 3", "Plaza"},
                            {"Garden", false, "Senate Gardens", "New"},
                                {"MAP_W01_L01", false, "Garden 1", "Garden"},
                                {"MAP_W01_L03", false, "Garden 2", "Garden"},
                                {"MAP_W01_L04", false, "Garden 3", "Garden"},
                            {"Hills", false, "Nothern Hills", "New"},
                                {"MAP_W02_L01", false, "Museum 1", "Hills"},
                                {"MAP_W02_L03", false, "Museum 2", "Hills"},
                                {"MAP_W02_L04", false, "Hills 3", "Hills"},
                            {"Cem", false, "Cemetary", "New"},
                                {"MAP_W03_L01", false, "Cem 1", "Cem"},
                                {"MAP_PERELACHAISE_L2", false, "Cemetary 2", "Cem"},
                                {"MAP_PERELACHAISE_L4", false, "Cem 3", "Cem"},
                            {"Train", false, "Train", "New"},
                                {"MAP_W04_L01", false, "Train 1", "Train"},
                                {"MAP_W04_L03", false, "Train 2", "Train"},
                                {"MAP_W04_L04", false, "Train 3", "Train"},
                            {"Obelisk", false, "Obelisk Square", "New"},
                                {"MAP_END_L02", false, "Obelisk 1", "Obelisk"},
                                {"MAP_END_L03", false, "Obelisk 2", "Obelisk"},
    };

    vars.Uhara.Settings.Create(_settings);
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    vars.Resolver.Watch<int>("Loading", vars.Utils.GSync);

    vars.Events.FunctionFlag("LevelComplete", "W_LevelComplete_C", "W_LevelComplete_C", "SequenceEvent__ENTRYPOINTW_LevelComplete");
}

update
{
    vars.Uhara.Update();

	var world = vars.Utils.FNameToString(current.GWorldName);
	if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
	if (old.World != current.World) vars.Uhara.Log("World Change: " + current.World);

    if (old.Loading != current.Loading) vars.Uhara.Log("Loading State Changed: " + current.Loading);
}

isLoading
{
    return current.Loading != 0 ;
}

start
{
    return current.World == "MAP_INTRO_L3_CINEMATIC" && old.World == "MAP_PLACEHOLDER_HOME";

    if (settings["IL"] && current.World != "MAP_PLACEHOLDER_HOME")
    {
        return true;
    }
}

split
{
    if (vars.Resolver.CheckFlag("LevelComplete") && !vars.CompletedSplits.Contains(current.World) && settings.ContainsKey(current.World) && settings[current.World])
    {
        vars.CompletedSplits.Add(current.World);
        return true;
    }

    if (current.World == "MAP_END_L03" && vars.Resolver.CheckFlag("LevelComplete"))
    {
        return true;
    }
}

onStart
{
    vars.CompletedSplits.Clear();
}

exit
{
    timer.IsGameTimePaused = true;
}
