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
    // General Race Stats & Checks Pointer: 0x00426458
    // General Pointer to Info: 0x004A3F80
    // Player Status Pointer: 0x004A3150
    // Weeks Passed Pointer: 0x003E23C8
    // General Player Car Race Stats Pointer: 0x004C8A70
    vars.Screen             = vars.Helper.Make<uint>(0x004CB888);
    vars.Ranking            = vars.Helper.Make<short>(0x004A3F7C, 0x74, 0x15C);
    vars.Message            = vars.Helper.Make<byte>(0x0042A174, 0x18);
    vars.InRaceMode         = vars.Helper.Make<byte>(0x003B3D08);
    vars.ELMenuSelect       = vars.Helper.Make<byte>(0x004F2E40);
    vars.OButton            = vars.Helper.Make<byte>(0x00376F4D);
    vars.XButton            = vars.Helper.Make<byte>(0x00376F4E);
    vars.WheelButtons       = vars.Helper.Make<byte>(0x00378222);
    vars.PlayerRaceFinished = vars.Helper.Make<byte>(0x00426458, 0x19C, 0x1DF0);
    vars.CurrentRace        = vars.Helper.Make<float>(0x004A3F80, 0x2930);
    vars.PlayerStatus       = vars.Helper.Make<byte>(0x004A3150);
    vars.WeeksPassed        = vars.Helper.Make<int>(0x003E23C8);
    vars.MainMenuSelect     = vars.Helper.Make<byte>(0x00377714);
    
    // 0-Indexed
    vars.Position           = vars.Helper.Make<byte>(0x004C8A70, 0x178, 0x194C);

    // This is set when KotY is selected.
    vars.InKingOfTheYear    = false;
}

update {
    if (!vars.InKingOfTheYear && vars.CurrentRace.Current == 1660.0) {
        vars.Log("Entered King of the Year!");
    }

    vars.InKingOfTheYear = vars.InKingOfTheYear || vars.CurrentRace.Current == 1660.0;
}

start {
    if (vars.MainMenuSelect.Current == 0x06 && vars.ELMenuSelect.Current == 0x80 && ((vars.OButton.Current != 0 && vars.OButton.Old == 0)|| (vars.XButton.Current != 0 && vars.XButton.Old == 0) || ((vars.WheelButtons.Current & 1) != 0 && (vars.WheelButtons.Old & 1) == 0) || ((vars.WheelButtons.Current & 4) != 0 && (vars.WheelButtons.Old & 4) == 0))) {
        vars.Log("Started Timer for Any%!");
        return true;
    }

    return false;
}

split {
    if (vars.PlayerStatus.Old == 0x39 && vars.PlayerStatus.Current != 0x39 && vars.WeeksPassed.Current == 0 && vars.Splits.Add("Retire Week 1")) {
        vars.Log("Retired from Week 1");
        return true;
    }

    if (vars.PlayerStatus.Current == 0x4C && vars.PlayerStatus.Old != 0x4C && vars.WeeksPassed.Current > 0 && vars.Splits.Add("Skip")) {
        vars.Log("Skipped Weeks");
        return true;
    }

    if (vars.Screen.Current == 0xCE787) {
        // If you've made it into RIII, you've probably also completed the requirements to unlock RIV.
        // So we can also check if RIII has been split, and then split as well if so.
        if ((vars.Splits.Contains("RIII") || (vars.Message.Current == 0x13 && vars.Message.Old == 0x13)) && vars.Splits.Add("RIV")) {
            vars.Log("Unlocked RIV");
            return true;
        }

        if (vars.Message.Current != 0 && vars.Ranking.Current <= 800 && vars.Splits.Add("RIII")) {
            vars.Log("Reached RIII (Top 800)");
            return true;
        }

        if (vars.Message.Current != 0 && vars.Ranking.Current <= 500 && vars.Splits.Add("RII")) {
            vars.Log("Reached RII (Top 500)");
            return true;
        }
        
        if (vars.Message.Current != 0 && vars.Ranking.Current <= 300 && vars.Splits.Add("RI")) {
            vars.Log("Reached RI (Top 300)");
            return true;
        }
        
        if (vars.Message.Current != 0 && vars.Ranking.Current <= 50 && vars.Splits.Add("RS")) {
            vars.Log("Reached RS (Top 50)");
            return true;
        }
        
        if (vars.Message.Current != 0 && vars.Ranking.Current <= 6 && vars.Splits.Add("Top 6")) {
            vars.Log("Reached Top 6");
            return true;
        }

        return false;
    }

    if (vars.InKingOfTheYear && vars.PlayerRaceFinished.Current == 4 && vars.PlayerRaceFinished.Old != 4 && vars.Position.Current == 0 && vars.Splits.Add("KOTY")) {
        vars.Log("Won King of the Year");
        return true;
    }

    return false;
}

onStart {
    vars.Splits.Clear();
    vars.InKingOfTheYear = false;
}
