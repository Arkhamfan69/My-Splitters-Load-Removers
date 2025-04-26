/***************************************************
 * Marvel's Guardians of the Galaxy Autosplitter And Load Remover *
 * By Arkhamfan69, Tpredninja, kunodemetries *
 **************************************************/

state("gotg", "Epic")
{
    int Chaptercount: 0x3DEE0B4; 
    int Interactable: 0x3DE74C8; // 4 for everything 7 when putting down the interactable may need to test further
    int Credits: 0x3DFAAF4; // 0 when not in credits, 1 when in credits
    int loading: 0x3DEDDDC; // 0 When Not Loading, 1 When Loading
    /*
    int testaddress: 3E044F8 //same as steam but its like minus 10 or something idk why its weird probably wont use
    */
}

state("gotg", "Steam")
{
    int Chaptercount: 0x3DD9374; // -1 when in main menu 0 when in prologue 1 and so on for all the other chapters
    int Interactable: 0x3DD2788; // 4 for everything 7 when putting down the interactable may need to test further
    int Credits: 0x3DE5DB4; // 0 when not in credits, 1 when in credits
    int loading: 0x3DD9004; // 0 When Not Loading, 1 When Loading
    /* extra loading addresses for steam version
    0x3D5CE48
    0x3DA6E34
    0x3DCA9A8
    0x3DCF9F8
    0x3DD9094
    0x3DD909C
    0x3DD90AC
    */
    //int testaddress: 0x3DE5DB4; //its a different number at different places could be useful to split on stuff other than just chapter changes
}

init
{
    string MD5Hash;
    using (var md5 = System.Security.Cryptography.MD5.Create())
    using (var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
    MD5Hash = md5.ComputeHash(s).Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
    print("Hash is: " + MD5Hash);

    switch (MD5Hash)
            {
                case "7C476C9C20CA03F7B66754082A83999C":
                    version = "Epic";
                    break;

                case "94717F256E87479C3D0643A3B0FBA6F1":
                    version = "Steam";
                    break;

                default:
                    version = "Unknown";
                    break;
            }
}

startup
{
    {        
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Loadless) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Loadless?",
            "LiveSplit | Marvel's Guardians of the Galaxy",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question
        );
        
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }

    settings.Add("Promise", true, "Promise%");
    settings.SetToolTip("Promise", "Enable to autoend the timer in promise%");
}

start
{
    if (current.Interactable == 7 && old.Interactable == 4)
    {
        timer.Run.Offset = TimeSpan.FromSeconds(2.32);
        return true;
    }
}

split
{
    //normal chapter splits
    if (current.Chaptercount > old.Chaptercount) {
        return true;
    }

    //promise % split
    if(current.Chaptercount == 8 && current.Interactable == 4 && current.Credits == 0 && old.Credits == 1 && settings["Promise"] )
    {
        print("Promise % Split Triggered");
        return true;
    } else if (current.Chaptercount == 16 && current.Credits == 0 && old.Credits == 1 && !settings["Promise"])
    {
        print("full game split triggered");
        return true;
    }
}

reset
{
    if (current.Chaptercount < old.Chaptercount) {
        return true;
   }
}

isLoading
{
    return current.loading == 1;
}
