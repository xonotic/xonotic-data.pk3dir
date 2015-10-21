#ifndef GAMEMODE_NEXBALL_WEAPON_H
#define GAMEMODE_NEXBALL_WEAPON_H

CLASS(BallStealer, PortoLaunch)
/* flags     */ ATTRIB(BallStealer, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(BallStealer, impulse, int, 0);
/* refname   */ ATTRIB(BallStealer, netname, string, "ballstealer");
/* wepname   */ ATTRIB(BallStealer, message, string, _("Ball Stealer"));
ENDCLASS(BallStealer)
REGISTER_WEAPON(NEXBALL, NEW(BallStealer));

#endif
