/***************************************************
 * Marvel's Guardians of the Galaxy Autosplitter And Load Remover *
 * By Arkhamfan69, Tpredninja, kunodemetries *
 **************************************************/

state("gotg", "Epic")
{
    int Chaptercount: 0x3DEE0B4; 
    int loading: 0x3DEDDDC; // 0 When Not Loading, 1 When Loading
}

state("gotg", "Steam") // Steam Version Done By tpredninja
{
    int Chaptercount: 0x3DD9374; // -1 when in main menu 0 when in prologue 1 and so on for all the other chapters
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
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
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
}

split
{
    if (current.Chaptercount > old.Chaptercount) {
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
