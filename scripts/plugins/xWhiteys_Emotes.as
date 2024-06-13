array<CScheduledFunction@> g_dict_lpfnLoops(33);

void PluginInit() {
    g_Module.ScriptInfo.SetAuthor("wootguy feat. xWhitey");
    g_Module.ScriptInfo.SetContactInfo("@tyabus at Discord");
    
    Emotes_LoadPredefinedNamedEmotes();
}

float fabsf(float _Value) {
    return _Value < 0.f ? _Value * -1.f : _Value;
}

enum EEmoteMode {
    kModeOnce, // play once
    kModeFreeze, // freeze on the last frame
    kModeLoop, // loop betwen start and end frames
    kModeLoopGoBackwards // invert framerate when reaching the start/end frame (basically makes the emote go back from last frame)
}

class CEmotePart {
    int m_iSequence;
    EEmoteMode m_eEmoteMode;
    float m_flFramerate;
    float m_flStartFrame;
    float m_flEndFrame;
    
    bool m_bIgnoreMovements;
    
    CEmotePart() {}
    
    CEmotePart(int _Sequence, EEmoteMode _Mode, float _Framerate, float _StartFrame, float _EndFrame, bool _IgnoreMovements = false) {
        m_iSequence = _Sequence;
        m_eEmoteMode = _Mode;
        m_flFramerate = _Framerate;
        m_flStartFrame = _StartFrame;
        m_flEndFrame = _EndFrame;
        
        m_bIgnoreMovements = _IgnoreMovements;
        
        if (m_flFramerate == 0) {
            m_flFramerate = 0.0000001f;
        }
        if (m_flStartFrame <= 0) {
            m_flStartFrame = 0.00001f;
        }
        if (m_flStartFrame >= 255) {
            m_flStartFrame = 254.9999f;
        }
        if (m_flEndFrame <= 0) {
            m_flEndFrame = 0.00001f;
        }
        if (m_flEndFrame >= 255) {
            m_flEndFrame = 254.9999f;
        }
    }
}

enum EEmoteType {
    kTypeDefault = 0,
    kChainLoop,
    kChainLoopingBackwards,
    kChainLoopBackwardsOnce,
    kChainLoopingSequenceBackwards
}

class CEmote {
    array<CEmotePart@> m_aParts;
    EEmoteType m_eType;
    bool m_bLoopingBack;
    
    CEmote() {}
    
    CEmote(array<CEmotePart@> _Parts, EEmoteType _Type) {
        m_aParts = _Parts;
        m_eType = _Type;
        m_bLoopingBack = false;
    }
}

dictionary g_dictEmotes;

void Emotes_LoadPredefinedNamedEmotes() {
    g_dictEmotes["alpha"] = CEmote({
        CEmotePart(187, kModeFreeze, 1.45, 180, 236)
    }, kTypeDefault);
    g_dictEmotes["scan"] = CEmote({
        CEmotePart(188, kModeOnce, 1.0, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["flex"] = CEmote({
        CEmotePart(129, kModeFreeze, 0.2, 0, 52)
    }, kTypeDefault);
    g_dictEmotes["lewd"] = CEmote({
        CEmotePart(88, kModeLoopGoBackwards, 1, 40, 70)
    }, kTypeDefault);
    g_dictEmotes["robot"] = CEmote({
        CEmotePart(71, kModeFreeze, 1, 0, 100)
    }, kTypeDefault);
    g_dictEmotes["elbow"] = CEmote({
        CEmotePart(35, kModeFreeze, 1, 135, 135)
    }, kTypeDefault);
    g_dictEmotes["hunch"] = CEmote({
        CEmotePart(16, kModeFreeze, 1, 40, 98)
    }, kTypeDefault);
    g_dictEmotes["anal"] = CEmote({
        CEmotePart(14, kModeFreeze, 1, 0, 120)
    }, kTypeDefault);
    g_dictEmotes["joy"] = CEmote({
        CEmotePart(9, kModeFreeze, 1, 90, 90)
    }, kTypeDefault);
    g_dictEmotes["wave"] = CEmote({
        CEmotePart(190, kModeOnce, 1.0, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["type"] = CEmote({
        CEmotePart(186, kModeLoop, 1, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["type2"] = CEmote({
        CEmotePart(187, kModeLoop, 1.2, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["study"] = CEmote({
        CEmotePart(189, kModeOnce, 1, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["oof"] = CEmote({
        CEmotePart(13, kModeOnce, 1, 0, 255),
        CEmotePart(14, kModeOnce, -1, 255, 0)
    }, kTypeDefault);
    g_dictEmotes["dance"] = CEmote({
        CEmotePart(31, kModeLoopGoBackwards, 1, 35, 255)
    }, kTypeDefault);
    g_dictEmotes["dance2"] = CEmote({
        CEmotePart(71, kModeLoopGoBackwards, 1, 0, 220)
    }, kTypeDefault);
    g_dictEmotes["shake"] = CEmote({
        CEmotePart(106, kModeFreeze, 1, 0, 0)
    }, kTypeDefault);
    g_dictEmotes["fidget"] = CEmote({
        CEmotePart(50, kModeLoopGoBackwards, 1, 100, 245)
    }, kTypeDefault);
    g_dictEmotes["barnacle"] = CEmote({
        CEmotePart(182, kModeOnce, 1, 0, 255),
        CEmotePart(183, kModeOnce, 1, 0, 255),
        CEmotePart(184, kModeOnce, 1, 0, 255),
        CEmotePart(185, kModeLoop, 1, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["swim"] = CEmote({
        CEmotePart(11, kModeLoop, 1, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["swim2"] = CEmote({
        CEmotePart(10, kModeLoop, 1, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["run"] = CEmote({
        CEmotePart(3, kModeLoop, 1, 0, 255)
    }, kTypeDefault);
    g_dictEmotes["crazy"] = CEmote({
        CEmotePart(183, kModeLoop, 4, 0, 255)
    }, kTypeDefault);
}

string Emotes_UTIL_GetModeString(EEmoteMode _Mode) {
    switch (_Mode) {
        case kModeOnce: return "ONCE";
        case kModeFreeze: return "FREEZE";
        case kModeLoop: return "LOOP";
        case kModeLoopGoBackwards: return "ILOOP";
    }
    return "???";
}

// force animation even when doing other things
void Emotes_DoEmoteLoop(EHandle _Player, EHandle _lpTarget, CEmote@ _Emote, int _PartIdx, float _LastFrame, bool _IgnoreMovements, bool _NoVerbose) {
    if (!_Player.IsValid()) {
        return;
    }
    
    CBasePlayer@ lpPlayer = cast<CBasePlayer@>(_Player.GetEntity());
    if (lpPlayer is null or !lpPlayer.IsConnected()) {
        return;
    }
    
    CBaseMonster@ lpTarget = cast<CBaseMonster@>(_lpTarget.GetEntity());
    if (lpTarget is null) {
        return;
    }
    
    if (!lpPlayer.IsAlive()) {
        return;
    }
    
    CEmotePart@ lpPart = _Emote.m_aParts[_PartIdx];
    
    // Actually, implementation of "broken" ignoreMovements back from Sw1ft747's Half-Life A
    bool bGaitBroken = (_IgnoreMovements || lpPart.m_bIgnoreMovements) && lpPart.m_iSequence >= 12 && lpPart.m_iSequence <= 18 /* death sequences */;
    
    if (bGaitBroken) {
        lpTarget.pev.gaitsequence = lpPart.m_iSequence;
    } else if (_IgnoreMovements || lpPart.m_bIgnoreMovements) {
        lpTarget.pev.gaitsequence = 0;
    }
    
    bool bEmoteIsPlaying = lpTarget.pev.sequence == lpPart.m_iSequence;
    
    if (!bEmoteIsPlaying) {
        if (lpPart.m_eEmoteMode == kModeLoopGoBackwards) { // Didn't make an ignore movements fix for iloop mode, sadly =( -  t r a s h
            if (_LastFrame >= lpPart.m_flEndFrame - 0.1f) {
                _LastFrame = lpPart.m_flEndFrame;
                lpPart.m_flFramerate = -fabsf(lpPart.m_flFramerate);
            } else if (_LastFrame <= lpPart.m_flStartFrame + 0.1f) {
                _LastFrame = lpPart.m_flStartFrame;
                lpPart.m_flFramerate = fabsf(lpPart.m_flFramerate);
            }
        } else if (lpPart.m_eEmoteMode == kModeLoop) {
            if (!_IgnoreMovements) { // Ignore movements fix when animation restarts after jumping
                _LastFrame = lpPart.m_flStartFrame;
            }
             
            if (lpPart.m_flFramerate >= 0 && _LastFrame <= lpPart.m_flStartFrame) {
                _LastFrame = lpPart.m_flStartFrame;
            }
                
            if (lpPart.m_flFramerate >= 0 && _LastFrame >= lpPart.m_flEndFrame) {
                _LastFrame = lpPart.m_flStartFrame;
            } else if (lpPart.m_flFramerate < 0 && _LastFrame <= lpPart.m_flEndFrame + 0.1f) {
                _LastFrame = lpPart.m_flStartFrame;
            }
        } else if (lpPart.m_eEmoteMode == kModeOnce) {
            if (!_IgnoreMovements) {
                if ((lpPart.m_flFramerate >= 0 and _LastFrame > lpPart.m_flEndFrame - 0.1f) or 
                    (lpPart.m_flFramerate < 0 and _LastFrame < lpPart.m_flEndFrame + 0.1f) or
                    (lpPart.m_flFramerate >= 0 and lpTarget.pev.frame < _LastFrame) or 
                    (lpPart.m_flFramerate < 0 and lpTarget.pev.frame > _LastFrame)) {
                        DoEmote(lpPlayer, _Emote, _Emote.m_bLoopingBack ? _PartIdx - 1 : _PartIdx + 1, _IgnoreMovements, _NoVerbose);
                        return;
                }
            } else { // Ignore movements fix when animation restarts after jumping
                if ((lpPart.m_flFramerate >= 0 and _LastFrame >= lpPart.m_flEndFrame - 0.1f) or (lpPart.m_flFramerate < 0 and _LastFrame <= lpPart.m_flEndFrame + 0.1f)) {
                    DoEmote(lpPlayer, _Emote, _Emote.m_bLoopingBack ? _PartIdx - 1 : _PartIdx + 1, _IgnoreMovements, _NoVerbose);
                    return;
                }
            }
        } else if (lpPart.m_eEmoteMode == kModeFreeze) { // I think freeze mode doesn't need an ignore movements fix 'cause it works properly without it :D
            if ((lpPart.m_flFramerate >= 0 and _LastFrame >= lpPart.m_flEndFrame - 0.1f) or (lpPart.m_flFramerate < 0 and _LastFrame <= lpPart.m_flEndFrame + 0.1f)) {
                _LastFrame = lpPart.m_flEndFrame;
                lpPart.m_flFramerate = lpTarget.pev.framerate = 0.0000001f;
            }
        }
        
        lpTarget.m_Activity = ACT_RELOAD;
        if (bGaitBroken) lpTarget.m_GaitActivity = ACT_RELOAD;
        lpTarget.m_IdealActivity = ACT_RELOAD;
        lpTarget.m_movementActivity = ACT_RELOAD;
        lpTarget.pev.sequence = lpPart.m_iSequence;
        lpTarget.pev.frame = _LastFrame;
        lpTarget.ResetSequenceInfo();
        if (bGaitBroken) lpTarget.ResetGaitSequenceInfo();
        lpTarget.pev.framerate = lpPart.m_flFramerate;
    } else {
        bool bLoopFinished = false;          
        if (lpPart.m_eEmoteMode == kModeLoopGoBackwards)
            bLoopFinished = (lpTarget.pev.frame - lpPart.m_flEndFrame) > 0.0000001f or (lpPart.m_flStartFrame - lpTarget.pev.frame) > 0.0000001f;
        else
            bLoopFinished = lpPart.m_flFramerate > 0 ? (lpTarget.pev.frame - lpPart.m_flEndFrame > 0.01f) : (lpPart.m_flEndFrame - lpTarget.pev.frame > 0.01f);
            
        if (bLoopFinished) {
            if (lpPart.m_eEmoteMode == kModeOnce) {
                DoEmote(lpPlayer, _Emote, _Emote.m_bLoopingBack ? _PartIdx - 1 : _PartIdx + 1, _IgnoreMovements, _NoVerbose);
                return;
            } else if (lpPart.m_eEmoteMode == kModeFreeze) {
                lpTarget.pev.frame = lpPart.m_flEndFrame;
                lpPart.m_flFramerate = lpTarget.pev.framerate = 0.0000001f;
            } else if (lpPart.m_eEmoteMode == kModeLoop)  {
                lpTarget.pev.frame = lpPart.m_flStartFrame;
            } else if (lpPart.m_eEmoteMode == kModeLoopGoBackwards) {
                _LastFrame = lpTarget.pev.frame;
                
                if (_LastFrame >= lpPart.m_flEndFrame - 0.1f) {
                    _LastFrame = lpPart.m_flEndFrame;
                    lpPart.m_flFramerate = -fabsf(lpPart.m_flFramerate);
                } else if (_LastFrame <= lpPart.m_flStartFrame + 0.1f) {
                    _LastFrame = lpPart.m_flStartFrame;
                    lpPart.m_flFramerate = fabsf(lpPart.m_flFramerate);
                }

                lpTarget.pev.framerate = lpPart.m_flFramerate;
            }
        } else {
            _LastFrame = lpTarget.pev.frame;
            
            if (lpPart.m_eEmoteMode == kModeLoop) {
                if (lpPart.m_flFramerate >= 0 && _LastFrame >= lpPart.m_flEndFrame) { //Make the animation reset whenever we end doing it mid-air (loop mode specific)
                    _LastFrame = lpTarget.pev.frame = lpPart.m_flStartFrame;
                } else if (lpPart.m_flFramerate < 0 && _LastFrame <= lpPart.m_flEndFrame + 0.1f) {
                    _LastFrame = lpTarget.pev.frame = lpPart.m_flStartFrame;
                }
            }
            
            lpTarget.m_flLastEventCheck = g_Engine.time + 1.0f;
            lpTarget.m_flLastGaitEventCheck = g_Engine.time + 1.0f;
            
            if (_LastFrame <= 0.f)
                _LastFrame = 0.00001f;
            if (_LastFrame >= 255.f)
                _LastFrame = 254.9999f;
        }
    }
        
    @g_dict_lpfnLoops[lpPlayer.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, _Player, _lpTarget, @_Emote, _PartIdx, _LastFrame, _IgnoreMovements, _NoVerbose);
}

void DoEmote(CBasePlayer@ _Player, CEmote@ _Emote, int _PartIdx, bool _IgnoreMovements, bool _NoVerbose) {
    CBaseMonster@ lpEmoteEnt = cast<CBaseMonster@>(_Player);
    
    if (_PartIdx < 0) {
        if (_Emote.m_eType == kChainLoopingBackwards) {
            _PartIdx = 0;
            _Emote.m_bLoopingBack = false;
        } else if (_Emote.m_eType == kChainLoopingSequenceBackwards) {
            _PartIdx = 0;
            _Emote.m_bLoopingBack = false;
            for (uint idx = 0; idx < _Emote.m_aParts.size(); idx++) {
                CEmotePart@ part = _Emote.m_aParts[idx];
                float flEndFrame = part.m_flEndFrame;
                part.m_flEndFrame = part.m_flStartFrame;
                part.m_flStartFrame = flEndFrame;
                part.m_flFramerate = part.m_flFramerate * -1.f;
            }
        } else {
            return;
        }
    }

    int iPartsSize = int(_Emote.m_aParts.size());
    if (_PartIdx >= iPartsSize) {
        if (_Emote.m_eType == kChainLoop) {
            _PartIdx = 0;
        } else if (_Emote.m_eType == kChainLoopBackwardsOnce) {
            _Emote.m_bLoopingBack = true;
            _PartIdx = iPartsSize - 1;
        } else if (_Emote.m_eType == kChainLoopingBackwards) {
            _Emote.m_bLoopingBack = true;
            _PartIdx = iPartsSize - 1;
        } else if (_Emote.m_eType == kChainLoopingSequenceBackwards) {
            _Emote.m_bLoopingBack = true;
            _PartIdx = iPartsSize - 1;
            for (uint idx = 0; idx < _Emote.m_aParts.size(); idx++) {
                CEmotePart@ part = _Emote.m_aParts[idx];
                float flEndFrame = part.m_flEndFrame;
                part.m_flEndFrame = part.m_flStartFrame;
                part.m_flStartFrame = flEndFrame;
                part.m_flFramerate = part.m_flFramerate * -1.f;
            }
        } else {
            return;
        }
    }
    
    CEmotePart@ lpPart = _Emote.m_aParts[_PartIdx];
    
    if (!_NoVerbose) {
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Part: ' + _PartIdx + ', Sequence: ' + lpPart.m_iSequence + " (" + Emotes_UTIL_GetModeString(lpPart.m_eEmoteMode) + ")" +
            ", Speed " + lpPart.m_flFramerate + ", Frames: " + int(lpPart.m_flStartFrame + 0.5f) + "-" + int(lpPart.m_flEndFrame + 0.5f) + "\n");
    }
    
    // Actually, implementation of "broken" ignoreMovements back from Sw1ft747's Half-Life A
    bool bGaitBroken = (_IgnoreMovements || lpPart.m_bIgnoreMovements) && lpPart.m_iSequence >= 12 && lpPart.m_iSequence <= 18 /* death sequences */;
    
    if (bGaitBroken) {
        lpEmoteEnt.pev.gaitsequence = lpPart.m_iSequence;
    } else if (_IgnoreMovements || lpPart.m_bIgnoreMovements) {
        lpEmoteEnt.pev.gaitsequence = 0;
    }
    
    lpEmoteEnt.m_Activity = ACT_RELOAD;
    if (bGaitBroken) lpEmoteEnt.m_GaitActivity = ACT_RELOAD;
    lpEmoteEnt.m_IdealActivity = ACT_RELOAD;
    lpEmoteEnt.m_movementActivity = ACT_RELOAD;
    lpEmoteEnt.pev.frame = lpPart.m_flStartFrame;
    lpEmoteEnt.pev.sequence = lpPart.m_iSequence;
    lpEmoteEnt.ResetSequenceInfo();
    if (bGaitBroken) lpEmoteEnt.ResetGaitSequenceInfo();
    lpEmoteEnt.pev.framerate = lpPart.m_flFramerate;
        
    CScheduledFunction@ lpSchedule = g_dict_lpfnLoops[_Player.entindex()];
    if (lpSchedule !is null) { // stop previous emote
        g_Scheduler.RemoveTimer(lpSchedule);
    }
    @g_dict_lpfnLoops[_Player.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, EHandle(_Player), EHandle(lpEmoteEnt), _Emote, _PartIdx, lpPart.m_flStartFrame, _IgnoreMovements, _NoVerbose);
}

void Emotes_DoEmoteConCmd(CBasePlayer@ _Player, const CCommand@ _Args) {
    if (_Args.ArgC() >= 2) { //.e 17
        string szEmote = _Args[1].ToLowercase();
        
        if (szEmote == "off" or szEmote == "stop") {
            CScheduledFunction@ lpSchedule = g_dict_lpfnLoops[_Player.entindex()];
            if (lpSchedule !is null and !lpSchedule.HasBeenRemoved()) {
                g_Scheduler.RemoveTimer(lpSchedule);
                _Player.m_Activity = ACT_IDLE;
                _Player.ResetSequenceInfo();
                _Player.ResetGaitSequenceInfo();
                CBaseMonster@ lpTarget = cast<CBaseMonster@>(_Player);
                lpTarget.m_flLastEventCheck = g_Engine.time + 1.0f;
                lpTarget.m_flLastGaitEventCheck = g_Engine.time + 1.0f;
                
                g_PlayerFuncs.SayText(_Player, "Emote stopped\n");
            } else {
                g_PlayerFuncs.SayText(_Player, "No emote is playing\n");
            }
            
            return;
        }
        
        if (szEmote == "version") {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, "emotes plugin v2; xWhitey's, like Sw1ft\n");
                
            return;
        }
        
        if (szEmote == "list") {
            array<string>@ rgszEmoteNames = g_dictEmotes.getKeys();
            rgszEmoteNames.sortAsc();
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, "Emotes: ");
            for (uint idx = 0; idx < rgszEmoteNames.length(); idx++) {
                string szEmoteName = rgszEmoteNames[idx];
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, idx == 0 ? szEmoteName : " | " + szEmoteName);
            }
            
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, "\n");
                
            return;
        }
        
        if (szEmote == "chain") {
            if (_Args.ArgC() < 5) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'You must at least specify sequence number!\n');
                return;
            }
       
            float flSpeedModifier = atof(_Args[2]);
            string loopMode = _Args[3].ToLowercase();
            
            EEmoteType eEmoteType = kTypeDefault;
            if (loopMode == "ilooponce") {
                eEmoteType = kChainLoopBackwardsOnce;
            }
            if (loopMode == "iloop") {
                eEmoteType = kChainLoopingBackwards;
            }
            if (loopMode == "loop") {
                eEmoteType = kChainLoop;
            }
            if (loopMode == "iloopseq") {
                eEmoteType = kChainLoopingSequenceBackwards;
            }
            
            EEmoteMode eLastSequenceMode = kModeOnce;
            if (loopMode == "loopend") {
                eLastSequenceMode = kModeLoop;
            }
            if (loopMode == "iloopend") {
                eLastSequenceMode = kModeLoopGoBackwards;
            }
            if (loopMode == "freezeend") {
                eLastSequenceMode = kModeFreeze;
            }

            array<CEmotePart@> parts;
            
            bool bNoVerbose = false;
            
            for (int i = 4; i < _Args.ArgC(); i++) {
                if (_Args[i].ToLowercase() == "noverbose") {
                    bNoVerbose = true;
                    continue;
                }
            
                array<string> rgszPartOpts = _Args[i].Split("_");
                
                int iSequence = atoi(rgszPartOpts[0]);
                float flSpeed = (rgszPartOpts.size() > 1 ? atof(rgszPartOpts[1]) : 1) * flSpeedModifier;
                
                float flStartFrame = (flSpeed >= 0.f ? 0.0001f : 254.9999f);
                float flEndFrame = (flSpeed >= 0.f ? 254.9999f : 0.0001f);
                flStartFrame = rgszPartOpts.size() > 2 ? atof(rgszPartOpts[2]) : flStartFrame;
                flEndFrame = rgszPartOpts.size() > 3 ? atof(rgszPartOpts[3]) : flEndFrame;
                
                bool bIgnoreMovements = rgszPartOpts.size() > 4 ? atoi(rgszPartOpts[4]) > 0 : false;
                
                if (iSequence > 255) {
                    iSequence = 255;
                }
                
                bool bIsLast = i == _Args.ArgC() - 1;
                EEmoteMode eMode = bIsLast ? eLastSequenceMode : kModeOnce;
                
                parts.insertLast(CEmotePart(iSequence, eMode, flSpeed, flStartFrame, flEndFrame, bIgnoreMovements));
            }

            DoEmote(_Player, CEmote(parts, eEmoteType), 0, false, bNoVerbose);
            
            return;
        }
        
        bool bIsNumeric = true;
        for (uint i = 0; i < szEmote.Length(); i++) {
            if (!isdigit(szEmote[i])) {
                bIsNumeric = false;
                break;
            }
        }
        
        if (!bIsNumeric) {
            if (g_dictEmotes.exists(szEmote)) {
                CEmote@ lpEmote = cast<CEmote@>(g_dictEmotes[szEmote]);
                    
                float flSpeed = _Args.ArgC() >= 3 ? atof(_Args[2]) : 1.0f;
                for (uint idx = 0; idx < lpEmote.m_aParts.size(); idx++) {
                    lpEmote.m_aParts[idx].m_flFramerate *= flSpeed;
                }
                
                bool bNoVerbose = false;
                
                for (int idx = 2; idx < _Args.ArgC(); idx++) {
                    if (!bNoVerbose)
                        bNoVerbose = _Args[idx].ToLowercase() == "noverbose";
                    else
                        break;
                }
                    
                DoEmote(_Player, lpEmote, 0, false, bNoVerbose);
            } else {
                g_PlayerFuncs.SayText(_Player, "No emote found with name " + szEmote + "\n");
            }
            
            return;
        }
        
        int iSequence = atoi(szEmote);
        
        EEmoteMode eMode = kModeOnce;
        string szMode = _Args[2];
        if (szMode.ToLowercase() == "loop") {
            eMode = kModeLoop;
        } else if (szMode.ToLowercase() == "iloop") {
            eMode = kModeLoopGoBackwards;
        } else if (szMode.ToLowercase() == "freeze") {
            eMode = kModeFreeze;
        }
        
        bool bIgnoreMovements = _Args.ArgC() >= 7 ? (atoi(_Args[6]) > 0) : false;
        
        float flFramerate = _Args.ArgC() >= 4 ? atof(_Args[3]) : 1.0f;
        float flStartFrame = (flFramerate >= 0 ? 0.0001f : 254.9999f);
        float flEndFrame = (flFramerate >= 0 ? 254.9999f : 0.0001f);
        if (iSequence > 255) {
            iSequence = 255;
        }
            
        flStartFrame = _Args.ArgC() >= 5 ? atof(_Args[4]) : flStartFrame;
        flEndFrame = _Args.ArgC() >= 6 ? atof(_Args[5]) : flEndFrame;
        
        bool bNoVerbose = false;
                
        for (int idx = 2; idx < _Args.ArgC(); idx++) {
            if (!bNoVerbose)
                bNoVerbose = _Args[idx].ToLowercase() == "noverbose";
            else
                break;
        }
        
        DoEmote(_Player, CEmote({CEmotePart(iSequence, eMode, flFramerate, flStartFrame, flEndFrame)}, kTypeDefault), 0, bIgnoreMovements, bNoVerbose);
    } else {
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '----------------------------------Emote Commands----------------------------------\n\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e off" to stop your emote.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e list" to list all named emotes.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e <name> [speed]" to play a named emote.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e <sequence> [mode] [speed] [start_frame] [end_frame] [ignore_movements]" for more control.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e chain <speed> <chain_mode> <sequence>_[speed]_[start_frame]_[end_frame]_[ignore_movements] ..." for advanced combos.\n');
    
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n<> = required. [] = optional.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\nAdd "noverbose" in any part of the command to disable verbose.\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<sequence> = 0-255. Most models have about 190 sequences.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[mode] = once, freeze, loop, or iloop.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<chain_mode> = once, loop, iloop, ilooponce, iloopseq, freezeend, loopend, or iloopend.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[speed] = Any number, even negative. The default speed is 1.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[start_frame/end_frame] = 0-255. This is like a percentage. Frame count in the model doesn\'t matter.\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\nExamples:\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e oof\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e oof 2\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 0.5\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 0.5 0 50\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 1 0 255 1\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 2 loop 13 14 15\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 once 13 14_-1\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 iloopend 182 183 184 185\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 freezeend 15_0.1_0_50 16_-1_100_10\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 iloop 15 17\n');
        
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n----------------------------------------------------------------------------------\n');
    }
}

CClientCommand g_EmoteCommand("e", "Emote commands", @CMD_Emote);

void CMD_Emote(const CCommand@ _Args) {
    string szMapname = g_Engine.mapname;
    
    CBasePlayer@ lpPlayer = g_ConCommandSystem.GetCurrentPlayer();
    
    if (szMapname.Find("qsg") == 0 || szMapname.Find("zm") == 0 || szMapname.Find("hns") == 0 || szMapname == "ctf_warforts" || szMapname == "frostline_v1r") {
        g_PlayerFuncs.ClientPrint(lpPlayer, HUD_PRINTCONSOLE, "Unknown command: .e\n");
        return;
    }

    Emotes_DoEmoteConCmd(lpPlayer, _Args);
}
