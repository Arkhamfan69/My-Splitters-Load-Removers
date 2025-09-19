state("goosebumps") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.Settings.CreateFromXml("Components/Goosebumps_Settings.xml");
    vars.Helper.AlertLoadless();
    vars.Helper.GameName = "Goosebumps: Terror in Little Creek";
    vars.Helper.LoadSceneManager = true;

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
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Mono = mono;
        return true;
    });

    vars.GGClassesLoaded = false;

    current.Scene = "";
    current.HP = 0;
    current.RoomID = "";
    current.Quest = ""; 
    current.DeathLoad = false;
    vars.ItemsCollected = new HashSet<string>();

    vars.SetTextIfEnabled = (Action<string, object>)((text1, text2) =>
    {
        if (settings[text1])            
            vars.SetText(text1, text2); 
        else
            vars.RemoveText(text1);     
    });
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;

    if (!vars.GGClassesLoaded && current.Scene != "Boot" && current.Scene != "Master" && current.Scene != "LogoTrain" && current.Scene != "Loading" && current.Scene != "MainMenu")
    {
        var ggAssembly = vars.Mono.Images["GoosebumpsGame"];
        if (ggAssembly != null)
        {
            ggAssembly.Clear(); 

            bool ggSearching = true;

            var GGPM = vars.Mono["GoosebumpsGame", "PlayerManager", 1];
            var GGMP = vars.Mono["GoosebumpsGame", "MapManager", 1];
            var GGSTM = vars.Mono["GoosebumpsGame", "GameStateManager", 1];
            var GGHM = vars.Mono["GoosebumpsGame", "HUDManager", 1];
            var GGAM = vars.Mono["GoosebumpsGame", "ApplicationManager", 1];
            var GGIM = vars.Mono["GoosebumpsGame", "InventoryManager", 1];

            if (GGPM != null && GGPM.Static != IntPtr.Zero &&
                GGMP != null && GGMP.Static != IntPtr.Zero &&
                GGSTM != null && GGSTM.Static != IntPtr.Zero)
                {
                    vars.GGClassesLoaded = true;

                    vars.Helper["HP"] = vars.Mono.Make<float>(GGPM, "instance", "playerCombatRoot", "combatRoot", "currentHP");
                    vars.Helper["RoomID"] = vars.Mono.MakeString(GGMP, "instance", "currentMapRoomSO", "id");
                    vars.Helper["Quest"] = vars.Mono.MakeString(GGSTM, "instance", "currentState", "id");
                    vars.Helper["DeathLoad"] = vars.Mono.Make<bool>(GGAM, "instance", "occupied");
                    vars.Helper["Inventory"] = vars.Mono.MakeList<IntPtr>(GGIM, "instance", "inventoryItems");

                    vars.Log("GoosebumpsGame classes loaded successfully.");
                    ggSearching = false;
                }

            if (vars.Helper["Inventory"].Current.Count > vars.Helper["Inventory"].Old.Count)
            {
                string id = vars.Helper.ReadString(vars.Helper["Inventory"].Current[vars.Helper["Inventory"].Current.Count - 1] + 0x10, 0x28, 0x68, 0x10, 0x20, 0x10);
                vars.Log("Picked Up: " + id);
            }

        }
    }

    if (old.Scene != current.Scene) vars.Log("Scene Changed: " + current.Scene);
    if (old.HP != current.HP) vars.Log("HP Changed: " + current.HP);
    if (old.RoomID != current.RoomID) vars.Log("RoomID Changed: " + current.RoomID);
    if (old.Quest != current.Quest) vars.Log("Quest Changed: " + current.Quest);
    if (old.DeathLoad != current.DeathLoad) vars.Log("Death Load Changed: " + current.DeathLoad);

    if (vars.Helper["Inventory"].Current.Count > vars.Helper["Inventory"].Old.Count)
    {
        string id = vars.Helper.ReadString(vars.Helper["Inventory"].Current[vars.Helper["Inventory"].Current.Count - 1] + 0x10, 0x28, 0x68, 0x10, 0x20, 0x10);
        vars.Log("Picked Up: " + id);
    }

    vars.Watch(old, current, "Quest");
    vars.Watch(old, current, "RoomID");
    vars.Watch(old, current, "HP");

    vars.SetTextIfEnabled("Quest", current.Quest);
    vars.SetTextIfEnabled("RoomID", current.RoomID);
    vars.SetTextIfEnabled("HP", current.HP);
}

isLoading
{
    return current.Scene == "Boot" || current.Scene == "Master" || current.Scene == "LogoTrain"
    || current.Scene == "Loading" || current.Scene == "MainMenu" || current.HP == 0 || current.DeathLoad;
}

split
{
    if (current.Quest == "23_schneeldefeated" && old.Quest != "23_schneeldefeated") return true;

    if (vars.Helper["Inventory"].Current.Count > vars.Helper["Inventory"].Old.Count)
	{
        string id = vars.Helper.ReadString(vars.Helper["Inventory"].Current[vars.Helper["Inventory"].Current.Count - 1] + 0x10, 0x28, 0x68, 0x10, 0x20, 0x10);
        if (!vars.ItemsCollected.Contains(id)) 
		{
			vars.ItemsCollected.Add(id);
			if (settings[id]) return true;
		}
	}
}

start
{
    return current.Scene == "Region_LittleCreek" && old.Scene != "Region_LittleCreek" && current.Quest == "0_speakwithharvey";
}

onStart
{
    timer.IsGameTimePaused = true;
    vars.ItemsCollected.Clear();
}

reset
{
    return settings["Reset"] && current.Scene == "MainMenu";
}

exit
{
    timer.IsGameTimePaused = true;
    if (settings["Remove"]) vars.RemoveAllTexts();
}