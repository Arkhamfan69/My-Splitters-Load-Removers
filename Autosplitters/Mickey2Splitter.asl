state("DEM2") 
{
    bool Loading: 0x103ACC0;
    int InMenu: 0xFBF2B4;
}

init
{
    vars.ModsDetected = false;
	vars.gameModule = modules.First();
	vars.Em2Location = Path.GetFullPath(Path.Combine(vars.gameModule.FileName, @"../../../"));
	vars.paksFolder = Path.GetFullPath(Path.Combine(vars.Em2Location, @"Content\Paks\"));
	if (Directory.Exists(vars.paksFolder + @"~mods"))
	{
		var modsMessage = MessageBox.Show (
			"Epic Mickey 2 speedruns requires no mods to be in use.\n"+
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
}

onStart
{
    {
	if (Directory.Exists(vars.paksFolder + @"~mods"))
	{
		var modsMessage = MessageBox.Show (
			"Epic Mickey 2 speedruns requires no mods to be in use.\n"+
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
}

start
{
    return old.InMenu == 171 && current.InMenu != 171;
}

exit
{
    timer.IsGameTimePaused = true;
}

isLoading
{
    return current.Loading;
}

update
{
    if (current.Loading != old.Loading )
        print("Current Loading Is: " + current.Loading);
}
