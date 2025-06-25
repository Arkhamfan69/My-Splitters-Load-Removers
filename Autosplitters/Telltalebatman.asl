state("Batman", "First Game")
{
    bool loading: 0xF4544D;
    int episode: 0xEEC088;
    int Menu: 0xEC4988; // 13 in Menu random numbers else where
}

state("Batman2", "Sequel")
{
    bool loading: 0xF4325D;
    int episode: 0x00EF8B90, 0xC0, 0x30, 0x10, 0xA0, 0x8, 0xB8, 0xE48;
    int Menu: 0xE31CC8;
}

startup
{
    settings.Add("Reset", false, "Reset When Going To The Main Menu (Only Trigger For ILS)");
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

init
{
{
    string MD5Hash;
    using (var md5 = System.Security.Cryptography.MD5.Create())
    using (var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
    MD5Hash = md5.ComputeHash(s).Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
    print("Hash is: " + MD5Hash);

    switch (MD5Hash)
        {
            case "E3912BC333CA9355585DA3DB6A05FCB3":
                version = "Sequel";
                break;
            
            case "2A215128B765B3D5B7487E8538A13670":
                version = "First Game";
                break;
        }

    vars.CompletedEpisdoes = new HashSet<int>();
}
}

onStart
{
    vars.CompletedEpisdoes.Clear();
}

start
{
    // Start when loading ends and any episode is active
   if (old.loading && !current.loading && current.episode > 0 && old.Menu == 13)
   {
        return true;
   }
}

split
{
    if (current.episode > 0
        && current.episode != old.episode
        && !vars.CompletedEpisdoes.Contains(current.episode))
    {
        vars.CompletedEpisdoes.Add(current.episode);
        return true;
    }
}

isLoading
{
    return current.loading || current.Menu == 13;
}

reset
{
    if (current.Menu == 13 && old.Menu != 13)
    {
        return settings["Reset"];
    }
}

exit
{
    timer.IsGameTimePaused = true;
}

update
{
    if (old.episode != current.episode) print("Current Episode Is: " + current.episode);
}
