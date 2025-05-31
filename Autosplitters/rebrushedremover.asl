state("recolored-Win64-Shipping")
{
    byte loading: 0x0522E878, 0xE0, 0x60; // Kept cause nothing I found via Helper blocks acted like this
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Disney Epic Mickey: Rebrushed";
    vars.Helper.Settings.CreateFromXml("Components/Rebrushed.Settings.xml");
    vars.Helper.AlertLoadless();   
    vars.TimerModel = new TimerModel { CurrentState = timer };
}

init
{
	vars.NewGamePlus = false;
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

    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
    IntPtr gEngine = vars.Helper.ScanRel(3, "48 8B 0D ???????? 66 0F 5A C9 E8");
    IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 05 ???????? eb ?? 48 8d 0d ???????? e8 ???????? c6 05");

	if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero || fNames == IntPtr.Zero)
	{
		const string Msg = "Not all required addresses could be found by scanning.";
		throw new Exception(Msg);
	}

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
	vars.Helper["NewGamePlus"] = vars.Helper.Make<bool>(gEngine, 0x10A8, 0xA98);

    vars.GetCutsceneName = (Func<ulong, string>)(sequencePlayer =>
	{
		if (sequencePlayer != 0)
		{
			ulong resolveHookPointer = memory.ReadValue<ulong>((IntPtr)(sequencePlayer));

			if (resolveHookPointer != 0)
			{
				bool cutscenePlaying = memory.ReadValue<bool>((IntPtr)(resolveHookPointer + 0x2B0));

				if (cutscenePlaying)
				{
					ulong sequence = memory.ReadValue<ulong>((IntPtr)(resolveHookPointer + 0x2B8));
					if (sequence != 0)
					{
						ulong sequencePrivate = memory.ReadValue<ulong>((IntPtr)(sequence + 0x18));
						if (sequencePrivate != 0)
						{
							vars.cutscenePlaying = cutscenePlaying;
							return (vars.FNameToString((ulong)(sequencePrivate)));
						}
					}
				}
			}
		}

		vars.cutscenePlaying = false;
		return "";
	});

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

	vars.FNameToShortString = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int dot = name.LastIndexOf('.');
		int slash = name.LastIndexOf('/');

		return name.Substring(Math.Max(dot, slash) + 1);
	});

	current.World = "";
    vars.CutscenesWatched = new HashSet<string>();
	vars.DoneAreas = new HashSet<string>();

	current.Cutscene = ""; old.Cutscene = "";
	vars.sequencePlayer = 0; vars.cutscenePlaying = false;
	vars.sequencePlayerFunction = vars.Helper.Scan("recolored-Win64-Shipping.exe", 0xC, "48 8B C8 E8 ?? ?? ?? ?? 0F 10 45 D7");

	if (vars.sequencePlayerFunction != IntPtr.Zero)
	{
		byte[] gutBytes = { 0x49, 0x8B, 0x06, 0x4C, 0x8D, 0x4D, 0x77, 0x0F, 0x10, 0x4D, 0xE7, 0x48, 0x8D, 0x55, 0xA7 };
		byte[] gutBytesInjected = { 0xFF, 0x25, 0x00, 0x00, 0x00, 0x00 };

		byte[] foundBytes = memory.ReadBytes((IntPtr)vars.sequencePlayerFunction, 0x0F);
		byte[] foundBytesInjected = memory.ReadBytes((IntPtr)vars.sequencePlayerFunction, 0x06);

		if (gutBytes.SequenceEqual(foundBytes))
		{
			vars.allocatedMemory = memory.AllocateMemory(0x200);

			if (vars.allocatedMemory != IntPtr.Zero)
			{
				vars.sequencePlayer = vars.allocatedMemory + 0x100;

				byte[] s1 = { 0xFF, 0x25, 0x00, 0x00, 0x00, 0x00 };
				byte[] s2 = BitConverter.GetBytes((ulong)vars.allocatedMemory);
				byte[] s3 = { 0x90 };
				byte[] start = s1.Concat(s2).Concat(s3).ToArray();

				byte[] e1 = { 0x4C, 0x89, 0x35 };
				byte[] e2 = BitConverter.GetBytes((int)0xF9);
				byte[] e3 = gutBytes;
				byte[] e4 = { 0xFF, 0x25, 0x00, 0x00, 0x00, 0x00 };
				byte[] e5 = BitConverter.GetBytes((ulong)vars.sequencePlayerFunction + 0x0F);
				byte[] end = e1.Concat(e2).Concat(e3).Concat(e4).Concat(e5).ToArray(); ;

				memory.WriteBytes((IntPtr)vars.allocatedMemory, end);
				memory.WriteBytes((IntPtr)vars.sequencePlayerFunction, start);
			}
		}
		else if (gutBytesInjected.SequenceEqual(foundBytesInjected))
			vars.sequencePlayer = memory.ReadValue<ulong>((IntPtr)(vars.sequencePlayerFunction + 0x6)) + 0x100;
	}

}

update
{
	vars.Helper.Update();
	vars.Helper.MapPointers();

	if (vars.ModsDetected) vars.TimerModel.Reset();

	var world = vars.FNameToString(current.GWorldName);
	if (!string.IsNullOrEmpty(world) && world != "None")
		current.World = world;
	if (old.World != current.World) vars.Log("Current Map Is: " + current.World);

	string checkName = vars.GetCutsceneName((ulong)(vars.sequencePlayer));
	if (checkName != "") current.Cutscene = checkName;

	if (old.Cutscene != current.Cutscene)
		vars.Log("Cutscene: " + old.Cutscene + " -> " + current.Cutscene);

    if (old.NewGamePlus != current.NewGamePlus)
        vars.Log("NG+ Changed: " + old.NewGamePlus + " -> " + current.NewGamePlus);

	if (old.World == "BTB_ITB_P" && current.World == "MainMenu")
	{
		vars.NewGamePlus = true;
		vars.Log("NG+ = True");
	}
}


isLoading
{
    return current.loading == 1 || current.World == "MainMenu" || current.World == "Intro_P";
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

    vars.CutscenesWatched.Clear();
	vars.DoneAreas.Clear();
	vars.NewGamePlus = false;

	vars.Log("NG+ State at start: " + current.NewGamePlus);
}


start
{
    return current.World == "DarkBeautyCastle_P" && old.World == "MainMenu";
}

split
{
    if (vars.NewGamePlus = false && current.World != old.World && settings[current.World] && !vars.DoneAreas.Contains(current.World))
    {
        vars.DoneAreas.Add(current.World);
        return true;
    }

	else if (vars.NewGamePlus = true && current.World != old.World && settings[current.World] && !vars.DoneAreas.Contains(current.World))
	{
		vars.DoneAreas.Add(current.World);
		return true;
	}

    if (vars.NewGamePlus = false && current.Cutscene != old.Cutscene && settings[current.Cutscene] && !vars.CutscenesWatched.Contains(current.Cutscene))
    {
        vars.CutscenesWatched.Add(current.Cutscene);
        return true;
    }

	else if (vars.NewGamePlus = true && current.Cutscene != old.Cutscene && settings[current.Cutscene] && !vars.CutscenesWatched.Contains(current.Cutscene))
	{
		vars.CutscenesWatched.Add(current.Cutscene);
		return true;
	}

	if (settings["ng+"] && current.World == "DarkBeautyCastle_P" && old.World == "MainMenu")
	{
		vars.NewGamePlus = true;
		vars.Log("NG+ = True");
		return true;
	}

	if (settings["Ng+f"] && current.World == "BTB1_TSB_P" && old.World == "BTB_YOD_P" && vars.NewGamePlus == true && current.Cutscene == "LS_TSB_ShadowBlotDefeatedThinner_2_2")
{
    return true;
}
}

exit
{
    //pauses timer if the game crashes
    timer.IsGameTimePaused = true;
}
