state("GFD-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
    vars.CompletedSplits = new HashSet<string>();

    settings.Add("main", true, "Settings");
    settings.Add("world1Settings", true, "World 1", "main");
    settings.Add("world2Settings", true, "World 2", "main");
    settings.Add("world3Settings", true, "World 3", "main");

    settings.Add("split_L_Biome1_Level1Abis_Master", true, "Welcome to the farm", "world1Settings");
    settings.Add("split_L_Biome1_Level1B_Master", true, "When The Cats Away", "world1Settings");
    settings.Add("split_L_Biome1_Level2A_Master", true, "Fowl Play in the Carrot Patch", "world1Settings");
    settings.Add("split_L_Biome1_Level2B_Master", true, "High Voltage, Low Motivation", "world1Settings");
    settings.Add("split_L_Biome1_Level3A_Master", true, "Higher and Higher", "world1Settings");
    settings.Add("split_L_Biome1_Level4A_Master", true, "It's Showtime 1", "world1Settings");
    settings.Add("split_L_Biome1_Level4B_Master", true, "It's Showtime 2", "world1Settings");
    settings.Add("split_L_Biome1_Level4C_Master", true, "It's Showtime 3", "world1Settings");
    settings.Add("split_L_Biome1_Level4D_Master", true, "It's Showtime 4", "world1Settings");
    settings.Add("split_L_Biome1_Level5A_Master", true, "Sweet Vengence", "world1Settings");
    settings.Add("split_L_Biome1_Level5B_Master", true, "Nightmare Factory", "world1Settings");
    settings.Add("split_L_Biome1_Level6A_Master", true, "Anything for cheese", "world1Settings");

    settings.Add("split_L_Biome2_Level07A_Master", true, "Surf N Turf", "world2Settings");
    settings.Add("split_L_Biome2_Level07B_Master", true, "Board Them!", "world2Settings");
    settings.Add("split_L_Biome2_Level8A_Master", true, "Hang Eight", "world2Settings");
    settings.Add("split_L_Biome2_Level9A_Master", true, "Sweet Archipelago", "world2Settings");
    settings.Add("split_L_Biome2_Level10B_Master", true, "Surprize Escape", "world2Settings");
    settings.Add("split_L_Biome2_Level11A_Master", true, "Under the Sea", "world2Settings");
    settings.Add("split_L_Biome2_Level11B_Master", true, "Marine Taxi", "world2Settings");
    settings.Add("split_L_Biome2_Level12_Master", true, "Nermals Party", "world2Settings");

    settings.Add("split_L_Biome3_Level13A_Master", true, "Lost In The Desert", "world3Settings");
    settings.Add("split_L_Biome3_Level13B_Master", true, "Theres a New Sheriff in Town", "world3Settings");
    settings.Add("split_L_Biome3_Level14A_Master", true, "The Western Village 1", "world3Settings");
    settings.Add("split_L_Biome3_Level14B_Master", true, "The Western Village 2", "world3Settings");
    settings.Add("split_L_Biome3_Level14C_Master", true, "The Western Village 3", "world3Settings");
    settings.Add("split_L_Biome3_Level15A_Master", true, "I Got a Train to Catch", "world3Settings");
    settings.Add("split_L_Biome3_Level15B_Master", true, "All Aboard", "world3Settings");
    settings.Add("split_L_Biome3_Level16A_Master", true, "Off The Rails", "world3Settings");
    settings.Add("split_L_Biome3_Level16B_Master", true, "Everyone After Garfield", "world3Settings");
    settings.Add("split_L_Biome3_Level17A_Master", true, "Barbecue Party", "world3Settings");
    settings.Add("split_L_Biome3_Level18_Master", true, "Desert Duel", "world3Settings");
    settings.Add("split_L_Biome0_Level19_Master", true, "Mondays Den", "world3Settings");
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
	vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<ulong>("GWorldName", vars.Utils.GWorld, 0x18);
    vars.Resolver.Watch<bool>("Loading", vars.Utils.GSync);

    vars.MapTextComponent = LiveSplit.UI.Components.ComponentManager.LoadLayoutComponent("LiveSplit.Text.dll", timer);
    vars.MapTextVisible = false;
    current.World = "";
    vars.CompletedSplits.Clear();
}

update
{
    vars.Uhara.Update();

    string world = vars.Utils.FNameToString(current.GWorldName);
	if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
	if (old.World != current.World) vars.Uhara.Log("World Change: " + current.World);
}

start
{
    return current.World == "L_CineMajor_01_Intro_Master";
}

split
{
    if (string.IsNullOrEmpty(current.World) || current.World == "None") return false;

    string splitKey = "split_" + current.World;
    if (settings[splitKey] && !vars.CompletedSplits.Contains(current.World))
    {
        vars.CompletedSplits.Add(current.World);
        return true;
    }

    return false;
}

isLoading
{
    return current.Loading;
}

exit
{
    timer.IsGameTimePaused = true;
}
