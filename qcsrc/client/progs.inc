#include "../lib/_all.inc"
#include "_all.qh"

#include "../common/effects/qc/all.qc"

#include "announcer.qc"
#include "bgmscript.qc"
#include "csqcmodel_hooks.qc"
#include "hook.qc"
#include "hud/all.qc"
#include "main.qc"
#include "mapvoting.qc"
#include "miscfunctions.qc"
#include "movelib.qc"
#include "player_skeleton.qc"
#include "scoreboard.qc"
#include "shownames.qc"
#include "teamradar.qc"
#include "tuba.qc"
#include "t_items.qc"
#include "view.qc"
#include "wall.qc"

#include "commands/all.qc"

#include "weapons/projectile.qc" // TODO

#include "../common/anim.qc"
#include "../common/animdecide.qc"
#include "../common/effects/effectinfo.qc"
#include "../common/ent_cs.qc"
#include "../common/mapinfo.qc"
#include "../common/movetypes/include.qc"
#include "../common/net_notice.qc"
#include "../common/notifications.qc"
#include "../common/physics.qc"
#include "../common/playerstats.qc"
#include "../common/util.qc"

#include "../common/viewloc.qc"

#include "../common/minigames/minigames.qc"
#include "../common/minigames/cl_minigames.qc"

#include "../common/deathtypes/all.qc"
#include "../common/effects/all.qc"
#include "../common/gamemodes/all.qc"
#include "../common/impulses/all.qc"
#include "../common/items/all.qc"
#include "../common/monsters/all.qc"
#include "../common/mutators/all.qc"
#include "../common/turrets/all.qc"
#include "../common/vehicles/all.qc"
#include "../common/weapons/all.qc"

#include "../common/turrets/cl_turrets.qc"

#include "../common/triggers/include.qc"

#include "../lib/csqcmodel/cl_model.qc"
#include "../lib/csqcmodel/cl_player.qc"
#include "../lib/csqcmodel/interpolate.qc"

#include "../lib/warpzone/anglestransform.qc"
#include "../lib/warpzone/client.qc"
#include "../lib/warpzone/common.qc"
#include "../lib/warpzone/server.qc"
#include "../lib/warpzone/util_server.qc"

#if BUILD_MOD
#include "../../mod/client/progs.inc"
#endif
