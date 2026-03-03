state("DEM2") 
{
}

startup
{
    vars.Log = (Action<object>)((output) => print("[Epic Mickey 2 ASL] " + output));

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {        
        var timingMessage = MessageBox.Show(
            "This game uses Time without Loads (Game Time) as the main timing method.\n" +
            "LiveSplit is currently set to show Real Time (RTA).\n" +
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | Disney Epic Mickey 2: The Power of Two!",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question
        );
        
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

init
{
    vars.Watchers = new MemoryWatcherList
    {
        new MemoryWatcher<int>(new DeepPointer(0xFBF2B4)) { Name = "InMenu" },
        new MemoryWatcher<bool>(new DeepPointer(0x103ACC0)) { Name = "Loading" }
    };
}

update
{
    if (vars.Watchers != null)
    {
        vars.Watchers.UpdateAll(game);
    }

    // vars.Log("InMenu: " + vars.Watchers["InMenu"].Current);
    // vars.Log("Loading: " + vars.Watchers["Loading"].Current);
}

start
{
    if (vars.Watchers != null)
    {
        return vars.Watchers["InMenu"].Old == 171 &&
               vars.Watchers["InMenu"].Current != 171;
    }
}

exit
{
    timer.IsGameTimePaused = true;
}

isLoading
{
    return vars.Watchers["Loading"].Current;
}
