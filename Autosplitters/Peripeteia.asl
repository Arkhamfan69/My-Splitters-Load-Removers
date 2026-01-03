state("Peripeteia") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Uhara.EnableDebug();
}

init
{
    var Instance =  vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    Instance.Watch<bool>("Loading", "Assembly-CSharp::LoadingScreen", "currentlyLoading");
}

update
{
    vars.Uhara.Update();
    vars.Helper.Update();
    vars.Helper.MapPointers();

    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    if (old.Scene != current.Scene) vars.Log("Scene Changed: " + current.Scene);

    if (old.Loading != current.Loading) vars.Uhara.Log("Loading changed: " + current.Loading);
}

isLoading
{
    return current.Loading;
}

start
{
    return current.Scene == "tutorial" && old.Scene != "tutorial" && current.Loading == false;

}
