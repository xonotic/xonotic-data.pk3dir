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

#include <dpdefs/pre.qh>

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

#include <dpdefs/post.qh>

#define USING(name, T) typedef T name

#include "bool.qh"
#include "int.qh"

#include "macro.qh"

#if NDEBUG
    #define TC(T, sym) MACRO_BEGIN MACRO_END
#else
    #define TC(T, sym) MACRO_BEGIN \
        if (!is_##T(sym)) { \
            LOG_WARNINGF("Type check failed: " #sym " :: " #T); \
            isnt_##T(sym); \
        } \
    MACRO_END
#endif

#define   is_float(        this) (true || ftoe(this))
#define isnt_float(        this)
#define   is_vector(       this) (true || vtos(this))
#define isnt_vector(       this)
#define   is_string(       this) (true || stof(this))
#define isnt_string(       this)
#define   is_entity(       this) (true || etof(this))
#define isnt_entity(       this)
bool      is_int(    float this) { return this == floor(this); }
void    isnt_int(    float this) { print(ftos(this)); }
bool      is_bool(   float this) { return this == true || this == false; }
void    isnt_bool(   float this) { print(ftos(this)); }

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
#include "json.qc"
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

#include "matrix/_mod.inc"
