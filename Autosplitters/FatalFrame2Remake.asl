// Patch 1.0.2.1 by Arkahamfan69
// Patch 1.3.4.0 by Streetbackguy
state("FatalFrameII")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
    vars.Log = (Action<object>)((output) => print("[Fatal Frame 2 Remake] " + output));
}

init
{
    var pv = modules.First().FileVersionInfo.ProductVersion;
    print("Game version: " + pv);

    switch (pv)
    {
        case "1.0.2.1":
            version = "1.0.2.1";
            break;
        
        case "1.3.4.0":
            version = "1.3.4.0";
            break;

        default:
            version = "Unknown";
            break;
    }

    vars.GetCutsceneName = (Func<int, string>)(cut =>
    {
        if(version == "1.0.2.1")
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
        }

        if(version == "1.3.4.0")
        {
            if (cut == 1) return "Intro_Cutscene";
            if (cut == 3) return "Mayu_Cutscene";
            if (cut == 5) return "House_Cutscene";
            if (cut == 7) return "Entered_House";
            if (cut == 9) return "Picked_Up_Camera";
            if (cut == 11) return "Started_Lady_BossFight";
            if (cut == 13) return "Finished_BossFight";
            if (cut == 15) return "Mayu_Betrayal";
            if (cut == 17) return "Followed_Butterfly";
            if (cut == 19) return "Grabbed_By_Hand_InChest";
            if (cut == 21) return "EndOf_ChapterTwo";
            if (cut == 23) return "Shinobi_Cutscene";
            if (cut == 25) return "Grabbed_Bookshelf_Item";
            if (cut == 27) return "Reunited_With_Mayu";
            if (cut == 29) return "Entered_Shinobi_Room";
            return "Cutscene_Unknown";
        }

        return "Cutscene_Unknown";
    });

    if(version == "1.0.2.1")
    {
        vars.Watchers = new MemoryWatcherList
        {
            new MemoryWatcher<byte>(new DeepPointer(0x6FCD6F3)) { Name = "Cutscene" },
            new MemoryWatcher<int>(new DeepPointer(0x6FCD58C)) { Name = "FPS" },
            new MemoryWatcher<byte>(new DeepPointer(0x6FEB5AC)) { Name = "OnMainMenu" }
        };
    }

    if(version == "1.3.4.0")
    {
        vars.Watchers = new MemoryWatcherList
        {
            new MemoryWatcher<byte>(new DeepPointer(0x6FCDBE1)) { Name = "Cutscene" },
            new MemoryWatcher<int>(new DeepPointer(0x6FD07D0)) { Name = "FPS" },
            new MemoryWatcher<byte>(new DeepPointer(0x6FCC6DD)) { Name = "OnMainMenu" }
        };
    }

    vars.CutsceneCount = 0;
    current.OnMainMenu = 0;
    vars.FrameRate = 60;
    vars.MainMenuHasIncremented = false;
}

update
{
    vars.Uhara.Update();
    vars.Watchers.UpdateAll(game);

    if(version == "1.0.2.1")
    {
        // vars.Log("Cutscene: " + vars.Watchers["Cutscene"].Current);
        // vars.Log("FPS: " + vars.Watchers["FPS"].Current);
        // vars.Log("On Main Menu: " + vars.Watchers["OnMainMenu"].Current);

        if (vars.Watchers["OnMainMenu"].Current != 0 && vars.Watchers["OnMainMenu"].Old == 0)
            vars.MainMenuHasIncremented = true;

        if (vars.Watchers["FPS"].Current > 0)
            vars.FrameRate = vars.Watchers["FPS"].Current;

        bool isCutsceneLoad = vars.Watchers["Cutscene"].Current == 62;
        bool wasCutsceneLoad = vars.Watchers["Cutscene"].Old == 62;

        if (isCutsceneLoad && !wasCutsceneLoad && vars.Watchers["Cutscene"].Current != 0)
        {
            vars.CutsceneCount++;

            vars.Uhara.Log("Cutscene Count: " + vars.CutsceneCount);
            vars.Uhara.Log("Current Cutscene:" + vars.GetCutsceneName(vars.CutsceneCount));
        }

        if (timer.CurrentPhase == TimerPhase.NotRunning)
        {
            vars.CutsceneCount = 0;
        }
    }

    if(version == "1.3.4.0")
    {
        // vars.Log("Cutscene: " + vars.Watchers["Cutscene"].Current);
        // vars.Log("Cutscene Count: " + vars.CutsceneCount);
        // vars.Log("FPS: " + vars.Watchers["FPS"].Current);
        // vars.Log("On Main Menu: " + vars.Watchers["OnMainMenu"].Current);

        if (vars.Watchers["OnMainMenu"].Current != 0 && vars.Watchers["OnMainMenu"].Old == 0)
        vars.MainMenuHasIncremented = true;

        if (vars.Watchers["FPS"].Current > 0)
            vars.FrameRate = vars.Watchers["FPS"].Current;

        if (vars.Watchers["Cutscene"].Current == 1 && vars.Watchers["Cutscene"].Old == 0 && vars.Watchers["Cutscene"].Current != 0 && vars.Watchers["OnMainMenu"].Current == 1)
        {
            vars.CutsceneCount++;

            vars.Uhara.Log("Cutscene Count: " + vars.CutsceneCount);
            vars.Uhara.Log("Current Cutscene:" + vars.GetCutsceneName(vars.CutsceneCount));
        }
    }
}

// start
// {
//     if(version == "1.0.2.1")
//     {
//         return vars.CutsceneCount == 1 && vars.GetCutsceneName(vars.CutsceneCount) == "Intro_Cutscene";
//     }

//     if(version == "1.3.4.0")
//     {
//         return vars.CutsceneCount == 1 && vars.GetCutsceneName(vars.CutsceneCount) == "Intro_Cutscene" && vars.Watchers["Cutscene"].Old == 1;
//     }
// }

isLoading
{
    if(version == "1.0.2.1")
    {
        if (vars.MainMenuHasIncremented && vars.Watchers["OnMainMenu"].Current == 0 && vars.Watchers["Cutscene"].Current == 62)
            return true;

        if (vars.Watchers["Cutscene"].Current == 62)
            return true;

        return false;
    }

    if(version == "1.3.4.0")
    {
        if (vars.MainMenuHasIncremented && vars.Watchers["OnMainMenu"].Current == 1 && vars.Watchers["Cutscene"].Current == 1)
            return true;

        if (vars.Watchers["Cutscene"].Current == 1)
            return true;

        return false;
    }
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
