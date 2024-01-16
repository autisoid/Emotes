array<CScheduledFunction@> g_dict_lpfnLoops(33);

void PluginInit() {
    g_Module.ScriptInfo.SetAuthor("xWhitey feat. wootguy");
    g_Module.ScriptInfo.SetContactInfo("@tyabus at Discord");
}

enum EEmoteMode {
    kModeOnce, // play once
    kModeFreeze, // freeze on the last frame
    kModeLoop, // loop betwen start and end frames
    kModeLoopGoBackwards // invert framerate when reaching the start/end frame (basically makes the emote go back from last frame)
}

class CEmotePart {
    int m_iSequence;
    int m_eEmoteMode;
    float m_flFramerate;
    float m_flStartFrame;
    float m_flEndFrame;
    float m_flCurFrame;
    
    bool m_bIgnoreMovements_Chain;
    
    CEmotePart() {}
    
    CEmotePart(int _Sequence, int _Mode, float _Framerate, float _StartFrame, float _EndFrame, bool _IgnoreMovements_Chain = false) {
        m_iSequence = _Sequence;
        m_eEmoteMode = _Mode;
        m_flFramerate = _Framerate;
        m_flStartFrame = _StartFrame;
        m_flEndFrame = _EndFrame;
        m_flCurFrame = 1.0f;
        m_bIgnoreMovements_Chain = _IgnoreMovements_Chain;
        
        if (m_flFramerate == 0) {
            m_flFramerate = 0.0000001f;
        }
        if (m_flStartFrame <= 0) {
            m_flStartFrame = 0.00001f;
        }
        if (m_flEndFrame >= 255) {
            m_flEndFrame = 254.9999f;
        }
    }
}

class CEmote {
    array<CEmotePart> m_aParts;
    bool m_bLoop;
    bool m_bGaitOnly;
    
    CEmote() {}
    
    CEmote(array<CEmotePart> _Parts, bool _bLoop, bool _bGaitOnly = false) {
        this.m_aParts = _Parts;
        this.m_bLoop = _bLoop;
        m_bGaitOnly = _bGaitOnly;
    }
}

string Emotes_UTIL_GetModeString(int mode) {
    switch(mode) {
        case kModeOnce: return "ONCE";
        case kModeFreeze: return "FREEZE";
        case kModeLoop: return "LOOP";
        case kModeLoopGoBackwards: return "ILOOP";
    }
    return "???";
}

class CTrickyBoolVarargs {
    bool m_bIgnoreMovements;
    bool m_bZeroSize;
    bool m_bGaitSequencesIsTheSameAsSequence;
    bool m_bNoVerbose;
    
    CTrickyBoolVarargs(bool _IgnoreMovements, bool _ZeroSize, bool _GaitSequenceIsTheSameAsSequence, bool _NoVerbose) {
        m_bIgnoreMovements = _IgnoreMovements;
        m_bZeroSize = _ZeroSize;
        m_bGaitSequencesIsTheSameAsSequence = _GaitSequenceIsTheSameAsSequence;
        m_bNoVerbose = _NoVerbose;
    }
}

// force animation even when doing other things
void Emotes_DoEmoteLoop(EHandle _Player, EHandle _Target, CEmote@ _Emote, int _PartIdx, float _LastFrame, CTrickyBoolVarargs@ _Varargs) {
    if (!_Player.IsValid()) {
        return;
    }
    
    CBasePlayer@ plr = cast<CBasePlayer@>(_Player.GetEntity());
    if (plr is null or !plr.IsConnected()) {
        return;
    }
    
    CBaseMonster@ target = cast<CBaseMonster@>(_Target.GetEntity());
    if (target is null) {
        return;
    }
    
    if (!plr.IsAlive()) {
        return;
    }
    
    bool _IgnoreMovements = _Varargs.m_bIgnoreMovements;
    bool _ZeroSize = _Varargs.m_bZeroSize;
    bool _GaitSequenceIsTheSameAsSequence = _Varargs.m_bGaitSequencesIsTheSameAsSequence;
    bool _NoVerbose = _Varargs.m_bNoVerbose;
    
    if (_ZeroSize) {
        target.pev.size = g_vecZero;
        target.pev.mins = g_vecZero;
        target.pev.maxs = g_vecZero;
    }
    
    CEmotePart e = _Emote.m_aParts[_PartIdx];
    
    // Hardcoded ignore movements impl
    if ((_IgnoreMovements || e.m_bIgnoreMovements_Chain) && e.m_iSequence >= 12 && e.m_iSequence <= 18) {
        if (!_GaitSequenceIsTheSameAsSequence && e.m_bIgnoreMovements_Chain) {
            _GaitSequenceIsTheSameAsSequence = true;
        }
        if (_GaitSequenceIsTheSameAsSequence) {
            target.pev.gaitsequence = e.m_iSequence;
        } else {
            target.pev.gaitsequence = 0;
        }
    } else if (_IgnoreMovements || e.m_bIgnoreMovements_Chain) {
        target.pev.gaitsequence = 0;
        _GaitSequenceIsTheSameAsSequence = false;
    }
    
    bool bEmoteIsPlaying = target.pev.sequence == e.m_iSequence;
        
    if (!bEmoteIsPlaying) {
        if (e.m_eEmoteMode == kModeLoopGoBackwards) { // Didn't make an ignore movements fix for iloop mode, sadly =( -  t r a s h
            if (_LastFrame >= e.m_flEndFrame - 0.1f) {
                _LastFrame = e.m_flEndFrame;
                e.m_flFramerate = -abs(e.m_flFramerate);
            }  else if (_LastFrame <= e.m_flStartFrame + 0.1f) {
                _LastFrame = e.m_flStartFrame;
                e.m_flFramerate = abs(e.m_flFramerate);
            }
        } else if (e.m_eEmoteMode == kModeLoop) {
            if (!_IgnoreMovements && !e.m_bIgnoreMovements_Chain) { // Ignore movements fix when animation restarts after jumping
                _LastFrame = e.m_flStartFrame;
            }
             
            if (e.m_flFramerate >= 0 && _LastFrame <= e.m_flStartFrame) {
                _LastFrame = e.m_flStartFrame;
            }
                
            if (e.m_flFramerate >= 0 && _LastFrame >= e.m_flEndFrame) {
                _LastFrame = e.m_flStartFrame;
            } else if (e.m_flFramerate < 0 && _LastFrame <= e.m_flEndFrame + 0.1f) {
                _LastFrame = e.m_flStartFrame;
            }
        } else if (e.m_eEmoteMode == kModeOnce) {
            if (!_IgnoreMovements && !e.m_bIgnoreMovements_Chain) {
                if ((e.m_flFramerate >= 0 and _LastFrame > e.m_flEndFrame - 0.1f) or 
                    (e.m_flFramerate < 0 and _LastFrame < e.m_flEndFrame + 0.1f) or
                    (e.m_flFramerate >= 0 and target.pev.frame < _LastFrame) or 
                    (e.m_flFramerate < 0 and target.pev.frame > _LastFrame)) {
                        DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, _IgnoreMovements || e.m_bIgnoreMovements_Chain, _ZeroSize, _GaitSequenceIsTheSameAsSequence);
                        return;
                }
            } else { // Ignore movements fix when animation restarts after jumping
                if ((e.m_flFramerate >= 0 and _LastFrame >= e.m_flEndFrame - 0.1f) or (e.m_flFramerate < 0 and _LastFrame <= e.m_flEndFrame + 0.1f)) {
                    DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, _IgnoreMovements || e.m_bIgnoreMovements_Chain, _ZeroSize, _GaitSequenceIsTheSameAsSequence);
                    return;
                }
            }
        } else if (e.m_eEmoteMode == kModeFreeze) { // I think freeze mode doesn't need an ignore movements fix 'cause it works properly without it :D
            if ((e.m_flFramerate >= 0 and _LastFrame >= e.m_flEndFrame - 0.1f) or (e.m_flFramerate < 0 and _LastFrame <= e.m_flEndFrame + 0.1f)) {
                _LastFrame = e.m_flEndFrame;
                e.m_flFramerate = target.pev.framerate = 0.0000001f;
            }
        }
        
        target.m_Activity = ACT_RELOAD;
        if (_GaitSequenceIsTheSameAsSequence) target.m_GaitActivity = ACT_RELOAD;
        target.m_IdealActivity = ACT_RELOAD;
        target.m_movementActivity = ACT_RELOAD;
        target.pev.sequence = e.m_iSequence;
        target.pev.frame = _LastFrame;
        target.ResetSequenceInfo();
        if (_GaitSequenceIsTheSameAsSequence) target.ResetGaitSequenceInfo();
        target.pev.framerate = e.m_flFramerate;
    } else {
        bool bLoopFinished = false;          
        if (e.m_eEmoteMode == kModeLoopGoBackwards)
            bLoopFinished = (target.pev.frame - e.m_flEndFrame > 0.01f) or (e.m_flStartFrame - target.pev.frame > 0.01f);
        else
            bLoopFinished = e.m_flFramerate > 0 ? (target.pev.frame - e.m_flEndFrame > 0.01f) : (e.m_flEndFrame - target.pev.frame > 0.01f);
            
        if (bLoopFinished) {
            if (e.m_eEmoteMode == kModeOnce) {
                DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, _IgnoreMovements || e.m_bIgnoreMovements_Chain, _ZeroSize, _GaitSequenceIsTheSameAsSequence);
                return;
            } else if (e.m_eEmoteMode == kModeFreeze) {
                target.pev.frame = e.m_flEndFrame;
                e.m_flFramerate = target.pev.framerate = 0.0000001f;
            } else if (e.m_eEmoteMode == kModeLoop)  {
                target.pev.frame = e.m_flStartFrame;
            } else if (e.m_eEmoteMode == kModeLoopGoBackwards) {
                _LastFrame = target.pev.frame;
                if (_LastFrame >= e.m_flEndFrame - 0.1f) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = -abs(e.m_flFramerate);
                } else if (_LastFrame <= e.m_flStartFrame + 0.1f) {
                    _LastFrame = e.m_flStartFrame;
                    e.m_flFramerate = abs(e.m_flFramerate);
                }

                target.pev.framerate = e.m_flFramerate;
            }
        } else {
            _LastFrame = target.pev.frame;
                
            target.m_flLastEventCheck = g_Engine.time + 1.0f;
            target.m_flLastGaitEventCheck = g_Engine.time + 1.0f;
            
            if (_LastFrame <= 0)
                _LastFrame = 0.00001f;
            if (_LastFrame >= 255)
                _LastFrame = 254.9999f;
        }
    }
        
    @g_dict_lpfnLoops[plr.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, _Player, _Target, @_Emote, _PartIdx, _LastFrame, @_Varargs);
}

void DoEmote(CBasePlayer@ _Player, CEmote _Emote, int _PartIdx, bool _NoVerbose, bool _IgnoreMovements, bool _ZeroSize, bool _GaitSequenceIsTheSameAsSequence) {
    CBaseMonster@ emoteEnt = cast<CBaseMonster@>(_Player);

    if (_PartIdx >= int(_Emote.m_aParts.size())) {
        if (_Emote.m_bLoop) {
            _PartIdx = 0;
        } else {
            return;
        }
    }
    
    CEmotePart e = _Emote.m_aParts[_PartIdx];
    
    if (!_NoVerbose) {
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Part: ' + _PartIdx + ', Sequence: ' + e.m_iSequence + " (" + Emotes_UTIL_GetModeString(e.m_eEmoteMode) + ")" +
            ", Speed " + e.m_flFramerate + ", Frames: " + int(e.m_flStartFrame + 0.5f) + "-" + int(e.m_flEndFrame + 0.5f) + "\n");
    }
        
    if (_ZeroSize) {
        emoteEnt.pev.size = g_vecZero;
        emoteEnt.pev.mins = g_vecZero;
        emoteEnt.pev.maxs = g_vecZero;
    }
    
    if ((_IgnoreMovements || e.m_bIgnoreMovements_Chain) && e.m_iSequence >= 12 && e.m_iSequence <= 18) {
        if (!_GaitSequenceIsTheSameAsSequence && e.m_bIgnoreMovements_Chain) {
            _GaitSequenceIsTheSameAsSequence = true;
        }
        if (_GaitSequenceIsTheSameAsSequence) {
            emoteEnt.pev.gaitsequence = e.m_iSequence;
        }
    } else if (_IgnoreMovements || e.m_bIgnoreMovements_Chain) {
        emoteEnt.pev.gaitsequence = 0;
        _GaitSequenceIsTheSameAsSequence = false;
    }
    
    emoteEnt.m_Activity = ACT_RELOAD;
    if (_GaitSequenceIsTheSameAsSequence) emoteEnt.m_GaitActivity = ACT_RELOAD;
    emoteEnt.m_IdealActivity = ACT_RELOAD;
    emoteEnt.m_movementActivity = ACT_RELOAD;
    emoteEnt.pev.frame = e.m_flStartFrame;
    emoteEnt.pev.sequence = e.m_iSequence;
    emoteEnt.ResetSequenceInfo();
    if (_GaitSequenceIsTheSameAsSequence) emoteEnt.ResetGaitSequenceInfo();
    emoteEnt.pev.framerate = e.m_flFramerate;
        
    CScheduledFunction@ func = g_dict_lpfnLoops[_Player.entindex()];
    if (func !is null) { // stop previous emote
        g_Scheduler.RemoveTimer(func);
    }
    @g_dict_lpfnLoops[_Player.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, EHandle(_Player), EHandle(emoteEnt), _Emote, _PartIdx, e.m_flStartFrame, CTrickyBoolVarargs(_IgnoreMovements, _ZeroSize, _GaitSequenceIsTheSameAsSequence, _NoVerbose));
}

void Emotes_DoEmoteConCmd(CBasePlayer@ _Player, const CCommand@ _Args) {
    if (_Args.ArgC() >= 2) { //.e 17
        string szEmote = _Args[1].ToLowercase();
        
        if (szEmote == "off" or szEmote == "stop") {
            CScheduledFunction@ func = g_dict_lpfnLoops[_Player.entindex()];
            if (func !is null and !func.HasBeenRemoved()) {
                g_Scheduler.RemoveTimer(func);
                _Player.m_Activity = ACT_IDLE;
                _Player.ResetSequenceInfo();
                _Player.ResetGaitSequenceInfo();
                CBaseMonster@ target = cast<CBaseMonster@>(_Player);
                target.m_flLastEventCheck = g_Engine.time + 1.0f;
                target.m_flLastGaitEventCheck = g_Engine.time + 1.0f;
                
                Vector vecSize = Vector(1.0f, 1.0f, 1.0f);
                target.pev.size = vecSize;
                target.pev.mins = vecSize;
                target.pev.maxs = vecSize;
                
                g_PlayerFuncs.SayText(_Player, "Emote stopped\n");
            } else {
                g_PlayerFuncs.SayText(_Player, "No emote is playing\n");
            }
            
            return;
        }
        
        if (szEmote == "list") {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, "Emotes: anal | lewd | nigger | wave\n");
                
            return;
        }
        
        if (szEmote == "anal") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
        
            DoEmote(_Player, CEmote({CEmotePart(14, kModeFreeze, 0.0f, 120, 120)}, false), 0, noVerbose, true, false, false);
            return;
        } else if (szEmote == "lewd") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
        
            DoEmote(_Player, CEmote({CEmotePart(88, kModeLoopGoBackwards, 1.0f, 40, 70)}, false), 0, noVerbose, false, false, false);
            return;
        } else if (szEmote == "nigger") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
        
            DoEmote(_Player, CEmote({CEmotePart(17, kModeFreeze, 1.0f, 255, 255)}, false), 0, noVerbose, true, false, true);
            return;
        } else if (szEmote == "wave") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
            
            DoEmote(_Player, CEmote({CEmotePart(190, kModeOnce, 1.0f, 0, 255)}, false), 0, noVerbose, false, false, false);
            return;
        }
        
        if (szEmote == "chain") {
            if (_Args.ArgC() < 5) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'You must at least specify sequence number!\n');
                return;
            }
       
            float speedMod = atof(_Args[2]);
            string loopMode = _Args[3].ToLowercase();
            
            int lastSeqMode = kModeOnce;
            if (loopMode == "loopend") {
                lastSeqMode = kModeLoop;
            }
            if (loopMode == "iloopend") {
                lastSeqMode = kModeLoopGoBackwards;
            }
            if (loopMode == "freezeend") {
                lastSeqMode = kModeFreeze;
            }

            array<CEmotePart> parts;
            
            for (int i = 4; i < _Args.ArgC(); i++) {
                array<string> seqOpts = _Args[i].Split("_");
                if (seqOpts[0].ToLowercase() == "noverbose") continue;
                
                int seq = atoi(seqOpts[0]);
                float speed = (seqOpts.size() > 1 ? atof(seqOpts[1]) : 1) * speedMod;
                
                float startFrame = (speed >= 0 ? 0.0001f : 254.9999f);
                float endFrame = (speed >= 0 ? 254.9999f : 0.0001f);
                startFrame = seqOpts.size() > 2 ? atof(seqOpts[2]) : startFrame;
                endFrame = seqOpts.size() > 3 ? atof(seqOpts[3]) : endFrame;
                bool ignoreMovements = seqOpts.size() > 4 ? (atoi(seqOpts[4]) > 0) : false;
                
                if (seq > 255) {
                    seq = 255;
                }
                
                bool isLast = i == _Args.ArgC() - 1;
                int mode = isLast ? lastSeqMode : kModeOnce;
                
                parts.insertLast(CEmotePart(seq, mode, speed, startFrame, endFrame, ignoreMovements));
            }

            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }

            DoEmote(_Player, CEmote(parts, loopMode == "loop"), 0, noVerbose, false, false, false);
            
            return;
        }
        
        bool isNumeric = true;
        for (uint i = 0; i < szEmote.Length(); i++) {
            if (!isdigit(szEmote[i])) {
                isNumeric = false;
                break;
            }
        }
        
        if (!isNumeric) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'The passed sequence is not numeric, skipping...\n');
            return;
        }
        
        int seq = atoi(szEmote);
        
        int mode = kModeOnce;
        string szMode = _Args[2];
        if (szMode.ToLowercase() == "loop") {
            mode = kModeLoop;
        } else if (szMode.ToLowercase() == "iloop") {
            mode = kModeLoopGoBackwards;
        } else if (szMode.ToLowercase() == "freeze") {
            mode = kModeFreeze;
        }
        
        bool ignoreMovements = _Args.ArgC() >= 7 ? (atoi(_Args[6]) > 0) : false;
        bool zeroSize = _Args.ArgC() >= 8 ? (atoi(_Args[7]) > 0) : false;
        bool gaitSequenceIsTheSameAsSequence = _Args.ArgC() >= 9 ? (atoi(_Args[8]) > 0) : (seq >= 12 && seq <= 18);
        
        float framerate = _Args.ArgC() >= 4 ? atof(_Args[3]) : 1.0f;
        float startFrame = (framerate >= 0 ? 0.0001f : 254.9999f);
        float endFrame = (framerate >= 0 ? 254.9999f : 0.0001f);
        if (seq > 255) {
            seq = 255;
        }
            
        startFrame = _Args.ArgC() >= 5 ? atof(_Args[4]) : startFrame;
        endFrame = _Args.ArgC() >= 6 ? atof(_Args[5]) : endFrame;
        
        bool noVerbose = false;
        
        for (int idx = 2; idx < _Args.ArgC(); idx++) {
            if (_Args[idx].ToLowercase() == "noverbose") {
                noVerbose = true;
                break;
            }
        }

        DoEmote(_Player, CEmote({CEmotePart(seq, mode, framerate, startFrame, endFrame)}, false), 0, noVerbose, ignoreMovements, zeroSize, gaitSequenceIsTheSameAsSequence);
    } else {
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '----------------------------------Emote Commands----------------------------------\n\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e off/.e stop" to stop your emote.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e list" to list all named emotes.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e chain <speed> <chain_mode> <sequence>_[speed]_[startFrame]_[endFrame]_[ignoreMovements] ..." for advanced combos.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e <sequence> [mode] [speed] [startFrame] [endFrame] [ignoreMovements]" to run a sequence.\n');
    
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n<> = required. [] = optional.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Add "noVerbose" in any part of the command to disable verbose.\n\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<sequence> = 0-255. Most models have about 190 sequences.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[mode] = once, freeze, loop, or iloop.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[speed] = Any number, even negative. The default speed is 1.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<chain_mode> = once, loop, freezeend, loopend, or iloopend.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[startFrame/endFrame] = 0-255. This is like a percentage. Frame count in the model doesn\'t matter.\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\nExamples:\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 0.5\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 0.5 0 50\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 2 loop 13 14 15\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 once 13 14_-1\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 iloopend 182 183 184 185\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 freezeend 15_0.1_0_50 16_-1_100_10\n');
        
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n----------------------------------------------------------------------------------\n');
    }
}

CClientCommand _emote("e", "Emote commands", @CMD_Emote);

void CMD_Emote(const CCommand@ args) {
    Emotes_DoEmoteConCmd(g_ConCommandSystem.GetCurrentPlayer(), args);
}
