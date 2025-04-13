/***************************************************
 * Marvel's Guardians of the Galaxy Autosplitter And Load Remover *
 * By Arkhamfan69, Tpredninja, kunodemetries *
 **************************************************/

state("gotg")
{
 int Chaptercount: 0x3DEE0B4; // Your Current Chapter
 int loading: 0x3DEDDDC; // 0 When Not Loading, 1 When Loading
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

isLoading
{
    return current.loading == 1;
}

reset
{
    if (current.Chaptercount < old.Chaptercount)
{
  return true;
}
}
