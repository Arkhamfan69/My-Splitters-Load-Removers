// Made By Arkhamfan69 And Sonic7
state("LEGO Voyagers") 
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Uhara.EnableDebug();

    settings.Add("Start", true, "Start On Chapter 1");
}

init
{
}

update
{
    vars.Uhara.Update();
    vars.Helper.Update();
    vars.Helper.MapPointers();

    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    if (old.Scene != current.Scene) vars.Log("Scene Changed: " + current.Scene);
}

isLoading
{
    return current.Scene == "Foundation";
}

start
{
    if (settings["Start"] && current.Scene == "nature_root" && old.Scene == "Foundation")
    {
        return true;
    }
}

exit
{
    timer.IsGameTimePaused = true;
}