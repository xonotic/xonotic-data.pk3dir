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
#include "player_skeleton.qc"
#include "scoreboard.qc"
#include "shownames.qc"
#include "teamradar.qc"
#include "tuba.qc"
#include "view.qc"
#include "wall.qc"

#include "commands/all.qc"

#include "weapons/projectile.qc" // TODO

#include "../common/_all.inc"

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
