state("WDC")
{
    bool Circle: 0xFDA138;
    byte Menu: 0xF3386F;
}

isLoading
{
    return current.Circle;
}

start
{
    return current.Menu == 0 && old.Menu == 191;
}

update
{
    if (old.Circle != old.Circle) print("Current Loading Is: " + current.Circle);
}