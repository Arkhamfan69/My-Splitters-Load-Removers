// Credits
// Nikoheart - Splitting Logic (Huge Thanks)
// Arkhamfan69 - Everything Else
state("TheFirstTree")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "The First Tree";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
}

start
{
    return current.Scene == "Level1" && old.Scene == "Loading";
}

split
{
    return current.Scene != "Loading" && current.Scene != old.Scene;
}

isLoading
{
    return current.Scene == "Loading";
}

reset
{
    return current.Scene == "Title";
}

update
{
     current.Scene = vars.Helper.Scenes.Active.Name ?? current.Scene;
}
