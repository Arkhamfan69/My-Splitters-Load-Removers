state("Kiki")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Uhara.AlertLoadless(); 
    vars.Uhara.EnableDebug(); 

    dynamic[,] _settings =
    {
        { "Kiki", true, "Kiki Auto-Splitter Settings", null},
            {"Split", true, "Level To Split On", "Kiki"},
                {"W1", true, "World 1", "Split"},
                    {"Level 2", true, "Level 2", "W1"},
                    {"Level 3", true, "Level 3", "W1"},
                    {"Level 4", true, "Level 4", "W1"},
                    {"Level 5", true, "Level 5", "W1"},
                    {"Level 6", true, "Level 6", "W1"},
                    {"Level 7", true, "Level 7", "W1"},
                    {"Level 8", true, "Level 8", "W1"},
                    {"Level 9", true, "Level 9", "W1"},
                    {"Level 10", true, "Level 10", "W1"},
                {"W2", true, "World 2", "Split"},
                    {"Level 11", true, "Level 11", "W2"},
                    {"Level 12", true, "Level 12", "W2"},
                    {"Level 13", true, "Level 13", "W2"},
                    {"Level 14", true, "Level 14", "W2"},
                    {"Level 15", true, "Level 15", "W2"},
                    {"Level 16", true, "Level 16", "W2"},
                    {"Level 17", true, "Level 17", "W2"},
                    {"Level 18", true, "Level 18", "W2"},
                    {"Level 19", true, "Level 19", "W2"},
                    {"Level 20", true, "Level 20", "W2"},
                {"W3", true, "World 3", "Split"},
                    {"Level 21", true, "Level 21", "W3"},
                    {"Level 22", true, "Level 22", "W3"},
                    {"Level 23", true, "Level 23", "W3"},
                    {"Level 24", true, "Level 24", "W3"},
                    {"Level 25", true, "Level 25", "W3"},
                    {"Level 26", true, "Level 26", "W3"},
                    {"Level 27", true, "Level 27", "W3"},
                    {"Level 28", true, "Level 28", "W3"},
                    {"Level 29", true, "Level 29", "W3"},
                    {"Level 30", true, "Level 30", "W3"},
                {"W4", true, "World 4", "Split"},
                    {"Level 31", true, "Level 31", "W4"},
                    {"Level 32", true, "Level 32", "W4"},
                    {"Level 33", true, "Level 33", "W4"},
                    {"Level 34", true, "Level 34", "W4"},
                    {"Level 35", true, "Level 35", "W4"},
                    {"Level 36", true, "Level 36", "W4"},
                    {"Level 37", true, "Level 37", "W4"},
                    {"Level 38", true, "Level 38", "W4"},
                    {"Level 39", true, "Level 39", "W4"},
                    {"Level 40", true, "Level 40", "W4"},
                {"W5", true, "World 5", "Split"},
                    {"Level 41", true, "Level 41", "W5"},
                    {"Level 42", true, "Level 42", "W5"},
                    {"Level 43", true, "Level 43", "W5"},
                    {"Level 44", true, "Level 44", "W5"},
                    {"Level 45", true, "Level 45", "W5"},
                    {"Level 46", true, "Level 46", "W5"},
                    {"Level 47", true, "Level 47", "W5"},
                    {"Level 48", true, "Level 48", "W5"},
                    {"Level 49", true, "Level 49", "W5"},
                    {"Level 50", true, "Level 50", "W5"},
                {"W6", true, "World 6", "Split"},
                    {"Level 51", true, "Level 51", "W6"},
                    {"Level 52", true, "Level 52", "W6"},
                    {"Level 53", true, "Level 53", "W6"},
                    {"Level 54", true, "Level 54", "W6"},
                    {"Level 55", true, "Level 55", "W6"},
                    {"Level 56", true, "Level 56", "W6"},
                    {"Level 57", true, "Level 57", "W6"},
                    {"Level 58", true, "Level 58", "W6"},
                    {"Level 59", true, "Level 59", "W6"},
                    {"Level 60", true, "Level 60", "W6"},
    };

    vars.Uhara.Settings.Create(_settings);
}

init
{
    vars.Tool = vars.Uhara.CreateTool("Unity", "Utils");
    var Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");

    Instance.Watch<bool>("Loading", "LevelManager", "_loadingInProgress");

    vars.CompletedSplits = new HashSet<string>();
    current.ActiveScene = "";
    current.Loading = false;
}

update
{
    vars.Uhara.Update();
	current.ActiveScene = vars.Tool.GetActiveSceneName() ?? current.ActiveScene;

    if (current.ActiveScene != old.ActiveScene) vars.Uhara.Log("Scene changed to " + current.ActiveScene);

    if (old.Loading != current.Loading) vars.Uhara.Log("Loading State Changed: " + current.Loading);
}

isLoading
{
    return current.Loading || current.ActiveScene == "MainMenu";
}

split
{
    if (settings.ContainsKey(current.ActiveScene) && settings[current.ActiveScene] && !vars.CompletedSplits.Contains(current.ActiveScene))
    {
        vars.CompletedSplits.Add(current.ActiveScene);
        return true;
    }

    if (current.ActiveScene == "CreditsScene")
    {
        return true;
    }
}

start
{
    return current.ActiveScene == "Level 1" && old.ActiveScene != "Level 1";
}

onStart
{
    vars.CompletedSplits.Clear();
}