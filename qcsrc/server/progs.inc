#ifdef FTEQCC

// To compile with fteqcc, run:
// QCCFLAGS_WERROR='-O3' make -C data/xonotic-data.pk3dir/qcsrc ../progs.dat QCC=$HOME/src/fteqw/engine/qclib/fteqcc.bin
#pragma target DP_20250104

#endif

#include <lib/_all.inc>

#if XONOTIC

#include <server/_mod.inc>

#include <common/_all.inc>
#include <common/effects/qc/_mod.inc>

#include <lib/csqcmodel/sv_model.qc>

#include <lib/warpzone/anglestransform.qc>
#include <lib/warpzone/common.qc>
#include <lib/warpzone/server.qc>
#include <lib/warpzone/util_server.qc>

#include <ecs/_mod.inc>
#endif

#ifdef BUILD_MOD
#include <mod/server/progs.inc>
#endif
