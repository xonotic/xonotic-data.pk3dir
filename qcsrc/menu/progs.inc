#include "../lib/_all.inc"

#define world NULL

#include "classes.qc"

#include "draw.qc"
#include "menu.qc"

#include "command/all.qc"

#include "xonotic/util.qc"

#include "../common/campaign_file.qc"
#include "../common/campaign_setup.qc"
#include "../common/mapinfo.qc"
#include "../common/playerstats.qc"
#include "../common/util.qc"
#include "../common/debug.qh"

#include "../common/items/all.qc"
#include "../common/monsters/all.qc"
#include "../common/mutators/all.qc"
#include "../common/vehicles/all.qc"
#include "../common/weapons/all.qc"

#if BUILD_MOD
#include "../../mod/menu/progs.inc"
#endif
