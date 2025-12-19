state("Unmourned") 
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Helper.LoadSceneManager = true;
    vars.Uhara.EnableDebug();

    dynamic[,] _settings =
	{
		{ "Area", true, "Splitting Areas", null },
			{ "1. Maze", true, "Maze", "Area" },
			{ "2. MeltedHall", true, "Melted Hall ", "Area" },
            { "3. CameraHouses", true, "Camera Houses", "Area" },
            { "0. WakeFromDreamNew", true, "Back In Starting House", "Area" },
            { "1.1 RoadToLibrary_House", true, "Outside Of The House", "Area" },
            { "1.2 RoadToLibrary_Library", true, "Entered Sewer", "Area" },
            { "2. HouseAfterLibrary", true, "At The House Again", "Area" },
            { "3. Opera", true, "Opera Theater", "Area" },
            { "4. EchoesOfParanoia", true, "Echoes Of Paranoia", "Area" },
            { "5. WomanDragFinale", true, "Nathan Jumpscare", "Area" },
            { "0. GettingPhotographicCamera", true, "Getting The Camera", "Area" },
            { "1. HideAndSeek", true, "Hide And Seek", "Area" },
            { "2. schoolFirstTime", true, "First Time In School", "Area" },
            { "3. KnockKnock", true, "Back In Attic", "Area" },
            { "4. schoolSecondTime", true, "Second Time In School", "Area" },
            { "5. Betrayal", true, "Betrayal", "Area" },
            { "6. EmmasDeathNearby", true, "Emma Drowning Nightmare", "Area" },
            { "0. ThePrayer", true, "The Prayer Scene", "Area" },
            { "1. RoadToVillage", true, "Road To Village", "Area" },
            { "2. PrisonBreak", true, "Prison Break", "Area" },
            { "3. TheExorcism", true, "The Exorcism", "Area" },
            { "4. TheSacrifice", true, "The Sacrifice", "Area" },
            { "5.1 RoadToChurchRuins", true, "Road To Church Ruins", "Area" },
            { "5.2 RoadToChurchChurch", true, "Fell Off Plank", "Area" },
            { "6. TheEnd", true, "The Ending", "Area" },
    };

	vars.Uhara.Settings.Create(_settings);
}

init
{
    vars.CompletedSplits = new HashSet<string>();

    var Instance =  vars.Uhara.CreateTool("Unity", "IL2CPP", "Instance");

    Instance.Watch<bool>("Paused", "Assembly-CSharp:HFPS.Systems:HFPS_GameManager", "isPaused");
}

split
{
    if (old.Scene != current.Scene && !vars.CompletedSplits.Contains(current.Scene) && settings.ContainsKey(current.Scene) && settings[current.Scene])
	{
		vars.CompletedSplits.Add(current.Scene);
		return true;
	}
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();
    vars.Uhara.Update();

    current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;
    if (old.Scene != current.Scene) vars.Log("Scene Changed: " + current.Scene);
}

isLoading
{
    return current.Scene == "SceneLoader L" || current.Paused;
}
