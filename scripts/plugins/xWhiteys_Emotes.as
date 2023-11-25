array<CScheduledFunction@> g_dict_lpfnLoops(33);

void PluginInit() {
    g_Module.ScriptInfo.SetAuthor("xWhitey feat. wootguy");
    g_Module.ScriptInfo.SetContactInfo("@tyabus at Discord");
}

//Implement that on your own: Used in Constantium server to prevent .e abuse in QuickSurvivalGames and CTF Warforts.
/*bool Emotes_IsPlayerAllowedToPlayEmotesOnAnyMap(const string& in _SteamID) {
    for (uint idx = 0; idx < g_a_lpszAllowedSteamIDs.length(); idx++) {
        string steamID = g_a_lpszAllowedSteamIDs[idx];
        
        if (steamID == _SteamID)
            return true;
    }
    
    return false;
}*/

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
    
    bool m_bMixed;
    int m_iSecondSequence;
    
    bool m_bIgnoreMovements_Chain;
    
    CEmotePart() {}
    
    CEmotePart(int _Sequence, int _Mode, float _Framerate, float _StartFrame, float _EndFrame, bool _Mixed = false, int _SecondSequence = 0, bool _IgnoreMovements_Chain = false) {
        m_iSequence = _Sequence;
        m_eEmoteMode = _Mode;
        m_flFramerate = _Framerate;
        m_flStartFrame = _StartFrame;
        m_flEndFrame = _EndFrame;
        m_flCurFrame = 1.0f;
        m_bMixed = _Mixed;
        m_iSecondSequence = _SecondSequence;
        m_bIgnoreMovements_Chain = _IgnoreMovements_Chain;

        if (_Framerate == 0) {
            _Framerate = 0.0000001f;
        }
        if (_StartFrame <= 0) {
            _StartFrame = 0.00001f;
        }
        if (_EndFrame >= 255) {
            _EndFrame = 254.9999f;
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

class CEmotePartGenerator {
    int m_iSequence;
    float m_flStartFrame;
    float m_flEndFrame;
    float m_flFramerate;

    CEmotePartGenerator(int _Sequence, float _StartFrame, float _EndFrame, float _Framerate) {
        m_iSequence = _Sequence;
        m_flStartFrame = _StartFrame;
        m_flEndFrame = _EndFrame;
        m_flFramerate = _Framerate;
    }
    
    array<CEmotePart> Generate() {
        array<CEmotePart> parts;
        
        for (float flFrame = m_flStartFrame; flFrame <= m_flEndFrame; flFrame = flFrame + 1.0f) {
            parts.insertLast(CEmotePart(m_iSequence, kModeOnce, m_flFramerate, flFrame, flFrame, false, 0, true));
        }
        
        return parts;
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
    bool m_bForceIdealActivities;
    bool m_bGaitSequencesIsTheSameAsSequence;
    bool m_bForceInfiniteSequence;
    bool m_bNoVerbose;
    
    CTrickyBoolVarargs(bool _IgnoreMovements, bool _ZeroSize, bool _ForceIdealActivities, bool _GaitSequenceIsTheSameAsSequence, bool _ForceInfiniteSequence, bool _NoVerbose) {
        m_bIgnoreMovements = _IgnoreMovements;
        m_bZeroSize = _ZeroSize;
        m_bForceIdealActivities = _ForceIdealActivities;
        m_bGaitSequencesIsTheSameAsSequence = _GaitSequenceIsTheSameAsSequence;
        m_bForceInfiniteSequence = _ForceInfiniteSequence;
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
    bool _ForceIdealActivities = _Varargs.m_bForceIdealActivities;
    bool _GaitSequenceIsTheSameAsSequence = _Varargs.m_bGaitSequencesIsTheSameAsSequence;
    bool _ForceInfiniteSequence = _Varargs.m_bForceInfiniteSequence;
    bool _NoVerbose = _Varargs.m_bNoVerbose;
    
    if (_ZeroSize) {
        Vector vecZero = Vector(0.0f, 0.0f, 0.0f);
    
        target.pev.size = vecZero;
        target.pev.mins = vecZero;
        target.pev.maxs = vecZero;
    }
    
    CEmotePart e = _Emote.m_aParts[_PartIdx];
    
    if (e.m_bMixed) {
        bool bEmoteIsPlaying = target.pev.sequence == e.m_iSequence;
        
        if (!bEmoteIsPlaying) {
            if (e.m_eEmoteMode == kModeLoopGoBackwards) {
                if (_LastFrame >= e.m_flEndFrame - 0.1f) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = -abs(e.m_flFramerate);
                }  else if (_LastFrame <= e.m_flStartFrame + 0.1f) {
                    _LastFrame = e.m_flStartFrame;
                    e.m_flFramerate = abs(e.m_flFramerate);
                }
            } else if (e.m_eEmoteMode == kModeLoop) {
                _LastFrame = e.m_flStartFrame;
            } else if (e.m_eEmoteMode == kModeOnce) {
                if ((e.m_flFramerate >= 0 and _LastFrame > e.m_flEndFrame - 0.1f) or 
                    (e.m_flFramerate < 0 and _LastFrame < e.m_flEndFrame + 0.1f) or
                    (e.m_flFramerate >= 0 and target.pev.frame < _LastFrame) or 
                    (e.m_flFramerate < 0 and target.pev.frame > _LastFrame)) {
                        DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, false, false, false, false, false);
                        return;
                }
            } else if (e.m_eEmoteMode == kModeFreeze) {
                if ((e.m_flFramerate >= 0 and _LastFrame >= e.m_flEndFrame - 0.1f) or (e.m_flFramerate < 0 and _LastFrame <= e.m_flEndFrame + 0.1f)) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = target.pev.framerate = 0.0000001f;
                }
            }
            
            target.SetActivity(ACT_RELOAD);
            target.SetGaitActivity(ACT_RELOAD);
            target.pev.frame = _LastFrame;
            target.pev.sequence = e.m_iSequence;
            target.pev.gaitsequence = e.m_iSecondSequence;
            target.ResetSequenceInfo();
            target.ResetGaitSequenceInfo();
            target.pev.framerate = e.m_flFramerate;
        } else { 
            bool bLoopFinished = false;          
            if (e.m_eEmoteMode == kModeLoopGoBackwards)
                bLoopFinished = (target.pev.frame - e.m_flEndFrame > 0.01f) or (e.m_flStartFrame - target.pev.frame > 0.01f);
            else
                bLoopFinished = e.m_flFramerate > 0 ? (target.pev.frame - e.m_flEndFrame > 0.01f) : (e.m_flEndFrame - target.pev.frame > 0.01f);
            
            if (bLoopFinished) {
                if (e.m_eEmoteMode == kModeOnce) {
                    DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, false, false, false, false, false);
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
    }

    if (!_Emote.m_bGaitOnly) {
        bool bEmoteIsPlaying = target.pev.sequence == e.m_iSequence;
        
        if (!bEmoteIsPlaying) {
            if (e.m_eEmoteMode == kModeLoopGoBackwards) {
                if (_LastFrame >= e.m_flEndFrame - 0.1f) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = -abs(e.m_flFramerate);
                }  else if (_LastFrame <= e.m_flStartFrame + 0.1f) {
                    _LastFrame = e.m_flStartFrame;
                    e.m_flFramerate = abs(e.m_flFramerate);
                }
            } else if (e.m_eEmoteMode == kModeLoop) {
                _LastFrame = e.m_flStartFrame;
            } else if (e.m_eEmoteMode == kModeOnce) {
                if ((e.m_flFramerate >= 0 and _LastFrame > e.m_flEndFrame - 0.1f) or 
                    (e.m_flFramerate < 0 and _LastFrame < e.m_flEndFrame + 0.1f) or
                    (e.m_flFramerate >= 0 and target.pev.frame < _LastFrame) or 
                    (e.m_flFramerate < 0 and target.pev.frame > _LastFrame)) {
                        DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, _IgnoreMovements || e.m_bIgnoreMovements_Chain, _ZeroSize, _ForceIdealActivities, _GaitSequenceIsTheSameAsSequence, _ForceInfiniteSequence);
                        return;
                }
            } else if (e.m_eEmoteMode == kModeFreeze) {
                if ((e.m_flFramerate >= 0 and _LastFrame >= e.m_flEndFrame - 0.1f) or (e.m_flFramerate < 0 and _LastFrame <= e.m_flEndFrame + 0.1f)) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = target.pev.framerate = 0.0000001f;
                }
            }
            
            target.SetActivity(ACT_RELOAD);
            if (_GaitSequenceIsTheSameAsSequence) target.SetGaitActivity(ACT_RELOAD);
            if (_ForceIdealActivities) {
                target.m_IdealActivity = ACT_RELOAD;
                target.m_movementActivity = ACT_RELOAD;
            }
            if (_IgnoreMovements || e.m_bIgnoreMovements_Chain) plr.SetAnimation(PLAYER_SUPERJUMP);
            target.pev.sequence = e.m_iSequence;
            if (_GaitSequenceIsTheSameAsSequence) target.pev.gaitsequence = e.m_iSequence;
            target.pev.frame = _LastFrame;
            target.ResetSequenceInfo();
            if (_GaitSequenceIsTheSameAsSequence) target.ResetGaitSequenceInfo();
            if (_ForceInfiniteSequence) {
                target.m_fSequenceFinished = false;
                target.m_fSequenceLoops = true;
            }
            target.pev.framerate = e.m_flFramerate;
        } else { 
            bool bLoopFinished = false;          
            if (e.m_eEmoteMode == kModeLoopGoBackwards)
                bLoopFinished = (target.pev.frame - e.m_flEndFrame > 0.01f) or (e.m_flStartFrame - target.pev.frame > 0.01f);
            else
                bLoopFinished = e.m_flFramerate > 0 ? (target.pev.frame - e.m_flEndFrame > 0.01f) : (e.m_flEndFrame - target.pev.frame > 0.01f);
            
            if (bLoopFinished) {
                if (e.m_eEmoteMode == kModeOnce) {
                    DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, _IgnoreMovements || e.m_bIgnoreMovements_Chain, _ZeroSize, _ForceIdealActivities, _GaitSequenceIsTheSameAsSequence, _ForceInfiniteSequence);
                    return;
                } else if (e.m_eEmoteMode == kModeFreeze) {
                    target.pev.frame = _IgnoreMovements || e.m_bIgnoreMovements_Chain ? 1.0f : e.m_flEndFrame;
                    //if (!_IgnoreMovements) 
                        e.m_flFramerate = target.pev.framerate = 0.0000001f;
                    //else
                        //target.StopAnimation();
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
    } else {
        bool bEmoteIsPlaying = target.pev.gaitsequence == e.m_iSequence;
        
        if (!bEmoteIsPlaying) {
            if (e.m_eEmoteMode == kModeLoopGoBackwards) {
                if (_LastFrame >= e.m_flEndFrame - 0.1f) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = -abs(e.m_flFramerate);
                }  else if (_LastFrame <= e.m_flStartFrame + 0.1f) {
                    _LastFrame = e.m_flStartFrame;
                    e.m_flFramerate = abs(e.m_flFramerate);
                }
            } else if (e.m_eEmoteMode == kModeLoop) {
                _LastFrame = e.m_flStartFrame;
            } else if (e.m_eEmoteMode == kModeOnce) {
                if ((e.m_flFramerate >= 0 and _LastFrame > e.m_flEndFrame - 0.1f) or 
                    (e.m_flFramerate < 0 and _LastFrame < e.m_flEndFrame + 0.1f) or
                    (e.m_flFramerate >= 0 and target.pev.frame < _LastFrame) or 
                    (e.m_flFramerate < 0 and target.pev.frame > _LastFrame)) {
                        DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, false, false, false, false, false);
                        return;
                }
            } else if (e.m_eEmoteMode == kModeFreeze) {
                if ((e.m_flFramerate >= 0 and _LastFrame >= e.m_flEndFrame - 0.1f) or (e.m_flFramerate < 0 and _LastFrame <= e.m_flEndFrame + 0.1f)) {
                    _LastFrame = e.m_flEndFrame;
                    e.m_flFramerate = target.pev.framerate = 0.0000001f;
                }
            }
            
            target.SetGaitActivity(ACT_RELOAD);
            target.pev.gaitsequence = e.m_iSequence;
            target.pev.frame = _LastFrame;
            target.ResetGaitSequenceInfo();
            target.pev.framerate = e.m_flFramerate;
        } else { 
            bool bLoopFinished = false;          
            if (e.m_eEmoteMode == kModeLoopGoBackwards)
                bLoopFinished = (target.pev.frame - e.m_flEndFrame > 0.01f) or (e.m_flStartFrame - target.pev.frame > 0.01f);
            else
                bLoopFinished = e.m_flFramerate > 0 ? (target.pev.frame - e.m_flEndFrame > 0.01f) : (e.m_flEndFrame - target.pev.frame > 0.01f);
            
            if (bLoopFinished) {
                if (e.m_eEmoteMode == kModeOnce) {
                    DoEmote(plr, _Emote, _PartIdx + 1, _NoVerbose, false, false, false, false, false);
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
    }
    
    @g_dict_lpfnLoops[plr.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, _Player, _Target, @_Emote, _PartIdx, _LastFrame, @_Varargs);
}

void DoEmote(CBasePlayer@ _Player, CEmote _Emote, int _PartIdx, bool _NoVerbose, bool _IgnoreMovements, bool _ZeroSize, bool _ForceIdealActivities, bool _GaitSequenceIsTheSameAsSequence, bool _ForceInfiniteSequence) {
    CBaseMonster@ emoteEnt = cast<CBaseMonster@>(_Player);

    if (_PartIdx >= int(_Emote.m_aParts.size())) {
        if (_Emote.m_bLoop) {
            _PartIdx = 0;
        } else {
            return;
        }
    }
    
    CEmotePart e = _Emote.m_aParts[_PartIdx];
    
    if (e.m_bMixed) {
        if (!_NoVerbose) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Part: ' + _PartIdx + ', Sequence: ' + e.m_iSequence + ", Second sequence: " + e.m_iSecondSequence + " (Mixed & " + Emotes_UTIL_GetModeString(e.m_eEmoteMode) + ")" +
                ", Speed " + e.m_flFramerate + ", Frames: " + int(e.m_flStartFrame + 0.5f) + "-" + int(e.m_flEndFrame + 0.5f) + "\n");
        }
            
        emoteEnt.SetActivity(ACT_RELOAD);
        emoteEnt.SetGaitActivity(ACT_RELOAD);
        emoteEnt.pev.frame = e.m_flStartFrame;
        emoteEnt.pev.sequence = e.m_iSequence;
        emoteEnt.pev.gaitsequence = e.m_iSecondSequence;
        emoteEnt.ResetSequenceInfo();
        emoteEnt.ResetGaitSequenceInfo();
        emoteEnt.pev.framerate = e.m_flFramerate;
        
        CScheduledFunction@ func = g_dict_lpfnLoops[_Player.entindex()];
        if (func !is null) { // stop previous emote
            g_Scheduler.RemoveTimer(func);
        }
        @g_dict_lpfnLoops[_Player.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, EHandle(_Player), EHandle(emoteEnt), _Emote, _PartIdx, e.m_flStartFrame, CTrickyBoolVarargs(false, false, false, false, false, _NoVerbose));
        
        return;
    }
    
    if (!_Emote.m_bGaitOnly) {
        if (!_NoVerbose) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Part: ' + _PartIdx + ', Sequence: ' + e.m_iSequence + " (" + Emotes_UTIL_GetModeString(e.m_eEmoteMode) + ")" +
                ", Speed " + e.m_flFramerate + ", Frames: " + int(e.m_flStartFrame + 0.5f) + "-" + int(e.m_flEndFrame + 0.5f) + ", ");
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'IgnoreMovements: ' + (_IgnoreMovements || e.m_bIgnoreMovements_Chain ? "true" : "false") + ", ZeroSize: " + (_ZeroSize ? "true" : "false") + ", ForceIdealActivities: " + (_ForceIdealActivities ? "true" : "false") + ", ");
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'GaitSequenceIsTheSameAsSequence: ' + (_GaitSequenceIsTheSameAsSequence ? "true" : "false") + ", ForceInfiniteSequence: " + (_ForceInfiniteSequence ? "true" : "false") + "\n");
        }
        
        if (_ZeroSize) {
            Vector vecZero = Vector(0.0f, 0.0f, 0.0f);
        
            emoteEnt.pev.size = vecZero;
            emoteEnt.pev.mins = vecZero;
            emoteEnt.pev.maxs = vecZero;
        }
        
        emoteEnt.SetActivity(ACT_RELOAD);
        if (_GaitSequenceIsTheSameAsSequence) emoteEnt.SetGaitActivity(ACT_RELOAD);
        if (_ForceIdealActivities) {
            emoteEnt.m_IdealActivity = ACT_RELOAD;
            emoteEnt.m_movementActivity = ACT_RELOAD;
        }
        if (_IgnoreMovements || e.m_bIgnoreMovements_Chain) _Player.SetAnimation(PLAYER_SUPERJUMP);
        emoteEnt.pev.frame = e.m_flStartFrame;
        emoteEnt.pev.sequence = e.m_iSequence;
        if (_GaitSequenceIsTheSameAsSequence) emoteEnt.pev.gaitsequence = e.m_iSequence;
        emoteEnt.ResetSequenceInfo();
        if (_GaitSequenceIsTheSameAsSequence) emoteEnt.ResetGaitSequenceInfo();
        if (_ForceInfiniteSequence) {
            emoteEnt.m_fSequenceFinished = false;
            emoteEnt.m_fSequenceLoops = true;
        }
        emoteEnt.pev.framerate = e.m_flFramerate;
        
        CScheduledFunction@ func = g_dict_lpfnLoops[_Player.entindex()];
        if (func !is null) { // stop previous emote
            g_Scheduler.RemoveTimer(func);
        }
        @g_dict_lpfnLoops[_Player.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, EHandle(_Player), EHandle(emoteEnt), _Emote, _PartIdx, e.m_flStartFrame, CTrickyBoolVarargs(_IgnoreMovements, _ZeroSize, _ForceIdealActivities, _GaitSequenceIsTheSameAsSequence, _ForceInfiniteSequence, _NoVerbose));
    } else {
        if (!_NoVerbose) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Part: ' + _PartIdx + ', Sequence: ' + e.m_iSequence + " (GaitOnly & " + Emotes_UTIL_GetModeString(e.m_eEmoteMode) + ")" +
                ", Speed " + e.m_flFramerate + ", Frames: " + int(e.m_flStartFrame + 0.5f) + "-" + int(e.m_flEndFrame + 0.5f) + "\n");
        }
        
        emoteEnt.SetGaitActivity(ACT_RELOAD);
        emoteEnt.pev.frame = e.m_flStartFrame;
        emoteEnt.pev.gaitsequence = e.m_iSequence;
        emoteEnt.ResetGaitSequenceInfo();
        emoteEnt.pev.framerate = e.m_flFramerate;
        
        CScheduledFunction@ func = g_dict_lpfnLoops[_Player.entindex()];
        if (func !is null) { // stop previous emote
            g_Scheduler.RemoveTimer(func);
        }
        @g_dict_lpfnLoops[_Player.entindex()] = g_Scheduler.SetTimeout("Emotes_DoEmoteLoop", 0, EHandle(_Player), EHandle(emoteEnt), _Emote, _PartIdx, e.m_flStartFrame, CTrickyBoolVarargs(false, false, false, false, false, _NoVerbose));
    }
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
                CBaseMonster@ target = cast<CBaseMonster@>(_Player);
                target.m_flLastEventCheck = g_Engine.time + 1.0f;
                target.m_flLastGaitEventCheck = g_Engine.time + 1.0f;
                
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
        
            DoEmote(_Player, CEmote({CEmotePart(14, kModeFreeze, 0.0f, 120, 120)}, false), 0, noVerbose, true, false, true, false, true);
            return;
        } else if (szEmote == "lewd") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
        
            DoEmote(_Player, CEmote({CEmotePart(88, kModeLoopGoBackwards, 1.0f, 40, 70)}, false), 0, noVerbose, false, false, false, false, false);
            return;
        } else if (szEmote == "nigger") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
        
            DoEmote(_Player, CEmote({CEmotePart(17, kModeFreeze, 1.0f, 255, 255)}, false), 0, noVerbose, true, false, true, true, true);
            return;
        } else if (szEmote == "wave") {
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
            
            DoEmote(_Player, CEmote({CEmotePart(190, kModeOnce, 1.0f, 0, 255)}, false), 0, noVerbose, false, false, false, false, false);
            return;
        }
        
        if (szEmote == "generate") {
            if (_Args.ArgC() < 3) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'You must at least specify sequence number!\n');
                return;
            }
            
            string szSequence = _Args[2].ToLowercase();
        
            bool isGenerationalSeqNumeric = true;
            for (uint i = 0; i < szSequence.Length(); i++) {
                if (!isdigit(szSequence[i])) {
                    isGenerationalSeqNumeric = false;
                    break;
                }
            }
            
            if (!isGenerationalSeqNumeric) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'The passed sequence is not numeric, skipping...\n');
                return;
            }
            
            int seq = atoi(szSequence);
            
            float framerate = _Args.ArgC() >= 4 ? atof(_Args[3]) : 1.0f;
            float startFrame = (framerate >= 0 ? 0.0001f : 254.9999f);
            float endFrame = (framerate >= 0 ? 254.9999f : 0.0001f);
            if (seq > 255) {
                seq = 255;
            }
                
            startFrame = _Args.ArgC() >= 5 ? atof(_Args[4]) : startFrame;
            endFrame = _Args.ArgC() >= 6 ? atof(_Args[5]) : endFrame;
            
            array<CEmotePart> parts = CEmotePartGenerator(seq, startFrame, endFrame, framerate).Generate();
            if (parts.length() == 0) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, "Cannot continue playing emote: 'parts.length()' is 0.\n");
                
                return;
            }

            DoEmote(_Player, CEmote(parts, true), 0, true, false, false, false, false, false);
            
            bool noVerbose = false;
        
            for (int idx = 0; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
            
            if (!noVerbose) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, "Total parts: " + string(parts.length()) + ", Sequence: " + seq + " (Dynamic generational mode, loop), Speed: " + framerate + "\n");
            }
            
            return;
        }
        
        if (szEmote == "gaitonly") {
            if (_Args.ArgC() < 3) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'You must at least specify sequence number!\n');
                return;
            }
        
            string szSequence = _Args[2].ToLowercase();
        
            bool isGaitSeqNumeric = true;
            for (uint i = 0; i < szSequence.Length(); i++) {
                if (!isdigit(szSequence[i])) {
                    isGaitSeqNumeric = false;
                    break;
                }
            }
            
            if (!isGaitSeqNumeric) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'The passed sequence is not numeric, skipping...\n');
                return;
            }
            
            int seq = atoi(szSequence);
            
            int mode = kModeOnce;
            string szMode = _Args[3];
            if (szMode.ToLowercase() == "loop") {
                mode = kModeLoop;
            } else if (szMode.ToLowercase() == "iloop") {
                mode = kModeLoopGoBackwards;
            } else if (szMode.ToLowercase() == "freeze") {
                mode = kModeFreeze;
            }
        
            float framerate = _Args.ArgC() >= 5 ? atof(_Args[4]) : 1.0f;
            float startFrame = (framerate >= 0 ? 0.0001f : 254.9999f);
            float endFrame = (framerate >= 0 ? 254.9999f : 0.0001f);
            if (seq > 255) {
                seq = 255;
            }
                
            startFrame = _Args.ArgC() >= 6 ? atof(_Args[5]) : startFrame;
            endFrame = _Args.ArgC() >= 7 ? atof(_Args[6]) : endFrame;
            
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
            
            DoEmote(_Player, CEmote({CEmotePart(seq, mode, framerate, startFrame, endFrame)}, false, true), 0, noVerbose, false, false, false, false, false);

            return;
        }
        
        if (szEmote == "mixed") {
            if (_Args.ArgC() < 3) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'You must at least specify two sequence numbers!\n');
                return;
            }
        
            string szSequences = _Args[2].ToLowercase();
            if (szSequences.EndsWith("_")) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'You must at least specify two sequence numbers!\n');
                return;
            }
            
            array<string> aSequences = szSequences.Split("_");
            if (aSequences.length() != 2) {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Only two sequences may play at the same time.\n');
                return;
            }
            
            bool bFailed = false;
        
            for (uint idx = 0; idx < aSequences.length(); idx++) {
                string szSeq = aSequences[idx];
                bool isNumeric = true;
                for (uint i = 0; i < szSeq.Length(); i++) {
                    if (!isdigit(szSeq[i])) {
                        isNumeric = false;
                        break;
                    }
                }
                
                if (!isNumeric) {
                    g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Non-numeric sequence passed, skipping...\n');
                    bFailed = true;
                    break;
                }
            }
            
            if (bFailed) return;
        
            int iSequence1 = atoi(aSequences[0]);
            if (iSequence1 > 255)
                iSequence1 = 255;
                
            int iSequence2 = atoi(aSequences[1]);
            if (iSequence2 > 255)
                iSequence2 = 255;
                
            int mode = kModeOnce;
            string szMode = _Args[3];
            if (szMode.ToLowercase() == "loop") {
                mode = kModeLoop;
            } else if (szMode.ToLowercase() == "iloop") {
                mode = kModeLoopGoBackwards;
            } else if (szMode.ToLowercase() == "freeze") {
                mode = kModeFreeze;
            }
            
            float framerate = _Args.ArgC() >= 5 ? atof(_Args[4]) : 1.0f;
            float startFrame = (framerate >= 0 ? 0.0001f : 254.9999f);
            float endFrame = (framerate >= 0 ? 254.9999f : 0.0001f);
            startFrame = _Args.ArgC() >= 6 ? atof(_Args[5]) : startFrame;
            endFrame = _Args.ArgC() >= 7 ? atof(_Args[6]) : endFrame;
            
            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }
            
            DoEmote(_Player, CEmote({CEmotePart(iSequence1, mode, framerate, startFrame, endFrame, true, iSequence2)}, false), 0, noVerbose, false, false, false, false, false);
        
            return;
        } else if (szEmote == "chain") {
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
                
                parts.insertLast(CEmotePart(seq, mode, speed, startFrame, endFrame, false, 0, ignoreMovements));
            }

            bool noVerbose = false;
        
            for (int idx = 2; idx < _Args.ArgC(); idx++) {
                if (_Args[idx].ToLowercase() == "noverbose") {
                    noVerbose = true;
                    break;
                }
            }

            DoEmote(_Player, CEmote(parts, loopMode == "loop"), 0, noVerbose, false, false, false, false, false);
            
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
        bool forceIdealActivities = _Args.ArgC() >= 9 ? (atoi(_Args[8]) > 0) : false;
        bool gaitSequenceIsTheSameAsSequence = _Args.ArgC() >= 10 ? (atoi(_Args[9]) > 0) : ignoreMovements;
        bool forceInfiniteSequence = _Args.ArgC() >= 11 ? (atoi(_Args[10]) > 0) : false;
        
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

        DoEmote(_Player, CEmote({CEmotePart(seq, mode, framerate, startFrame, endFrame)}, false), 0, noVerbose, ignoreMovements, zeroSize, forceIdealActivities, gaitSequenceIsTheSameAsSequence, forceInfiniteSequence);
    } else {
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '----------------------------------Emote Commands----------------------------------\n\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e off/.e stop" to stop your emote.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e list" to list all named emotes.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e gaitOnly <sequence> [mode] [speed] [startFrame] [endFrame]" to run a sequence that plays only for gaitSequence.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e mixed <sequence>_<sequence2> [mode] [speed] [startFrame] [endFrame]" to run a mixed emote.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e chain <speed> <chain_mode> <sequence>_[speed]_[startFrame]_[endFrame]_[ignoreMovements] ..." for advanced combos.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e <sequence> [mode] [speed] [startFrame] [endFrame] [ignoreMovements] [zeroSize] [forceIdealActivities] ');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '{gaitSequenceIsTheSameAsSequence} [forceInfiniteSequence]" to run a sequence.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Type ".e generate <sequence> [speed] [startFrame] [endFrame] to generate a ".e chain" command with passed frames.\n');
    
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n<> = required. [] = optional. {} = default value depends on another value.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'Add "noVerbose" in any part of the command to disable verbose.\n\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<sequence> = 0-255. Most models have about 190 sequences.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<sequence2> = 0-255. Most models have about 190 sequences.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[mode] = once, freeze, loop, or iloop.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[speed] = Any number, even negative. The default speed is 1.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '<chain_mode> = once, loop, freezeend, loopend, or iloopend.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[startFrame/endFrame] = 0-255. This is like a percentage. Frame count in the model doesn\'t matter.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[ignoreMovements] = 0/1. Do emote even when doing sth.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[zeroSize] = 0/1. Makes your size absolutely zero. (useful when playing death animations)\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[forceIdealActivities] = 0/1. Forces "ideal" activities (m_IdealActivity, m_movementActivity) to be the same as m_Activity.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '{gaitSequenceIsTheSameAsSequence} = 0/1. Forces entvars_t#gaitsequence to be the same as ');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, 'entvars_t#sequence. Also makes m_GaitActivity same as m_Activity.\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '[forceInfiniteSequence] = 0/1. Forces CBaseMonster#m_fSequenceFinished to be false and CBaseMonster#m_fSequenceLoops to be true.');
        
        //Redundant \n here is because we achieve max length of the string in previous ClientPrint call.
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n\nUnless specified the value, gaitSequenceIsTheSameAsSequence is true when ignoreMovements is true. Otherwise it is false.\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\nExamples:\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 0.5\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 15 iloop 0.5 0 50\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 17 freeze 1 255 255 1 1 1 1 0\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e 10 iloop 1 20 30 1\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e gaitOnly 8 freeze 1 255 255\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e mixed 16_17 freeze 1 255 255\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 2 loop 13 14 15\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 once 13 14_-1\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 iloopend 182 183 184 185\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e chain 1 freezeend 15_0.1_0_50 16_-1_100_10\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '.e generate 9\n');
        
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\nBe careful! The syntax of the command has changed: ".e anal" -> ".e 14 freeze 0 120 120 1 0 0 0 0"\n');
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n".e 14 freeze 1 120 120 1" will not work! Since the gaitSequenceIsTheSameAsSequence is true because ignoreMovements is true.\n');
            
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTCONSOLE, '\n----------------------------------------------------------------------------------\n');
    }
}

CClientCommand _emote("e", "Emote commands", @CMD_Emote);

void CMD_Emote(const CCommand@ args) {
    //string mapname = g_Engine.mapname;
    
    CBasePlayer@ player = g_ConCommandSystem.GetCurrentPlayer();

    //Implement that also :)
    /*if (mapname.Find("zm") == 0 or mapname.Find("hns") == 0 or mapname == "ctf_warforts") {
        if (!Emotes_IsPlayerAllowedToPlayEmotesOnAnyMap(g_EngineFuncs.GetPlayerAuthId(player.edict()))) {
            g_PlayerFuncs.ClientPrint(player, HUD_PRINTCONSOLE, "Unknown command: .e\n");
            return;
        }
    }*/

    Emotes_DoEmoteConCmd(player, args);
}
