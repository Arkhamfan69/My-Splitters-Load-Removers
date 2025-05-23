state("Breadsticks")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Breadsticks";
    vars.Helper.LoadSceneManager = true;

    dynamic[,] _settings =
    {
        {"Bread", true, "Area To Split", null},
            {"Wasteland", true, "Split When Entering Level 2 (Wasteland)", "Bread"},
            {"Grotto", true, "Split When Entering Level 3 (Grotto)", "Bread"},
    };
    vars.Helper.Settings.Create(_settings);
}

init
{
    vars.CompletedSplits = new HashSet<string>();
}

start
{
    return current.Scene == "Tutorial" && old.Scene == "MainMenu";
}

split
{
    if (current.Scene != old.Scene && settings[current.Scene] && !vars.CompletedSplits.Contains(current.Scene))
    {
        vars.CompletedSplits.Add(current.Scene);
        return true;
    };
}

reset
{
    return current.Scene == "MainMenu";
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    // Log the scene change
    if (old.Scene != current.Scene)
        vars.Log("Scene Changed: " + current.Scene);
}