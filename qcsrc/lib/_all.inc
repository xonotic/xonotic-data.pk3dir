#ifndef NOCOMPAT
	#define COMPAT_NO_MOD_IS_XONOTIC
#endif

#include "compiler.qh"

#ifndef QCC_SUPPORT_INT
	#define int float
#endif

#ifndef QCC_SUPPORT_BOOL
	#define bool float
#endif

#if defined(CSQC)
	#include <dpdefs/csprogsdefs.qh>
	#include <dpdefs/keycodes.qh>
#elif defined(SVQC)
	#include <server/sys-pre.qh>
	#include <dpdefs/progsdefs.qh>
	#include <dpdefs/dpextensions.qh>
	#include <server/sys-post.qh>
#elif defined(MENUQC)
	#include <dpdefs/menudefs.qh>
	#include <dpdefs/keycodes.qh>
#endif

#include "bool.qh"
#include "int.qh"

#include "macro.qh"

#ifndef NDEBUG
    #define TC(T, sym) MACRO_BEGIN \
        if (!is_##T(sym)) LOG_WARNINGF("Type check failed: " #sym " :: " #T); \
    MACRO_END
#else
    #define TC(T, sym) MACRO_BEGIN MACRO_END
#endif

bool is_int(float f) { return f == f | 0; }
bool is_bool(float f) { return f == true || f == false; }

#include "warpzone/mathlib.qc"

#include "accumulate.qh"
#include "angle.qc"
#include "arraylist.qh"
#include "bits.qh"
#include "color.qh"
#include "counting.qh"
#include "cvar.qh"
#include "defer.qh"
#include "draw.qh"
#include "enumclass.qh"
#include "file.qh"
#include "functional.qh"
#include "i18n.qh"
#include "iter.qh"
#include "lazy.qh"
#include "linkedlist.qh"
#include "log.qh"
#include "map.qh"
#include "markdown.qh"
#include "math.qh"
#include "misc.qh"
#include "net.qh"
#include "nil.qh"
#include "noise.qh"
#include "oo.qh"
#include "p2mathlib.qc"
#include "progname.qh"
#include "random.qc"
#include "registry.qh"
#include "registry_net.qh"
#include "replicate.qh"
#include "self.qh"
#include "sortlist.qc"
#include "sort.qh"
#include "spawnfunc.qh"
#include "static.qh"
#include "stats.qh"
#include "string.qh"
#include "struct.qh"
#include "test.qc"
#include "unsafe.qh"
#include "urllib.qc"
#include "vector.qh"
#include "yenc.qh"
