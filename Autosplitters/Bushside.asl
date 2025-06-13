// Credits
// Nikoheart - Sigscans & Helpers & Starting Block
// Arkhamfan69 - Creating The Splitter

state("BushsideRangers-Win64-Shipping") 
{
    bool HiddenLoads: 0x5635EF9;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Bushside Rangers Chapter 1";  

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
         var timingMessage = MessageBox.Show(
        "Thank you so much for using the Bushside Rangers Autosplitter!\n" +
        "LiveSplit has detected that you're currently using Real Time.\n" +
        "For the most accurate timing, it's highly recommend you switch to Game Time.\n" +
        "Would you be willing to make this change for a more precise experience?",
        "LiveSplit | Bushside Rangers Chapter 1",
        MessageBoxButtons.YesNo, MessageBoxIcon.Information);
    }

    settings.Add("skip", false, "Split On Final Cutscene (With Rubble Skip)");
    settings.Add("skip2", true, "Split On Final Cutscene (No Rubble Skip)");

   	dynamic[,] _settings =
	{
		{ "Area", true, "Splitting Areas", null },
			{ "1_intro_entrance", false, "Split When Entering The Nature Hub", "Area" },
			{ "1_cableCarSectEntrance", true, "Split When Entering The Utilidors", "Area" },
			{ "1_cableCarSect2", false, "Split When Entering The First Autoscroller", "Area" },
            { "1_cableCarSectDevice", true, "Split When Entering Simons Sector", "Area" },
            { "1_cableCarFinal", false, "Split When Entering The 2nd Autoscroller", "Area" },
            { "1_giftShopSect", true, "Split When Entering The Gift Shop", "Area" },
            { "1_finalChase", true, "Split When Entering The Final Chase", "Area" },
    };
	vars.Helper.Settings.Create(_settings);
}

init
{
    IntPtr gWorld = vars.Helper.ScanRel(10, "80 7C 24 ?? 00 ?? ?? 48 8B 3D ???????? 48");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
    IntPtr fNames = vars.Helper.ScanRel(7, "8B D9 74 ?? 48 8D 15 ?? ?? ?? ?? EB");

    if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero || fNames == IntPtr.Zero)
    {
        const string Msg = "Not all required addresses could be found by scanning.";
        throw new Exception(Msg);
    }

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
    // GWorld.OwningGameInstance.LocalPlayers[0].AcknowledgedPawn.IsPaused
    vars.Helper["Paused"] = vars.Helper.Make<bool>(gEngine, 0xD98, 0x38, 0x0, 0x30, 0x318, 0x6E1);
    // GWorld.OwningGameInstance.LocalPlayers[0].Character.CharacterMovement.Velocity.X/Y/Z
    vars.Helper["CharacterMovementX"] = vars.Helper.Make<float>(gEngine, 0xD98, 0x38, 0x0, 0x30, 0x2C8, 0x300, 0xC8);
    vars.Helper["CharacterMovementY"] = vars.Helper.Make<float>(gEngine, 0xD98, 0x38, 0x0, 0x30, 0x2C8, 0x300, 0xD0);
    // GWorld.OwningGameInstance.LocalPlayers[0].AcknowledgedPawn.IsCinematic
    vars.Helper["Cinematic"] = vars.Helper.Make<bool>(gEngine, 0xD98, 0x38, 0x0, 0x30, 0x318, 0x761);
    // GEngine.GameInstance.collectableList??
    // vars.Helper["Collectables"] = vars.Helper.Make<int>(gEngine, 0xD98, 0x278);

    // vars.CollctablesDP = new DeepPointer(gEngine, 0xD98, 0x278);

    vars.FNameToString = (Func<ulong, string>)(fName =>
    {
        var nameIdx = (fName & 0x000000000000FFFF) >> 0x00;
        var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
        var number = (fName & 0xFFFFFFFF00000000) >> 0x20;

        IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
        IntPtr entry = chunk + (int)nameIdx * sizeof(short);

        int length = vars.Helper.Read<short>(entry) >> 6;
        string name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + sizeof(short));

        return number == 0 ? name : name + "_" + number;
    });

    current.Area = "";
    current.CutsceneCount = 0;
    vars.CompletedSplits = new HashSet<string>();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") current.Area = world;
    if (old.Area != current.Area) vars.Log("Area: " + current.Area);
    if (old.Paused != current.Paused) vars.Log("Current Paused Is " + current.Paused);
    if (old.HiddenLoads != current.HiddenLoads) vars.Log("Hidden Loading = " + current.HiddenLoads);
    if (old.Cinematic != current.Cinematic) vars.Log("Cinematic: " + current.Cinematic);

    if (current.Area == "1_finalChase") {
        if (current.Cinematic && !old.Cinematic) {
            current.CutsceneCount = old.CutsceneCount + 1;
            vars.Log("Final map cutscene started! Total: " + current.CutsceneCount);
        } else {
            current.CutsceneCount = old.CutsceneCount;
        }
    } else {
        current.CutsceneCount = old.CutsceneCount;
    }

    if (current.Area != "1_finalChase") {
        current.CutsceneCount = 0;
    }
}

start
{
    return (current.CharacterMovementX > 0 || current.CharacterMovementY > 0); 
}

onStart
{
    vars.CompletedSplits.Clear();
}

isLoading
{
    return current.Area == "loadingScreen_MAP" || current.Paused || current.HiddenLoads;
}

reset
{
    return current.Area == "mainMenu_MAP";
}

split
{
    if (current.Area != old.Area && settings[current.Area] && !vars.CompletedSplits.Contains(current.Area))
    {
        vars.CompletedSplits.Add(current.Area);
        return true;
    }

    if (settings["skip"] && current.Area == "1_finalChase" && current.CutsceneCount == 5)
    {
        return true;
    }

    if (settings["skip2"] && current.Area == "1_finalChase" && current.CutsceneCount == 6)
    {
        return true;
    }
}
