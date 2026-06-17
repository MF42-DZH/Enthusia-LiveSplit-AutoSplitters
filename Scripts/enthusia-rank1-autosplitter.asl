state("PCSX2-qt") { }

startup {
    Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).CreateInstance("PS2");

    vars.Log = (Action<object>) (output => print("[Enthusia: Professional Racing] " + output));
    vars.Splits = new HashSet<string>();

    // Pointer Sources: https://retroachievements.org/codenotes.php?g=21944
    // ASL code: Azullia
    // Pointer & Value Sources: xp
    // Base Pointer to EL Records: 0x004A3F7C
    // Base Pointer to Current Screen: 0x004CB888
    // Base Pointer to Display Data: 0x0042A174
    // Pointer to InRaceMode: 0x003B3D08
    // Pointer to New Game/Continue Press: 0x004F2E40
    // Value for Week Data Update Screen: 0xCE787
    // Value for RIV message: 0x13
    // Pointer to last selected menu value: 0x00377714
    // Value for main menu EL selected: 0x06
    // Pointer to X controller byte: 0x00376F4E
    // Pointer to O controller byte: 0x00376F4D
    vars.Screen         = vars.Helper.Make<uint>(0x004CB888);
    vars.Ranking        = vars.Helper.Make<short>(0x004A3F7C, 0x74, 0x15C);
    vars.Message        = vars.Helper.Make<byte>(0x0042A174, 0x18);
    vars.InRaceMode     = vars.Helper.Make<byte>(0x003B3D08);
    vars.ELMenuSelect   = vars.Helper.Make<byte>(0x004F2E40);
    vars.MainMenuSelect = vars.Helper.Make<byte>(0x00377714);
    vars.OButton        = vars.Helper.Make<byte>(0x00376F4D);
    vars.XButton        = vars.Helper.Make<byte>(0x00376F4E);
    vars.WheelButtons   = vars.Helper.Make<byte>(0x00378222);
}

update { }

start {
    if (vars.MainMenuSelect.Current == 0x06 && vars.ELMenuSelect.Current == 0x01 && ((vars.OButton.Current != 0 && vars.OButton.Old == 0)|| (vars.XButton.Current != 0 && vars.XButton.Old == 0) || ((vars.WheelButtons.Current & 1) != 0 && (vars.WheelButtons.Old & 1) == 0) || ((vars.WheelButtons.Current & 4) != 0 && (vars.WheelButtons.Old & 4) == 0))) {
        vars.Log("Started Timer for Rank 1!");
        return true;
    }

    return false;
}

split {
    if (vars.Screen.Current != 0xCE787) return false;

    // If you've made it into RIII, you've probably also completed the requirements to unlock RIV.
    // So we can also check if RIII has been split, and then split as well if so.
    if ((vars.Splits.Contains("RIII") || (vars.Message.Current == 0x13 && vars.Message.Old == 0x13)) && vars.Splits.Add("RIV")) {
        vars.Log("Unlocked RIV");
        return true;
    }

    if (vars.Message.Current != 0 && vars.Message.Old != 0 && vars.Ranking.Current <= 800 && vars.Ranking.Old <= 800 && vars.Splits.Add("RIII")) {
        vars.Log("Reached RIII (Top 800)");
        return true;
    }

    if (vars.Message.Current != 0 && vars.Message.Old != 0 && vars.Ranking.Current <= 500 && vars.Ranking.Old <= 500 && vars.Splits.Add("RII")) {
        vars.Log("Reached RII (Top 500)");
        return true;
    }

    if (vars.Message.Current != 0 && vars.Message.Old != 0 && vars.Ranking.Current <= 300 && vars.Ranking.Old <= 300 && vars.Splits.Add("RI")) {
        vars.Log("Reached RI (Top 300)");
        return true;
    }

    if (vars.Message.Current != 0 && vars.Message.Old != 0 && vars.Ranking.Current <= 50 && vars.Ranking.Old <= 50 && vars.Splits.Add("RS")) {
        vars.Log("Reached RS (Top 50)");
        return true;
    }

    if (vars.Message.Current != 0 && vars.Message.Old != 0 && vars.Ranking.Current <= 1 && vars.Ranking.Old <= 1 && vars.Splits.Add("Rank 1")) {
        vars.Log("Reached Rank 1");
        return true;
    }

    return false;
}

onStart {
    vars.Splits.Clear();
}
