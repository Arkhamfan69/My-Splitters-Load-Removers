state("DEM2") 
{
    bool Loading: 0x103ACC0;
    int InMenu: 0xFBF2B4;
}

start
{
    return old.InMenu == 171 && current.InMenu != 171;
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