state("Adventure Time Pirates of the Enchiridion")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pirates of the Echidereion";
    vars.Helper.LoadSceneManager = true;
}

init
{
    vars.UpgradeState = false;
}

isLoading
{
    return current.Scene == "Loading" || current.loadingScene == 2 || current.loadingScene == 22 || current.loadingScene == 21;
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? old.Scene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Index ?? old.loadingScene;

    if (old.Scene != current.Scene)
    {
        vars.Log("Scene Changed: " + current.Scene);
    }

    if (old.loadingScene != current.loadingScene)
    {
        vars.Log("Loading Scene Changed: " + current.loadingScene);
    }
}

exit
{
    timer.IsGameTimePaused = true;
}
