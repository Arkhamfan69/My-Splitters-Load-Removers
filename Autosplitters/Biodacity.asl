state("BiodacityA")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.Settings.CreateFromXml("Components/Bio_Ashton_Settings.xml");
    vars.Uhara.EnableDebug();


    vars.lcCache = new Dictionary<string, LiveSplit.UI.Components.ILayoutComponent>();

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) =>
    {
        var currentValue = currentLookup.ContainsKey(key) ? (currentLookup[key] ?? "(null)") : null;
        var oldValue = oldLookup.ContainsKey(key) ? (oldLookup[key] ?? "(null)") : null;

        if (oldValue != null && currentValue != null && !oldValue.Equals(currentValue)) {
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
        }

        if (oldValue == null && currentValue != null) {
            vars.Log(key + ": " + currentValue);
        }
    });

    vars.SetText = (Action<string, object>)((text1, text2) =>
    {
        const string FileName = "LiveSplit.Text.dll";
        LiveSplit.UI.Components.ILayoutComponent lc;

        if (!vars.lcCache.TryGetValue(text1, out lc))
        {
            lc = timer.Layout.LayoutComponents.Reverse().Cast<dynamic>()
                .FirstOrDefault(llc => llc.Path.EndsWith(FileName) && llc.Component.Settings.Text1 == text1)
                ?? LiveSplit.UI.Components.ComponentManager.LoadLayoutComponent(FileName, timer);

            vars.lcCache.Add(text1, lc);
        }

        if (!timer.Layout.LayoutComponents.Contains(lc))
            timer.Layout.LayoutComponents.Add(lc);

        dynamic tc = lc.Component;
        tc.Settings.Text1 = text1;
        tc.Settings.Text2 = text2.ToString();
    });

    vars.RemoveText = (Action<string>)(text1 =>
    {
        LiveSplit.UI.Components.ILayoutComponent lc;

        if (vars.lcCache.TryGetValue(text1, out lc))
        {
            timer.Layout.LayoutComponents.Remove(lc);
            vars.lcCache.Remove(text1);
        }
    });

    vars.RemoveAllTexts = (Action)(() =>
    {
        foreach (var lc in vars.lcCache.Values)
            timer.Layout.LayoutComponents.Remove(lc);
        vars.lcCache.Clear();
    });

}

init
{
	vars.Tool = vars.Uhara.CreateTool("Unity", "Utils");

    var Instance = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
    Instance.Watch<int>("Area", "AreaManager", "currentArea");
    Instance.Watch<bool>("Paused", "PauseMenu", "open");
    Instance.Watch<bool>("InventoryOpen", "InventoryOpen", "isOpen");
    // Boss Fight Stuff
    Instance.Watch<bool>("finalBossDead", "UlrichBoss", "died");

    vars.SetTextIfEnabled = (Action<string, object>)((text1, text2) =>
    {
        if (settings[text1])            
            vars.SetText(text1, text2); 
        else
            vars.RemoveText(text1);     
    });

    vars.CompletedSplits = new HashSet<string>();
}

start
{
    return current.ActiveScene == "GrayBox_1" && current.Area == 2;
}

isLoading
{
    if (current.ActiveScene == "MainMenu")
        return true;

    if (current.Paused && !current.InventoryOpen)
        return true;

    return false;
}

split
{
    if (settings["Area Splits"] && !vars.CompletedSplits.Contains(current.Area.ToString()))
    {
        vars.CompletedSplits.Add(current.Area.ToString());
        return true;
    }

    if (settings["DeadUlrich"] && current.finalBossDead && !vars.CompletedSplits.Contains("DeadUlrich"))
    {
        vars.CompletedSplits.Add("DeadUlrich");
        return true;
    }
}

update
{
    vars.Uhara.Update();
	current.ActiveScene = vars.Tool.GetActiveSceneName() ?? current.ActiveScene;

    vars.Watch(old, current, "Area");

    vars.SetTextIfEnabled("Area", current.Area);

    vars.Watch(old, current, "Paused");

    vars.SetTextIfEnabled("Paused", current.Paused);

    vars.Watch(old, current, "InventoryOpen");

    vars.SetTextIfEnabled("InventoryOpen", current.InventoryOpen);

    if (current.Paused && current.InventoryOpen)
    {
        current.Paused = false;
    }
}

exit
{
    timer.IsGameTimePaused = true;
    if (settings["Remove"]) vars.RemoveAllTexts();
}