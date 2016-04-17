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

#define USING(name, T) typedef T name

#include "bool.qh"
#include "int.qh"

#include "macro.qh"

#if NDEBUG
	#define TC(T, sym) MACRO_BEGIN MACRO_END
#else
	#define TC(T, sym) \
		MACRO_BEGIN \
		if (!is_##T(sym)) \
		{ \
			LOG_WARNINGF("Type check failed: " #sym " :: " #T); \
			isnt_##T(sym); \
		} \
		MACRO_END
#endif

#define   is_float(this) (true || ftoe(this))
#define isnt_float(this)
#define   is_vector(this) (true || vtos(this))
#define isnt_vector(this)
#define   is_string(this) (true || stof(this))
#define isnt_string(this)
#define   is_entity(this) (true || etof(this))
#define isnt_entity(this)
bool      is_int(float this) { return this == floor(this); }
void    isnt_int(float this) { print(ftos(this)); }
bool      is_bool(float this) { return this == true || this == false; }
void    isnt_bool(float this) { print(ftos(this)); }

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

#ifdef MENUQC
	void _m_init();
	void m_init() { if (_m_init) _m_init(); }
	#define m_init _m_init

	void _m_shutdown();
	void m_shutdown() { if (_m_shutdown) _m_shutdown(); }
	#define m_shutdown _m_shutdown

	void _m_draw(float width, float height);
	void m_draw(float width, float height) { if (_m_draw) _m_draw(width, height); }
	#define m_draw _m_draw

	void _m_keydown(int keynr, int ascii);
	void m_keydown(int keynr, int ascii) { if (_m_keydown) _m_keydown(keynr, ascii); }
	#define m_keydown _m_keydown

	void _m_toggle(int mode);
	void m_toggle(int mode) { if (_m_toggle) _m_toggle(mode); }
	#define m_toggle _m_toggle
#endif

#ifdef SVQC
	void _main();
	void main() { if (_main) _main(); }
	#define main _main

    void _SV_Shutdown();
    void SV_Shutdown() { if (_SV_Shutdown) _SV_Shutdown(); }
    #define SV_Shutdown _SV_Shutdown

	void _StartFrame();
	void StartFrame() { if (_StartFrame) _StartFrame(); }
	#define StartFrame _StartFrame

	void _SetNewParms();
	void SetNewParms() { if (_SetNewParms) _SetNewParms(); }
	#define SetNewParms _SetNewParms

	void _SetChangeParms();
	void SetChangeParms() { if (_SetChangeParms) _SetChangeParms(); }
	#define SetChangeParms _SetChangeParms

	void _ClientConnect();
	void ClientConnect() { if (_ClientConnect) _ClientConnect(); }
	#define ClientConnect _ClientConnect

	void _ClientDisconnect();
	void ClientDisconnect() { if (_ClientDisconnect) _ClientDisconnect(); }
	#define ClientDisconnect _ClientDisconnect

	void _PutClientInServer();
	void PutClientInServer() { if (_PutClientInServer) _PutClientInServer(); }
	#define PutClientInServer _PutClientInServer

	void _ClientKill();
	void ClientKill() { if (_ClientKill) _ClientKill(); }
	#define ClientKill _ClientKill

	void _PlayerPreThink(entity this);
	void PlayerPreThink() { SELFPARAM(); if (_PlayerPreThink) _PlayerPreThink(this); }
	#define PlayerPreThink _PlayerPreThink

	void _PlayerPostThink();
	void PlayerPostThink() { if (_PlayerPostThink) _PlayerPostThink(); }
	#define PlayerPostThink _PlayerPostThink
#endif

#ifdef CSQC
	void _CSQC_Init();
	void CSQC_Init() {
        static_init();
        static_init_late();
        static_init_precache();
        if (_CSQC_Init) _CSQC_Init();
    }
	#define CSQC_Init _CSQC_Init

    void _CSQC_Shutdown();
    void CSQC_Shutdown() { if (_CSQC_Shutdown) _CSQC_Shutdown(); }
    #define CSQC_Shutdown _CSQC_Shutdown

	void _CSQC_UpdateView(float w, float h);
	void CSQC_UpdateView(float w, float h) { if (_CSQC_UpdateView) _CSQC_UpdateView(w, h); }
	#define CSQC_UpdateView _CSQC_UpdateView

	bool _CSQC_InputEvent(int inputType, float nPrimary, float nSecondary);
	bool CSQC_InputEvent(int inputType, float nPrimary, float nSecondary)
	{
		return _CSQC_InputEvent ? _CSQC_InputEvent(inputType, nPrimary, nSecondary) : false;
	}
	#define CSQC_InputEvent _CSQC_InputEvent

	bool _CSQC_ConsoleCommand(string s);
	bool CSQC_ConsoleCommand(string s) { return _CSQC_ConsoleCommand ? _CSQC_ConsoleCommand(s) : false; }
	#define CSQC_ConsoleCommand _CSQC_ConsoleCommand

#endif
