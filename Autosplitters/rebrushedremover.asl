state("recolored-Win64-Shipping")
{
    byte loading: 0x0522E878, 0xE0, 0x60;
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
   {
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Game Time) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | Disney Epic Mickey: Rebrushed",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question
        );

        if (timingMessage == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

init // Code Tweaked Some From Clair Obscure: Expedition 33 Autosplitter By Nikoheart
{
    vars.ModsDetected = false;
	vars.gameModule = modules.First();
	vars.MickeyLocation = Path.GetFullPath(Path.Combine(vars.gameModule.FileName, @"../../../"));
	vars.paksFolder = Path.GetFullPath(Path.Combine(vars.MickeyLocation, @"Content\Paks\"));
	if (Directory.Exists(vars.paksFolder + @"~mods"))
	{
		var modsMessage = MessageBox.Show (
			"Disney Epic Mickey: Rebrushed speedruns requires no mods to be in use.\n"+
				"If you are seeing this message, it means that the '~mods' folder has been detected.\n"+
				"Make sure to remove this folder to stop seeing this message and ensure the validity of a legitimate speedrun.\n",
				"Mods Folder Detected",
			MessageBoxButtons.OK,MessageBoxIcon.Question
			);
		
			if (modsMessage == DialogResult.OK)
			{
				Application.Exit();
			}
	}

	if (Directory.Exists(vars.paksFolder + @"~mods"))
	{
		const string Msg = "Mods detected. Stopping ASL.";
		throw new Exception(Msg);
	}
}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}

onStart
{
	if (Directory.Exists(vars.paksFolder + @"~mods"))
	{
		var modsMessage = MessageBox.Show (
			"Disney Epic Mickey: Rebrushed speedruns requires no mods to be in use.\n"+
				"If you are seeing this message, it means that the '~mods' folder has been detected.\n"+
				"Make sure to remove the~mods folder to stop seeing this message and ensure the validity of a legitimate speedrun.\n",
				"Mods Folder Detected",
			MessageBoxButtons.OK,MessageBoxIcon.Question
			);
		
			if (modsMessage == DialogResult.OK)
			{
				Application.Exit();
			}
	}
	if (Directory.Exists(vars.paksFolder + @"~mods"))
	{
		vars.ModsDetected = true;
		const string Msg = "Mods detected. Stopping ASL.";
		throw new Exception(Msg);
	}
	timer.IsGameTimePaused = true;
}

isLoading
{
    return current.loading == 1 || current.loading == null;
}

start
{
    return current.loading == 1;
}
