state("Adventure Time Pirates of the Enchiridion")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pirates of the Enchiridion";
    vars.Helper.LoadSceneManager = true;
}

init
{
    
}

isLoading
{
    return current.Scene == "Loading" || current.loadingScene == "CandyKingdom_Geo" || current.loadingScene2 == 2 || current.loadingScene2 == 22 || current.loadingScene2 == 21 || current.loadingScene2 == 26 || current.loadingScene2 == 25 || current.loadingScene2 == 38 || current.loadingScene2 == 39 || current.loadingScene2 == 37 || current.loadingScene2 == 54 || current.loadingScene2 == 53 || current.loadingScene2 == 65 || current.loadingScene2 == 64 || current.loadingScene2 == 63;
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
        vars.Log("Loading Scene Changed: " + current.loadingScene);
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

reset
{
    return old.loadingScene == "TreeHouse_Flooded" && current.loadingScene == "TreeHouse_Unflooded_Night";
}

// All Of These Logs Use loadingScene

// Fight Name Logs
// Tutorial Fight - BattleScene7_Gameplay
// First Candy Kingdom Fight - Candy Kingdom Fights
// Mushroom Island Fight - BattleScene9_Mushroom_Gameplay 
// Other Mushroom Island Fight - CandyKingdomShell_Geo
// Evil Forest Fights - BattleScene4_Gameplay
// Fern Boss Fight - BattleScene19_Fern_Gameplay
// Evil Forest Ocean  - BattleScene11_Sea_EvilForest_Gameplay
// Candy Kingdom Ocean - BattleScene7_Gameplay
// Gelato Island - BattleScene12_GelatoIsland_Gameplay
// 

// Upgrade Logs
// Ocean Training - TrainingScene_Ocean_Gameplay
// Candy Kingdom - TrainingScene_CandyKingdom_Gameplay
// Mushroom Island - TrainingScene_MushroomIsland_Gameplay
// Evil Forest - TrainingScene_EvilForest_Gameplay
// Ice Kingdom - TrainingScene_IceKingdom_Gameplay
// Gelato Island - TrainingScene_GelatoIsland_Gameplay
