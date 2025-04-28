state("BiodacityMansion")
{}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Biodacity: The Mansion";
    vars.Helper.AlertGameTime();
    
    dynamic[,] _settings =
	 {
	 	{ "Mansion", true, "Splitting Areas", null },
			{ "g_MansionExterior", true, "Split After Going Through The Tunnel & Entering The Area Before Pool", "Mansion" },
             { "g_MansionA", true, "Split When Entering The Mansion", "Mansion"},
             { "Courtyard", true, "Split When Entering The Courtyard", "Mansion"},
             { "g_MansionB", true, "Split When Entering Mansion B", "Mansion"},
             { "g_Pool", true, "Split When Entering The Pool Area", "Mansion"},
             { "Rocky Grounds", true, "Split When Entering The Rocky Grounds", "Mansion"},
             { "g_MansionBasement", true, "Split When Entering The Mansion B Basement", "Mansion"},
             { "Attic", false, "Split When Entering The Attic", "Mansion"},
             { "g_LabEntry", true, "Split When Entering The Underground Lab", "Mansion"},
             { "g_LabIntel", true, "Split When Entering The 2nd Lab Area", "Mansion"},
             { "LabDestroyed,", false, "Split When Entering The Destroyed Lab", "Mansion"},
             { "PoolSun", true, "Split When Entering The Final Area (Last Split Still Done Manually)", "Mansion"},
     };
     vars.Helper.Settings.Create(_settings);
}

init
{
      vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["IGT"] = mono.Make<float>("Statistics", "TimePlayed");
        vars.Helper["Scene"] = mono.MakeString("AreaManager", "__", "currentLevel");
        return true;
    });
}

start
{
    return current.Scene == "" && current.IGT != 0; // To Prevent it From Starting Anywhere Else Besides The Starting Area
}

split
{
    if (current.Scene != old.Scene && settings[current.Scene]) 
    {
        return true;
    }
}

isLoading
{
    return true;
}

gameTime
{
    return TimeSpan.FromSeconds(current.IGT);
}

update
{
    if (current.Scene != old.Scene) vars.Log("Current Scene Is: " + current.Scene);
}