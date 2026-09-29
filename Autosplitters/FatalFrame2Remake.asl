// Patch 1.0.2.1 by Arkahamfan69
// Patch 1.3.4.0 & 1.4.0.0 by Streetbackguy
state("FatalFrameII")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
    vars.Log = (Action<object>)((output) => print("[Fatal Frame 2 Remake] " + output));

    vars.GetCutsceneName = (Func<int, string>)(cut =>
    {
        if (cut == 1) return "Intro_Cutscene";
        if (cut == 2) return "Mayu_Cutscene";
        if (cut == 3) return "House_Cutscene";
        if (cut == 4) return "Entered_House";
        if (cut == 5) return "Picked_Up_Camera";
        if (cut == 6) return "Started_Lady_BossFight";
        if (cut == 7) return "Finished_BossFight";
        if (cut == 8) return "Mayu_Betrayal";
        if (cut == 9) return "Followed_Butterfly";
        if (cut == 10) return "Grabbed_By_Hand_InChest";
        if (cut == 11) return "EndOf_ChapterTwo";
        if (cut == 12) return "Shinobi_Cutscene";
        if (cut == 13) return "Grabbed_Bookshelf_Item";
        if (cut == 14) return "Reunited_With_Mayu";
        if (cut == 15) return "Entered_Shinobi_Room";
        return "Cutscene_Unknown";
    });
}

init
{
    vars.Watchers = new MemoryWatcherList
    {
        new MemoryWatcher<byte>(new DeepPointer(0x6FD5C9F)) { Name = "Cutscene" },
        new MemoryWatcher<byte>(new DeepPointer(0x6FD9961)) { Name = "CutsceneLoads" },
        new MemoryWatcher<int>(new DeepPointer(0x6FDC6A0)) { Name = "FPS" },
        new MemoryWatcher<byte>(new DeepPointer(0x6FD8374)) { Name = "OnMainMenu" }
    };

    vars.CutsceneCount = 0;
    current.OnMainMenu = 0;
    vars.FrameRate = 60;
    vars.MainMenuHasIncremented = false;
}

update
{
    vars.Uhara.Update();
    vars.Watchers.UpdateAll(game);

    if (vars.Watchers["OnMainMenu"].Current != 0 && vars.Watchers["OnMainMenu"].Old == 0)
    vars.MainMenuHasIncremented = true;

    if (vars.Watchers["FPS"].Current > 0)
        vars.FrameRate = vars.Watchers["FPS"].Current;

    if (vars.Watchers["Cutscene"].Current == 1 && vars.Watchers["Cutscene"].Old == 0 && vars.Watchers["Cutscene"].Current != 0 && vars.Watchers["OnMainMenu"].Current == 0)
    {
        vars.CutsceneCount++;

        vars.Uhara.Log("Cutscene Count: " + vars.CutsceneCount);
        vars.Uhara.Log("Current Cutscene:" + vars.GetCutsceneName(vars.CutsceneCount));
        vars.Uhara.Log("Cutscene Loads: " + vars.Watchers["CutsceneLoads"].Current);
    }
}

start
{
    return vars.CutsceneCount == 1 && vars.Watchers["Cutscene"].Old == 1 && vars.Watchers["Cutscene"].Current == 0;
}

isLoading
{

    if (vars.MainMenuHasIncremented && vars.Watchers["OnMainMenu"].Current == 1 && vars.Watchers["Cutscene"].Current == 1)
        return true;

    if (vars.Watchers["CutsceneLoads"].Current == 1)
        return true;

    if (vars.Watchers["Cutscene"].Current == 1)
        return true;

    return false;
}

onStart
{
    timer.IsGameTimePaused = true;
}

onReset
{
    vars.CutsceneCount = 0;
}

exit
{
    timer.IsGameTimePaused = true;
}
