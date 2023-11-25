# Emotes

Once this was supposed to be a replacement for great ".e 17 freeze 1 255 255 1" that gave us godmode in Sw1ft's server.
Even though it turned the game into mess, it still was fun.
But some explorations through server code led me to some interesting results: thus making an advanced version of wootguy's emotes plugin.

An offtop theme that I didn't want to mention there but someone told me to do so:
The "ignoreMovements" was broken in Sw1ft's version of emotes. Normally ".e 17 freeze 1 255 255 1" should NOT make your gait sequence same as sequence, i.e only your sequence should be 17.
Resetting current animation using `plr.SetAnimation(PLAYER_SUPERJUMP)` led me to right implementation of "ignoreMovements", but in case to make the "godmode" exploit work I decided to make "gaitSequenceIsTheSameAsSequence" setting, thus making my "ignoreMovements" broken too (read more ingame, type .e for help)
The plugin is pretty self-explanatory, just read into the help that ".e" command provides and you will understand quite many things.

# NO CHANGELOG WILL BE PROVIDED. CHECKOUT DIFFERENCES BETWEEN ORIGINAL PLUGIN AND MY VERSION INGAME.
