state("Batman")
{
    bool loading: 0xF4544D;
    int episode: 0xEEC088;
}

state("Batman2")
{
    bool loading: 0xF4325D;
}

startup
{
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {        
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Loadless) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Loadless?",
            "LiveSplit | Batman: The Telltale Series",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question
        );
        
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}
}

split
{
    return current.episode != old.episode && current.episode >= 1 && current.episode <= 5;
}

isLoading
{
    return current.loading;
}
