#ifndef NOCOMPAT
	#define COMPAT_NO_MOD_IS_XONOTIC
#endif

#ifdef CSQC
#define IS_CSQC 1
#else
#define IS_CSQC 0
#endif

#ifdef SVQC
#define IS_SVQC 1
#else
#define IS_SVQC 0
#endif

#include "compiler.qh"

#ifndef QCC_SUPPORT_INT
	#define int float
#endif

#ifndef QCC_SUPPORT_BOOL
	#define bool float
#endif

#ifndef QCC_SUPPORT_ACCUMULATE
	#warning "QCC does not support accumulate, may not compile correctly"
	#define ACCUMULATE
#else
	#define ACCUMULATE [[accumulate]]
#endif

#ifndef QCC_SUPPORT_ERASEABLE
	#define ERASEABLE
#else
	#define ERASEABLE [[eraseable]]
#endif

#ifndef QCC_SUPPORT_ALIAS
    #warning "QCC does not support alias, may not compile correctly"
    #define ALIAS(var)
#else
    #define ALIAS(var) [[alias(var)]]
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

#ifndef QCC_SUPPORT_POW
    #define pow(a, b) pow(a, b)
#else
    #define pow(a, b) ((a) ** (b))
#endif

#include "self.qh"

#define USING(name, T) typedef T name

#include "bool.qh"
#include "int.qh"

#include "macro.qh"

#if NDEBUG
	#define TC(T, sym) MACRO_BEGIN MACRO_END
#else
	#define TC(T, sym) MACRO_BEGIN \
		if (!is_##T(sym)) { \
			LOG_WARNF("Type check failed: " #sym " :: " #T); \
			isnt_##T(sym); \
		} \
	MACRO_END
#endif

#if !(NDEBUG)
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
#endif

#include "warpzone/mathlib.qc"

// needs to be included before any of the functions which use globals are called
#include "deglobalization.qh"

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
#include "float.qh"
#include "functional.qh"
#include "i18n.qh"
#include "intrusivelist.qh"
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
#include "promise.qc"
#include "random.qc"
#include "registry.qh"
#include "registry_net.qh"
#include "replicate.qh"
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

#if XONOTIC
	#include "matrix/_mod.inc"
#endif

#ifndef SVQC
#define objerror_safe(e)
#else
void make_safe_for_remove(entity this);
    #define objerror_safe(e) make_safe_for_remove(e)
#endif

#define objerror(this, msg) MACRO_BEGIN \
	LOG_WARN("======OBJECT ERROR======"); \
	entity _e = (this); \
	eprint(_e); \
	objerror_safe(_e); \
	delete(_e); \
	LOG_WARNF("%s OBJECT ERROR in %s:\n%s\nTip: read above for entity information", PROGNAME, __FUNC__, msg); \
MACRO_END

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
	bool _StartFrame_init;
	void spawnfunc_worldspawn(entity);
	void StartFrame() {
		if (!_StartFrame_init) {
			_StartFrame_init = true;
			float oldtime = time; time = 1;
			__spawnfunc_expecting = 2; NULL.__spawnfunc_constructor(NULL);
			time = oldtime;
        }
        if (_StartFrame) _StartFrame();
	}
	#define StartFrame _StartFrame

	void _SetNewParms();
	void SetNewParms() { if (_SetNewParms) _SetNewParms(); }
	#define SetNewParms _SetNewParms

	void _SetChangeParms(entity this);
	void SetChangeParms() { ENGINE_EVENT(); if (_SetChangeParms) _SetChangeParms(this); }
	#define SetChangeParms _SetChangeParms

#ifdef DP_EXT_PRECONNECT
	void _ClientPreConnect(entity this);
	void ClientPreConnect() { ENGINE_EVENT(); if (_ClientPreConnect) _ClientPreConnect(this); }
	#define ClientPreConnect _ClientPreConnect
#endif

	void _ClientConnect(entity this);
	void ClientConnect() { ENGINE_EVENT(); if (_ClientConnect) _ClientConnect(this); }
	#define ClientConnect _ClientConnect

	void _ClientDisconnect(entity this);
	void ClientDisconnect() { ENGINE_EVENT(); if (_ClientDisconnect) _ClientDisconnect(this); }
	#define ClientDisconnect _ClientDisconnect

	void _PutClientInServer(entity this);
	void PutClientInServer() { ENGINE_EVENT(); if (_PutClientInServer) _PutClientInServer(this); }
	#define PutClientInServer _PutClientInServer

	void _ClientKill(entity this);
	void ClientKill() { ENGINE_EVENT(); if (_ClientKill) _ClientKill(this); }
	#define ClientKill _ClientKill

	void _PlayerPreThink(entity this);
	void PlayerPreThink() { ENGINE_EVENT(); if (_PlayerPreThink) _PlayerPreThink(this); }
	#define PlayerPreThink _PlayerPreThink

	void _PlayerPostThink(entity this);
	void PlayerPostThink() { ENGINE_EVENT(); if (_PlayerPostThink) _PlayerPostThink(this); }
	#define PlayerPostThink _PlayerPostThink

	void _SV_PlayerPhysics(entity this);
	void SV_PlayerPhysics() { ENGINE_EVENT(); if (_SV_PlayerPhysics) _SV_PlayerPhysics(this); }
	#define SV_PlayerPhysics _SV_PlayerPhysics

	void _SV_OnEntityPreSpawnFunction(entity this);
	void SV_OnEntityPreSpawnFunction()
	{
		ENGINE_EVENT();
		__spawnfunc_expecting = true;
		__spawnfunc_expect = this;
	}
	#define SV_OnEntityPreSpawnFunction _SV_OnEntityPreSpawnFunction

	void _SV_ChangeTeam(entity this, int _color);
	void SV_ChangeTeam(int _color) { ENGINE_EVENT(); if (_SV_ChangeTeam) _SV_ChangeTeam(this, _color); }
	#define SV_ChangeTeam _SV_ChangeTeam

	void _SV_ParseClientCommand(entity this, string command);
	void SV_ParseClientCommand(string command)
	{
		ENGINE_EVENT();
		if (_SV_ParseClientCommand) _SV_ParseClientCommand(this, command);
	}
	#define SV_ParseClientCommand _SV_ParseClientCommand
#endif

#ifdef CSQC
	void _CSQC_Init(float apilevel, string enginename, float engineversion);
	void CSQC_Init(float apilevel, string enginename, float engineversion) { if (_CSQC_Init) _CSQC_Init(apilevel, enginename, engineversion); }
	#define CSQC_Init _CSQC_Init

	void _CSQC_Shutdown();
	void CSQC_Shutdown() { if (_CSQC_Shutdown) _CSQC_Shutdown(); }
	#define CSQC_Shutdown _CSQC_Shutdown

	void _CSQC_UpdateView(entity this, float w, float h, bool notmenu);
	void CSQC_UpdateView(float w, float h, bool notmenu) { ENGINE_EVENT(); if (_CSQC_UpdateView) _CSQC_UpdateView(this, w, h, notmenu); }
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

	void _CSQC_Ent_Update(entity this, bool isNew);
	void CSQC_Ent_Update(bool isNew) { ENGINE_EVENT(); if (_CSQC_Ent_Update) _CSQC_Ent_Update(this, isNew); }
	#define CSQC_Ent_Update _CSQC_Ent_Update

	void _CSQC_Ent_Remove(entity this);
	void CSQC_Ent_Remove() { ENGINE_EVENT(); if (_CSQC_Ent_Remove) _CSQC_Ent_Remove(this); }
	#define CSQC_Ent_Remove _CSQC_Ent_Remove
#endif
#undef ENGINE_EVENT

#if XONOTIC
#ifdef GAMEQC
	#include <ecs/_mod.qh>
#endif
#endif
