#ifndef MENUQC
#include "anim.qc"
#include "animdecide.qc"
#include "ent_cs.qc"
#include "net_notice.qc"
#endif

#include "mapinfo.qc"
#include "playerstats.qc"
#include "util.qc"

#ifndef CSQC
#include "campaign_file.qc"
#include "campaign_setup.qc"
#endif

#ifndef MENUQC
#include "physics.qc"
#include "movetypes/include.qc"
#include "triggers/include.qc"
#include "viewloc.qc"
#endif

#ifndef MENUQC
#include "minigames/minigames.qc"
#endif
#ifdef CSQC
#include "minigames/cl_minigames.qc"
#endif
#ifdef SVQC
#include "minigames/sv_minigames.qc"
#endif

#include "debug.qh"

#ifndef MENUQC
#include "deathtypes/all.qc"
#include "effects/all.qc"
#include "impulses/all.qc"
#include "notifications.qc"
#endif

#include "items/all.qc"
    #include "weapons/all.qc"
        #include "monsters/all.qc"
        #include "turrets/all.qc"
        #include "vehicles/all.qc"

#include "mutators/all.qc"
    #include "gamemodes/all.qc"
