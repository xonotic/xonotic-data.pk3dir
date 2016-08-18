#ifndef DEBUGPATHING
	#define DEBUGPATHING 0
#endif

#include <lib/_all.inc>

#if XONOTIC

#include "_all.qh"

#include "../server/_mod.inc"
#include "bot/_mod.inc"
#include "command/_mod.inc"
#include "mutators/_mod.inc"
#include "pathlib/_all.inc"
#include "weapons/_mod.inc"

#include <common/_all.inc>
#include <common/effects/qc/all.qc>

#include <lib/csqcmodel/sv_model.qc>

#include <lib/warpzone/anglestransform.qc>
#include <lib/warpzone/common.qc>
#include <lib/warpzone/server.qc>
#include <lib/warpzone/util_server.qc>

#endif

#include <ecs/_lib.inc>

#if BUILD_MOD
#include "../../mod/server/progs.inc"
#endif
