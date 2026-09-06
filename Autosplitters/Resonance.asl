state("Resonance")
{
    bool Loading: "Resonance.exe", 0x440B870;
    bool Paused: "Resonance.exe", 0x440AB33;
    int Chapter: "Resonance.exe", 0x406EE84;
    float Xpos: "Resonance.exe", 0x03461828, 0x38, 0x528, 0x1F8, 0x30;
    float Ypos: "Resonance.exe", 0x03461828, 0x38, 0x528, 0x1F8, 0x34;
    float Zpos: "Resonance.exe", 0x03461828, 0x38, 0x528, 0x1F8, 0x38;
}

startup
{
    settings.Add("startChapter3", false, "Start on Chapter 3 (No Intro)");
    settings.Add("chapters", true, "Chapter Splits");
    settings.Add("chapter2", true, "Split on Chapter 2", "chapters");
    settings.Add("chapter3", true, "Split on Chapter 3", "chapters");
    settings.Add("chapter4", true, "Split on Chapter 4", "chapters");
    settings.Add("chapter5", true, "Split on Chapter 5", "chapters");
    settings.Add("chapter6", true, "Split on Chapter 6", "chapters");
    settings.Add("chapter7", true, "Split on Chapter 7", "chapters");
    settings.Add("chapter8", true, "Split on Chapter 8", "chapters");
    settings.Add("chapter9", true, "Split on Chapter 9", "chapters");
    settings.Add("chapter10", true, "Split on Chapter 10", "chapters");
    settings.Add("chapter11", true, "Split on Chapter 11", "chapters");
    settings.Add("chapter12", true, "Split on Chapter 12", "chapters");
    settings.Add("chapter13", true, "Split on Chapter 13", "chapters");
    settings.Add("chapter14", true, "Split on Chapter 14", "chapters");

    settings.Add("text", true, "Display Game Information");
    settings.Add("showPosition", true, "Show Position", "text");
    settings.Add("showSpeed", true, "Show Speed", "text");

    vars.CompletedChapters = new HashSet<int>();
    vars.TextComponents = new Dictionary<string, LiveSplit.UI.Components.ILayoutComponent>();

    vars.SetTextComponent = (Action<string, string>)((text1, text2) =>
    {
        LiveSplit.UI.Components.ILayoutComponent layoutComponent;

        if (!vars.TextComponents.TryGetValue(text1, out layoutComponent))
        {
            layoutComponent = timer.Layout.LayoutComponents
                .FirstOrDefault(component =>
                {
                    if (!component.Path.EndsWith("LiveSplit.Text.dll"))
                        return false;

                    var settingsProperty = component.Component.GetType()
                        .GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public);
                    var componentSettings = settingsProperty.GetValue(component.Component, null);
                    var textProperty = componentSettings.GetType().GetProperty("Text1");
                    return (string)textProperty.GetValue(componentSettings, null) == text1;
                });

            if (layoutComponent == null)
            {
                var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
                var textComponent = Activator.CreateInstance(
                    textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);

                layoutComponent = new LiveSplit.UI.Components.LayoutComponent(
                    "LiveSplit.Text.dll",
                    textComponent as LiveSplit.UI.Components.IComponent);
                timer.Layout.LayoutComponents.Add(layoutComponent);
            }

            vars.TextComponents.Add(text1, layoutComponent);
        }

        var textSettings = layoutComponent.Component.GetType()
            .GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public)
            .GetValue(layoutComponent.Component, null);
        textSettings.GetType().GetProperty("Text1").SetValue(textSettings, text1, null);
        textSettings.GetType().GetProperty("Text2").SetValue(textSettings, text2, null);
    });

    vars.RemoveTextComponent = (Action<string>)(text1 =>
    {
        LiveSplit.UI.Components.ILayoutComponent layoutComponent;

        if (vars.TextComponents.TryGetValue(text1, out layoutComponent))
        {
            timer.Layout.LayoutComponents.Remove(layoutComponent);
            vars.TextComponents.Remove(text1);
        }
    });

    vars.PreviousX = 0.0;
    vars.PreviousY = 0.0;
    vars.PreviousZ = 0.0;
    vars.PreviousTime = DateTime.UtcNow;
    vars.HasPreviousPosition = false;
    vars.Speed = 0.0;
    vars.SmoothedSpeed = 0.0;
    vars.DisplaySpeed = 0.0;
    vars.LastSpeedDisplay = DateTime.UtcNow;
}

onStart
{
    vars.CompletedChapters.Clear();
}

update
{
    DateTime currentTime = DateTime.UtcNow;
    vars.Speed = 0.0;

    if (vars.HasPreviousPosition)
    {
        double elapsed = (currentTime - vars.PreviousTime).TotalSeconds;

        if (elapsed > 0)
        {
            double deltaX = current.Xpos - vars.PreviousX;
            double deltaY = current.Ypos - vars.PreviousY;
            double deltaZ = current.Zpos - vars.PreviousZ;

            vars.Speed = Math.Sqrt(
                deltaX * deltaX +
                deltaY * deltaY +
                deltaZ * deltaZ) / elapsed;

            double smoothing = 1.0 - Math.Exp(-elapsed / 0.25);
            vars.SmoothedSpeed += (vars.Speed - vars.SmoothedSpeed) * smoothing;
        }
    }

    if (settings["showPosition"])
    {
        vars.SetTextComponent(
            "Position",
            "X: " + current.Xpos.ToString("F2")
                + " | Y: " + current.Ypos.ToString("F2")
                + " | Z: " + current.Zpos.ToString("F2"));
    }
    else
    {
        vars.RemoveTextComponent("Position");
    }

    if (settings["showSpeed"])
    {
        if ((currentTime - vars.LastSpeedDisplay).TotalSeconds >= 0.10)
        {
            vars.DisplaySpeed = vars.SmoothedSpeed;
            vars.LastSpeedDisplay = currentTime;
        }

        vars.SetTextComponent("Speed", vars.DisplaySpeed.ToString("F2"));
    }
    else
    {
        vars.RemoveTextComponent("Speed");
    }

    if (current.Chapter != old.Chapter)
    {
        print("Chapter changed from " + old.Chapter + " to " + current.Chapter);
    }

    vars.PreviousX = current.Xpos;
    vars.PreviousY = current.Ypos;
    vars.PreviousZ = current.Zpos;
    vars.PreviousTime = currentTime;
    vars.HasPreviousPosition = true;
}

start
{
    if (settings["startChapter3"])
        return current.Chapter >= 3 && old.Chapter < 3;

    return current.Chapter >= 1 && old.Chapter < 1;
}

isLoading
{
    return current.Paused || current.Loading;
}

split
{
    return current.Chapter > old.Chapter
        && current.Chapter >= 2
        && current.Chapter <= 14
    && settings["chapter" + current.Chapter]
    && vars.CompletedChapters.Add(current.Chapter);
}

exit
{
    foreach (var layoutComponent in vars.TextComponents.Values)
        timer.Layout.LayoutComponents.Remove(layoutComponent);

    vars.TextComponents.Clear();
}
