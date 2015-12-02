#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "../../lib/warpzone/anglestransform.qh"
    #include "../../lib/warpzone/common.qh"
    #include "../../lib/warpzone/util_server.qh"
    #include "../../lib/warpzone/server.qh"
    #include "../../common/constants.qh"
    #include "../../common/stats.qh"
    #include "../../common/teams.qh"
    #include "../../common/util.qh"
    #include "../../common/command/markup.qh"
    #include "../../common/command/rpn.qh"
    #include "../../common/command/generic.qh"
    #include "../../common/command/command.qh"
    #include "../../common/net_notice.qh"
    #include "../../common/animdecide.qh"
    #include "../../common/monsters/all.qh"
    #include "../../common/monsters/sv_monsters.qh"
    #include "../../common/monsters/spawn.qh"
    #include "../../common/weapons/config.qh"
    #include "../../common/weapons/all.qh"
    #include "../weapons/accuracy.qh"
    #include "../weapons/common.qh"
    #include "../weapons/csqcprojectile.qh"
    #include "../weapons/hitplot.qh"
    #include "../weapons/selection.qh"
    #include "../weapons/spawning.qh"
    #include "../weapons/throwing.qh"
    #include "../weapons/tracing.qh"
    #include "../weapons/weaponstats.qh"
    #include "../weapons/weaponsystem.qh"
    #include "../t_items.qh"
    #include "../autocvars.qh"
    #include "../constants.qh"
    #include "../defs.qh"
    #include "../../common/notifications.qh"
    #include "../../common/deathtypes/all.qh"
    #include "all.qh"
    #include "../../common/turrets/sv_turrets.qh"
    #include "../../common/vehicles/all.qh"
    #include "../campaign.qh"
    #include "../../common/campaign_common.qh"
    #include "../../common/mapinfo.qh"
    #include "../command/common.qh"
    #include "../command/banning.qh"
    #include "../command/radarmap.qh"
    #include "../command/vote.qh"
    #include "../command/getreplies.qh"
    #include "../command/cmd.qh"
    #include "../command/sv_cmd.qh"
    #include "../../common/csqcmodel_settings.qh"
    #include "../../lib/csqcmodel/common.qh"
    #include "../../lib/csqcmodel/sv_model.qh"
    #include "../anticheat.qh"
    #include "../cheats.qh"
    #include "../../common/playerstats.qh"
    #include "../portals.qh"
    #include "../g_hook.qh"
    #include "../scores.qh"
    #include "../spawnpoints.qh"
    #include "../mapvoting.qh"
    #include "../ipban.qh"
    #include "../race.qh"
    #include "../antilag.qh"
    #include "../playerdemo.qh"
    #include "../round_handler.qh"
    #include "../item_key.qh"
    #include "../pathlib/pathlib.qh"
    #include "../../common/vehicles/all.qh"
#endif

#include "all.qh"

STATIC_INIT_LATE(Gametype) {
    Gametype g = MapInfo_Type(MapInfo_CurrentGametype());
    if (g) {
        for (string _s = g.m_mutators; _s != ""; _s = cdr(_s)) {
            string s = car(_s);
            FOREACH(Mutators, it.m_name == s, LAMBDA(Mutator_Add(it); break));
        }
    }
}

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION
