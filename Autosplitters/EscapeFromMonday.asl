state("GFD-Win64-Shipping")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
    vars.CompletedSplits = new HashSet<string>();
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
	vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<ulong>("GWorldName", vars.Utils.GWorld, 0x18);
    vars.Resolver.Watch<bool>("Loading", vars.Utils.GSync);

    current.World = "";
}

update
{
    vars.Uhara.Update();
    
    string world = vars.Utils.FNameToString(current.GWorldName);
	if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;
	if (old.World != current.World) vars.Uhara.Log("World Change: " + current.World);

    if (current.Loading != old.Loading)
    {
        vars.Uhara.Log("Loading Change: " + current.Loading);
    }
}

isLoading
{
    return current.Loading;
}