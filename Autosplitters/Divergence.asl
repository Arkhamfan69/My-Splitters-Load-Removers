state("Divergence-Win64-Shipping") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Divergence";
}

init
{
    IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 05 ???????? eb ?? 48 8d 0d ???????? e8 ???????? c6 05");
    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 8B 0D ???????? 66 0F 5A C9 E8");

    if ( fNames == IntPtr.Zero || gWorld == IntPtr.Zero || gEngine == IntPtr.Zero)
    {
        throw new InvalidOperationException("Not all signatures resolved.");
    }

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
    // GEngine.TransitionType
    vars.Helper["Paused"] = vars.Helper.Make<bool>(gEngine, 0x8A8);
    // GEngine.GameInstance.LocalPlayers[0].PlayerController.PauseMenuRef.currentlyMainMenu
    vars.Helper["InMenu"] = vars.Helper.Make<bool>(gEngine, 0xDE8, 0x38, 0x0, 0x30, 0x5F0, 0x6C8);

    vars.CutscenePlaying = false;
    current.Paused = false;
    current.InMenu = false;
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    if (old.InMenu == true && current.InMenu == false)
    {
        vars.CutscenePlaying = true;
    }

    if (current.InMenu == true && current.Paused == true)
    {
        vars.CutscenePlaying = false;
    }

    if (old.Paused != current.Paused)
    {
        vars.Log("Paused: " + current.Paused);
    }

    if (old.InMenu != current.InMenu)
    {
        vars.Log("InMenu: " + current.InMenu);
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

start
{
    return vars.CutscenePlaying;
}

reset
{
   if (current.InMenu)
   {
        return true;
   }

   else if (vars.CutscenePlaying = false)
   {
        return false;
   }
}