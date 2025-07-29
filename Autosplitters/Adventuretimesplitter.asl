state("Adventure Time Pirates of the Enchiridion")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pirates of the Enchiridion";
    vars.Helper.LoadSceneManager = true;
}

isLoading
{
    return current.Scene == "Loading" || current.loadingScene == "CandyKingdom_Geo" || current.loadingScene == "TreeHouse_Flooded"
    || current.Scene == "Intro" || current.loadingScene2 == 2 || current.loadingScene2 == 22
    || current.loadingScene2 == 21 || current.loadingScene == "FireBreakIslandShell_P" || current.loadingScene2 == 30
    || current.loadingScene2 == 29 || current.loadingScene2 == 35 || current.loadingScene2 == 34
    || current.loadingScene2 == 26 || current.loadingScene2 == 25 || current.loadingScene2 == 38
    || current.loadingScene2 == 39 || current.loadingScene2 == 37 || current.loadingScene2 == 54
    || current.loadingScene2 == 53 || current.loadingScene2 == 64 || current.loadingScene2 == 63
    || current.loadingScene2 == 35 || current.loadingScene2 == 34;
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? old.Scene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? old.loadingScene;
    current.loadingScene2 = vars.Helper.Scenes.Loaded[0].Index ?? old.loadingScene;

    if (old.Scene != current.Scene)
    {
        vars.Log("Scene Changed: " + current.Scene);
    }

    if (old.loadingScene != current.loadingScene)
    {
        vars.Log("Loading Scene Changed From: " + old.loadingScene + " To: " + current.loadingScene);
    }

    if (old.loadingScene2 != current.loadingScene2)
    {
        vars.Log("2nd Loading Scene Changed: " + current.loadingScene2);
    }
}

exit
{
    timer.IsGameTimePaused = true;
}

split
{
    return old.loadingScene == "WorldTerrainMidW_Geo" && current.loadingScene == "TreeHouse_Unflooded"; // This Is Just To Autoend The Timer
}

reset
{
    return old.loadingScene == "TreeHouse_Flooded" && current.loadingScene == "TreeHouse_Unflooded_Night";
}
