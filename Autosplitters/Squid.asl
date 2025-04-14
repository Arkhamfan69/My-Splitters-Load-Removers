state("Sinister Squidward") {} // This Game Is So Stupid

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Sinister Squidward"; 
    vars.Helper.LoadSceneManager = true;

    dynamic[,] _settings =
	{
		{ "Area", true, "Split On Scene?", null },
			{ "NewsReportScene", false, "Split When The News Report Starts", "Area" },
			{ "SpongebobsHouseScene", true, "Split When You Enter Spongebobs Pineapple", "Area" },
    };
	vars.Helper.Settings.Create(_settings);
}

start
{
    return current.Scene == "KrustyKrabScene";
}

split
{
    if (current.Scene != old.Scene && settings[current.Scene]) 
    {
        return true;
    }
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    // Log the scene change
    if (old.Scene != current.Scene)
        vars.Log("Scene Changed: " + current.Scene);
}