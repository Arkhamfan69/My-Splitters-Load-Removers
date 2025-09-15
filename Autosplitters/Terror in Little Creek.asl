state("goosebumps")
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Terror in Little Creek";
    vars.Helper.LoadSceneManager = true;

    settings.Add("Reset", false, "Reset on The Main Menu");
}

init
{
    current.Scene = "";
    current.loadingScene = "";
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? old.loadingScene;

    if (old.Scene != current.Scene)
        vars.Log("Scene Changed: " + current.Scene);

    if (old.loadingScene != current.loadingScene)
    {
        vars.Log("Loading Scene Changed: " + current.loadingScene);
    }
}

isLoading
{
    return current.Scene == "Boot" || current.Scene == "Master" || current.Scene == "LogoTrain" || current.Scene == "Loading" || current.Scene == "MainMenu";
}

start
{
    return old.Scene == "Loading" && current.Scene == "Region_LittleCreek" && current.LoadingScene == "Cinematic_LittleCreek";
}

reset
{
    return settings["Reset"] && current.Scene == "MainMenu";
}