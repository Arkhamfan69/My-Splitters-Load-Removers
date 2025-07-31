state("Adventure Time Pirates of the Enchiridion")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pirates of the Enchiridion";
    vars.Helper.LoadSceneManager = true;

    vars.FightNames = new Dictionary<string, string>
    {
        { "BattleScene7_Gameplay", "Tutorial Fight & Candy Kingdom Fights" },
        { "BattleScene9_Mushroom_Gameplay", "Mushroom Island Fight" },
        { "CandyKingdomShell_Geo", "Other Mushroom Island Fight" },
        { "BattleScene4_Gameplay", "Evil Forest Fights" },
        { "BattleScene19_Fern_Gameplay", "Fern Boss Fight" },
        { "BattleScene11_Sea_EvilForest_Gameplay", "Evil Forest Ocean" },
        { "BattleScene12_GelatoIsland_Gameplay", "Gelato Island" },
        { "BattleScene18_MotherVarmint_Gameplay", "Mother Varmint Boss" },
        { "BattleScene13_Sea_Generic_Gameplay", "Ocean Fight Near Fire Kingdom" },
        { "BattleScene8_Badlands_Gameplay", "Badlands" },
        { "BattleScene6_Gameplay", "Fire Kingdom" },
        { "BattleScene17_FireGiant_Gameplay", "Fire Giant Boss" },
        { "BattleScene15_Firebreak_Gameplay", "Fire Break Island" },
        { "BattleScene10_Sea_FireKingdom_Gameplay", "Fire Kingdom Sea Fight" },
        { "BattleScene5_Gameplay", "Final Boss" }
    };
}

init
{
    vars.CurrentFight = null;
}

isLoading
{
    return current.Scene == "Loading" || current.loadingScene == "CandyKingdom_Geo" || current.loadingScene == "TreeHouse_Flooded"
    || current.Scene == "Intro" || current.loadingScene2 == 2 || current.loadingScene2 == 22
    || current.loadingScene2 == 21 || current.loadingScene == "FireBreakIslandShell_P" || current.loadingScene2 == 30
    || current.loadingScene2 == 29 || current.loadingScene2 == 35 || current.loadingScene2 == 34
    || current.loadingScene2 == 26 || current.loadingScene2 == 25 || current.loadingScene2 == 38
    || current.loadingScene2 == 39 || current.loadingScene2 == 37 || current.loadingScene2 == 54
    || current.loadingScene2 == 53 || current.loadingScene2 == 64
    || current.loadingScene2 == 63 || current.loadingScene2 == 35 || current.loadingScene2 == 34;
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? old.Scene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? old.loadingScene;
    current.loadingScene2 = vars.Helper.Scenes.Loaded[0].Index ?? old.loadingScene;

    if (old.Scene != current.Scene)
    {
        vars.Log("Scene Changed: " + current.Scene);
    }

    if (old.loadingScene != current.loadingScene)
    {
        vars.Log("Loading Scene Changed From: " + old.loadingScene + " To: " + current.loadingScene);

        // Fight start detection
        if (vars.FightNames.ContainsKey(current.loadingScene))
        {
            if (vars.CurrentFight != current.loadingScene)
            {
                vars.CurrentFight = current.loadingScene;
                vars.Log("Fight Started: " + vars.FightNames[current.loadingScene]);
            }
        }
        // Fight end detection
        else
        {
            if (vars.CurrentFight != null)
            {
                vars.Log("Fight Ended: " + vars.FightNames[vars.CurrentFight]);
                vars.CurrentFight = null;
            }
        }
    }

    if (old.loadingScene2 != current.loadingScene2)
    {
        vars.Log("2nd Loading Scene Changed: " + current.loadingScene2);
    }
}

exit
{
    timer.IsGameTimePaused = true;
}

split
{
    // Split when a fight scene ends
    return vars.FightNames.ContainsKey(old.loadingScene) && !vars.FightNames.ContainsKey(current.loadingScene);

    if (old.loadingScene == "WorldTerrainMidW_Geo" && current.loadingScene == "TreeHouse_Unflooded")
    {
        return true;
    }
}

reset
{
    return old.loadingScene == "TreeHouse_Flooded" && current.loadingScene == "TreeHouse_Unflooded_Night";
}
