state("Hotel188DEMO-Win64-Shipping") // May eventutally add support for the full game.
{

}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Hotel 188";

    settings.Add("Item", false, "Item Splits");
        settings.Add("Flash", false, "Obtained Flashlight", "Item");

    var demoMessage = MessageBox.Show(
        "Thank you for using the Hotel 188 Autosplitter!\n" +
        "This autosplitter is designed for the DEMO version of the game.\n" +
        "If you are using the full version, please note that for the time being, this autosplitter will not work for the full game.\n",
        "LiveSplit | Hotel 188",
        MessageBoxButtons.OK, MessageBoxIcon.Information);
}

init
{
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
    IntPtr fNames = vars.Helper.ScanRel(7, "8B D9 74 ?? 48 8D 15 ?? ?? ?? ?? EB");

    if (gEngine == IntPtr.Zero || fNames == IntPtr.Zero)
    {
        const string Msg = "Not all required addresses could be found by scanning.";
        throw new Exception(Msg);
    }

    // GEngine.TransitionType
    vars.Helper["Paused"] = vars.Helper.Make<bool>(gEngine, 0xBBB);
    // GEngine.GameInstace.LocalPlayer[0].PlayerController.Character.CapsuleComponent.RelativeLocation
    vars.Helper["PlayerPosition"] = vars.Helper.Make<Vector3f>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x2E0, 0x328, 0x128);
    // GEngine.GameInstance.LocalPlayer[0].PlayerController.AcknowledgedPawn.HasFlashlight
    vars.Helper["HasFlash"] = vars.Helper.Make<bool>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x338, 0x74C);

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

    vars.CompletedSplits = new HashSet<string>();
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    // Uncomment debug information in the event of an update.
	// print(modules.First().ModuleMemorySize.ToString());

    if (old.Paused != current.Paused) vars.Log("Current Paused Is " + current.Paused);
}

start
{
    return current.PlayerPosition.X != old.PlayerPosition.X;
}

split
{
    if (settings["Flash"] && old.HasFlash != current.HasFlash && current.HasFlash)
    {
        return true;
    }
}

isLoading
{
    return current.Paused;
}

exit
{
    timer.IsGameTimePaused = true;
}

// Demo - 142016512
