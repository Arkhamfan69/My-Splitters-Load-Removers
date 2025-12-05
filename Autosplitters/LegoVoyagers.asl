// Made By Arkhamfan69 And Sonic7
state("LEGO Voyagers") 
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Uhara.Settings.CreateFromXml("Components/LVoyagers_Settings.xml");
    vars.Helper.LoadSceneManager = true;
    vars.Uhara.EnableDebug();
}

init
{
    var Instance =  vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    Instance.Watch<int>("Chapter", "TumbleDefinition::LoadGameElement", "_active", "index");

    vars.CompletedChapters = new HashSet<int>();
}

update
{
    vars.Uhara.Update();
    vars.Helper.Update();
    vars.Helper.MapPointers();

    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    if (old.Scene != current.Scene) vars.Log("Scene Changed: " + current.Scene);
    print("Current Chapter: " + current.Chapter.ToString());
}

isLoading
{
    return current.Scene == "Foundation";
}

start
{
    if (settings["IL"])
    {
        return true;
    }
    
    if (settings["Start"] && current.Scene == "nature_root" && old.Scene == "Foundation" && current.Chapter == 0)
    {
        return true;
    }
}

onStart
{
    vars.CompletedChapters.Clear();
}

split
{
    if (current.Chapter > old.Chapter && current.Chapter > 0)
    {
        string chapterSettingId = current.Chapter.ToString();
        if (settings.ContainsKey(chapterSettingId) && settings[chapterSettingId])
        {
            return true;
        }
    }
}

exit
{
    timer.IsGameTimePaused = true;
}
