state("Unmourned")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Unmourned";  
    vars.Helper.LoadSceneManager = true;

    dynamic[,] _settings =
	{
		{ "Area", true, "Splitting Areas", null },
			{ "1.2 RoadToLibrary_Library_Demo", true, "Split When You Go To The Library", "Area" },
			{ "4. EchoesOfParanoia", true, "Split When Entering The Wanna Be Among The Sleep Ass Area", "Area" },
    };
	vars.Helper.Settings.Create(_settings);
}

init
{
    vars.CompletedSplits = new HashSet<string>();
}

start
{
    return current.Scene == "0. WakeFromDreamNew";
}

split
{
    if (current.Scene != old.Scene && settings[current.Scene] && !vars.CompletedSplits.Contains(current.Scene))
    {
        vars.CompletedSplits.Add(current.Scene);
        return true;
    }
}

reset
{
    return current.Scene == "MainMenu L";
}

onReset
{
    vars.CompletedSplits.Clear();
}

isLoading
{
    return current.Scene == "SceneLoader L";
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    // Log the scene change
    if (old.Scene != current.Scene)
        vars.Log("Scene Changed: " + current.Scene);
}
