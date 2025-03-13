state("Stardrop") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Stardrop";
    vars.Helper.LoadSceneManager = true;
    
    settings.Add("Starsliver", false, "Split When Picking Up A Starsliver");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["Starshard"] = mono.Make<int>("GameManager", "instance", "Starshard_Amount");
        vars.Helper["Credits"] = mono.Make<bool>("GameManager", "hasBeatenGame");
        vars.Helper["Starsliver"] = mono.Make<int>("GameManager", "instance", "Starsliver_Amount");
        vars.Helper["Paused"] = mono.Make<bool>("GameManager", "isPaused");
        return true;
    });

    current.Scene = "";
    current.Starshard = 0;
    current.Starsliver = 0;
    current.Credits = false;
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    // Log the scene change
    if (old.Scene != current.Scene)
        vars.Log("Scene Changed: " + current.Scene);

    // Check and log only when values change
    if (old.Starshard != current.Starshard)
        vars.Log("Starshard Changed: " + current.Starshard);

    if (old.Credits != current.Credits)
        vars.Log("Credits Changed: " + current.Credits);

    if (old.Starsliver != current.Starsliver)
        vars.Log("Starsliver Changed: " + current.Starsliver);

    if (old.Paused != current.Paused)
        vars.Log("Paused Changed: " + current.Paused);
}

split
{
    if (current.Starshard > old.Starshard) {
        return true;
    }

    if (current.Starsliver > old.Starsliver) {
        return settings["Starsliver"];
    }
}

start
{
    return old.Scene != "Stage1" && current.Scene == "Stage1";
}

reset
{
    return old.Scene != "Stage0" && current.Scene == "Stage0";
}

isLoading
{
    return current.Paused == true;
}
