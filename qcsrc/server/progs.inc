#ifdef FTEQCC

// To compile with fteqcc, run:
// QCCFLAGS_WERROR='-TDP -O3' make -C data/xonotic-data.pk3dir/qcsrc ../progs.dat QCC=$HOME/src/fteqw/engine/qclib/fteqcc.bin

// https://github.com/DarkPlacesEngine/DarkPlaces/pull/215
#pragma opcode enable GLOBALADDRESS
#pragma opcode enable ADD_PIW
#pragma opcode enable LOADP_F LOADP_ENT LOADP_FLD LOADP_FNC LOADP_I LOADP_S LOADP_V
#pragma opcode enable C_FTOI
#pragma opcode enable LOADA_F LOADA_ENT LOADA_FLD LOADA_FNC LOADA_I LOADA_S LOADA_V

// https://github.com/DarkPlacesEngine/DarkPlaces/pull/237
#pragma opcode enable RSHIFT_I LSHIFT_I
#pragma opcode enable LE_U LT_U DIV_U RSHIFT_U

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
