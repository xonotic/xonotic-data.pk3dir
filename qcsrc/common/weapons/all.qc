#include "all.qh"
#ifndef WEAPONS_ALL_C
#define WEAPONS_ALL_C

#if defined(CSQC)
	#include <client/main.qh>
	#include <common/constants.qh>
	#include <common/deathtypes/all.qh>
	#include <common/physics/movetypes/movetypes.qh>
	#include <common/stats.qh>
	#include <common/util.qh>
	#include <common/weapons/calculations.qc>
	#include <common/weapons/weapon/_mod.inc>
	#include <lib/csqcmodel/cl_model.qh>
	#include <lib/csqcmodel/interpolate.qh>
	#include <lib/warpzone/anglestransform.qh>
	#include <lib/warpzone/client.qh>
	#include <lib/warpzone/common.qh>
#elif defined(MENUQC)
	#include <common/weapons/weapon/_mod.inc>
#elif defined(SVQC)
	#include <common/constants.qh>
	#include <common/deathtypes/all.qh>
	#include <common/items/_mod.qh>
	#include <common/mapinfo.qh>
	#include <common/monsters/_mod.qh>
	#include <common/notifications/all.qh>
	#include <common/stats.qh>
	#include <common/teams.qh>
	#include <common/util.qh>
	#include <common/weapons/calculations.qc>
	#include <common/weapons/config.qc>
	#include <common/weapons/config.qh>
	#include <common/weapons/weapon/_mod.inc>
	#include <lib/csqcmodel/sv_model.qh>
	#include <lib/warpzone/anglestransform.qh>
	#include <lib/warpzone/common.qh>
	#include <lib/warpzone/server.qh>
	#include <lib/warpzone/util_server.qh>
	#include <server/command/_mod.qh>
	#include <server/hook.qh>
	#include <server/items/spawning.qh>
	#include <server/mutators/_mod.qh>
	#include <server/portals.qh>
	#include <server/weapons/common.qh>
	#include <server/weapons/csqcprojectile.qh>
	#include <server/weapons/tracing.qh>
#endif


// WEAPON PLUGIN SYSTEM

WepSet _WepSet_FromWeapon(int a)
{
	a -= WEP_FIRST;
	if (REGISTRY_MAX(Weapons) > 24)
		if (a >= 24)
		{
			a -= 24;
			if (REGISTRY_MAX(Weapons) > 48)
				if (a >= 24)
				{
					a -= 24;
					return '0 0 1' * BIT(a);
				}
			return '0 1 0' * BIT(a);
		}
	return '1 0 0' * BIT(a);
}
#ifdef SVQC
	void WriteWepSet(float dst, WepSet w)
	{
		if (REGISTRY_MAX(Weapons) > 48) WriteInt72_t(dst, w);
		else if (REGISTRY_MAX(Weapons) > 24) WriteInt48_t(dst, w);
		else WriteInt24_t(dst, w.x);
	}
#endif
#ifdef CSQC
	WepSet WepSet_GetFromStat()
	{
		return STAT(WEAPONS);
	}
	WepSet WepSet_GetFromStat_InMap()
	{
		return STAT(WEAPONSINMAP);
	}
	WepSet ReadWepSet()
	{
		if (REGISTRY_MAX(Weapons) > 48) return ReadInt72_t();
		if (REGISTRY_MAX(Weapons) > 24) return ReadInt48_t();
		return ReadInt24_t() * '1 0 0';
	}
#endif

string W_FixWeaponOrder(string order, float complete)
{
	return fixPriorityList(order, WEP_FIRST, WEP_LAST, WEP_IMPULSE_BEGIN - WEP_FIRST, complete);
}
string W_NameWeaponOrder_MapFunc(string s)
{
	int i = stof(s);
	if (s == "0" || i)
	{
		entity wi = REGISTRY_GET(Weapons, i);
		if (wi != WEP_Null) return wi.netname;
	}
	return s;
}

string W_NameWeaponOrder(string order)
{
	return mapPriorityList(order, W_NameWeaponOrder_MapFunc);
}
string W_NumberWeaponOrder_MapFunc(string s)
{
	if (s == "0" || stof(s)) return s;
	FOREACH(Weapons, it != WEP_Null && (it.netname == s || it.m_deprecated_netname == s), return ftos(i));
	return s;
}
string W_NumberWeaponOrder(string order)
{
	return mapPriorityList(order, W_NumberWeaponOrder_MapFunc);
}

float W_FixWeaponOrder_BuildImpulseList_buf[REGISTRY_MAX(Weapons)];
string W_FixWeaponOrder_BuildImpulseList_order;
void W_FixWeaponOrder_BuildImpulseList_swap(int i, int j, entity pass)
{
	float h;
	h = W_FixWeaponOrder_BuildImpulseList_buf[i];
	W_FixWeaponOrder_BuildImpulseList_buf[i] = W_FixWeaponOrder_BuildImpulseList_buf[j];
	W_FixWeaponOrder_BuildImpulseList_buf[j] = h;
}
float W_FixWeaponOrder_BuildImpulseList_cmp(int i, int j, entity pass)
{
	int si = W_FixWeaponOrder_BuildImpulseList_buf[i];
	Weapon e1 = REGISTRY_GET(Weapons, si);
	int sj = W_FixWeaponOrder_BuildImpulseList_buf[j];
	Weapon e2 = REGISTRY_GET(Weapons, sj);
	int d = (e1.impulse + 9) % 10 - (e2.impulse + 9) % 10;
	if (d != 0) return -d;  // high impulse first!
	string s = strcat(" ", W_FixWeaponOrder_BuildImpulseList_order, " ");
	return strstrofs(s, sprintf(" %d ", si), 0)
		- strstrofs(s, sprintf(" %d ", sj), 0); // low char index first!
}
string W_FixWeaponOrder_BuildImpulseList(string o)
{
	int i;
	W_FixWeaponOrder_BuildImpulseList_order = o;
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		W_FixWeaponOrder_BuildImpulseList_buf[i - WEP_FIRST] = i;
	heapsort(WEP_LAST - WEP_FIRST + 1, W_FixWeaponOrder_BuildImpulseList_swap, W_FixWeaponOrder_BuildImpulseList_cmp,
		NULL);
	o = "";
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		o = strcat(o, " ", ftos(W_FixWeaponOrder_BuildImpulseList_buf[i - WEP_FIRST]));
	W_FixWeaponOrder_BuildImpulseList_order = string_null;
	return substring(o, 1, -1);
}

string W_FixWeaponOrder_AllowIncomplete(entity this, string order)
{
	return W_FixWeaponOrder(order, 0);
}

string W_FixWeaponOrder_ForceComplete(string order)
{
	if (order == "") order = W_NumberWeaponOrder(cvar_defstring("cl_weaponpriority"));
	return W_FixWeaponOrder(order, 1);
}

WepSet W_RandomWeapons(entity e, WepSet remaining, int n)
{
	WepSet result = '0 0 0';
	for (int j = 0; j < n; ++j)
	{
		RandomSelection_Init();
		FOREACH(Weapons, it != WEP_Null, {
			if (remaining & (it.m_wepset))
				RandomSelection_AddEnt(it, 1, 1);
		});
		Weapon w = RandomSelection_chosen_ent;
		result |= WepSet_FromWeapon(w);
		remaining &= ~WepSet_FromWeapon(w);
	}
	return result;
}

entity GetAmmoItem(Resource ammotype)
{
	FOREACH(Items, it.netname == ammotype.netname,
	{
		return it;
	});
	LOG_WARNF("Invalid ammo type %d ", ammotype.m_id);
	return NULL;
}

entity GetAmmoResource(Ammo ammotype)
{
	FOREACH(Resources, it.netname == ammotype.netname,
	{
		return it;
	});
	LOG_WARNF("Invalid ammo type %d ", ammotype.m_id);
	return NULL;
}

#ifdef CSQC
int GetAmmoStat(Resource ammotype)
{
	// TODO: handle networking via resources
	switch (ammotype)
	{
		case RES_SHELLS: return STAT_SHELLS;
		case RES_BULLETS: return STAT_NAILS;
		case RES_ROCKETS: return STAT_ROCKETS;
		case RES_CELLS: return STAT_CELLS;
		case RES_FUEL: return STAT_FUEL.m_id;
		default: return -1;
	}
}
#endif

string W_Sound(string w_snd)
{
	string output = strcat("weapons/", w_snd);
	MUTATOR_CALLHOOK(WeaponSound, w_snd, output);
	return M_ARGV(1, string);
}

string W_Model(string w_mdl)
{
	string output = strcat("models/weapons/", w_mdl);
	MUTATOR_CALLHOOK(WeaponModel, w_mdl, output);
	return M_ARGV(1, string);
}

#ifdef GAMEQC
vector shotorg_adjustfromclient(vector vecs, float y_is_right, float algn)
{
	switch (algn)
	{
		default:
		case 3:
			// right alignment
			break;
		case 4:
			// left
			vecs.y = -vecs.y;
			break;
		case 1:
		case 2:
			// center
			vecs.y = 0;
			vecs.z -= 2;
			break;
	}
	return vecs;
}

vector shotorg_adjust(vector vecs, bool y_is_right, bool visual, int algn)
{
	string s;
	if (visual)
	{
		vecs = shotorg_adjustfromclient(vecs, y_is_right, algn);
	}
	else if (STAT(SHOOTFROMEYE))
	{
		vecs.y = vecs.z = 0;
	}
	else if (STAT(SHOOTFROMCENTER))
	{
		vecs.y = 0;
		vecs.z -= 2;
	}
	else if ((s = G_SHOOTFROMFIXEDORIGIN) != "")
	{
		vector v = stov(s);
		if (y_is_right) v.y = -v.y;
		if (v.x != 0) vecs.x = v.x;
		vecs.y = v.y;
		vecs.z = v.z;
	}
	else  // just do the same as top
	{
		vecs = shotorg_adjustfromclient(vecs, y_is_right, algn);
	}

	return vecs;
}


/**
 * supported formats:
 *
 * 1. simple animated model, muzzle flash handling on h_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - invisible model controlling the animation
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *        weapon = attachment for v_tuba.md3
 *    v_tuba.md3 - first and third person model
 *    g_tuba.md3 - pickup model
 *
 * 2. simple animated model, muzzle flash handling on v_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - invisible model controlling the animation
 *      tags:
 *        weapon = attachment for v_tuba.md3
 *    v_tuba.md3 - first and third person model
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *    g_tuba.md3 - pickup model
 *
 * 3. fully animated model, muzzle flash handling on h_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - animated first person model
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *        handle = corresponding to the origin of v_tuba.md3 (used for muzzle flashes)
 *    v_tuba.md3 - third person model
 *    g_tuba.md3 - pickup model
 *
 * 4. fully animated model, muzzle flash handling on v_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - animated first person model
 *      tags:
 *        shot = muzzle end (shot origin)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *    v_tuba.md3 - third person model
 *      tags:
 *        shot = muzzle end (for muzzle flashes)
 *    g_tuba.md3 - pickup model
 *
 * writes:
 *   this.origin, this.angles
 *   this.weaponchild
 *   this.movedir, this.view_ofs, this.movedir_aligned
 *   this.spawnorigin (SVQC only)
 *   attachment stuff
 *   anim stuff
 * to free:
 *   call again with ""
 *   remove the ent
 */
void CL_WeaponEntity_SetModel(entity this, string name, bool _anim)
{
	if (name == "")
	{
		vector oldmin = this.mins, oldmax = this.maxs;
		setmodel(this, MDL_Null);
		setsize(this, oldmin, oldmax);
		if (this.weaponchild) delete(this.weaponchild);
		this.weaponchild = NULL;
		this.movedir = '0 0 0';
#ifdef SVQC
		this.spawnorigin = '0 0 0';
#endif
		this.oldorigin = '0 0 0';
		this.anim_fire1  = '0 1 0.01';
		this.anim_fire2  = '0 1 0.01';
		this.anim_idle   = '0 1 0.01';
		this.anim_reload = '0 1 0.01';
	}
	else
	{
		// if there is a child entity, hide it until we're sure we use it
		if (this.weaponchild) this.weaponchild.model = "";
		_setmodel(this, W_Model(strcat("v_", name, ".md3")));
		int v_shot_idx;  // used later
		(v_shot_idx = gettagindex(this, "shot")) || (v_shot_idx = gettagindex(this, "tag_shot"));

		_setmodel(this, W_Model(strcat("h_", name, ".iqm")));
		// preset some defaults that work great for renamed zym files (which don't need an animinfo)
		this.anim_fire1  = animfixfps(this, '0 1 0.01', '0 0 0');
		this.anim_fire2  = animfixfps(this, '1 1 0.01', '0 0 0');
		this.anim_idle   = animfixfps(this, '2 1 0.01', '0 0 0');
		this.anim_reload = animfixfps(this, '3 1 0.01', '0 0 0');

		// if we have a "weapon" tag, let's attach the v_ model to it ("invisible hand" style model)
		// if we don't, this is a "real" animated model
		string t;
		if ((t = "weapon", gettagindex(this, t)) || (t = "tag_weapon", gettagindex(this, t)))
		{
			if (!this.weaponchild)
			{
				this.weaponchild = new(weaponchild);
#ifdef CSQC
				this.weaponchild.drawmask = MASK_NORMAL;
				this.weaponchild.renderflags |= RF_VIEWMODEL;
#endif
			}
			_setmodel(this.weaponchild, W_Model(strcat("v_", name, ".md3")));
			setsize(this.weaponchild, '0 0 0', '0 0 0');
			setattachment(this.weaponchild, this, t);
		}
		else
		{
			if (this.weaponchild) delete(this.weaponchild);
			this.weaponchild = NULL;
		}

		setsize(this, '0 0 0', '0 0 0');
		setorigin(this, '0 0 0');
		this.angles = '0 0 0';
		this.frame = 0;
#ifdef SVQC
		this.viewmodelforclient = NULL;
#else
		this.renderflags &= ~RF_VIEWMODEL;
#endif
		if (v_shot_idx)  // v_ model attached to invisible h_ model
		{
			this.movedir = gettaginfo(this.weaponchild, v_shot_idx);
		}
		else
		{
			int idx;
			if ((idx = gettagindex(this, "shot")) || (idx = gettagindex(this, "tag_shot")))
			{
				this.movedir = gettaginfo(this, idx);
			}
			else
			{
				LOG_WARNF("weapon model %s does not support the 'shot' tag, will display shots TOTALLY wrong",
					this.model);
				this.movedir = '0 0 0';
			}
		}
#ifdef SVQC
		{
			int idx = 0;
			// v_ model attached to invisible h_ model
			if (this.weaponchild
				&& ((idx = gettagindex(this.weaponchild, "shell")) || (idx = gettagindex(this.weaponchild, "tag_shell"))))
			{
				this.spawnorigin = gettaginfo(this.weaponchild, idx);
			}
			else if ((idx = gettagindex(this, "shell")) || (idx = gettagindex(this, "tag_shell")))
			{
				this.spawnorigin = gettaginfo(this, idx);
			}
			else
			{
				LOG_WARNF("weapon model %s does not support the 'shell' tag, will display casings wrong",
					this.model);
				this.spawnorigin = this.movedir;
			}
		}
#endif
		if (v_shot_idx)
		{
			this.oldorigin = '0 0 0';  // use regular attachment
		}
		else
		{
			int idx;
			if (this.weaponchild)
				(idx = gettagindex(this, "weapon")) || (idx = gettagindex(this, "tag_weapon"));
			else
				(idx = gettagindex(this, "handle")) || (idx = gettagindex(this, "tag_handle"));
			if (idx)
			{
				this.oldorigin = this.movedir - gettaginfo(this, idx);
			}
			else
			{
				LOG_WARNF(
					"weapon model %s does not support the 'handle' tag "
					"and neither does the v_ model support the 'shot' tag, "
					"will display muzzle flashes TOTALLY wrong\n",
					this.model);
				this.oldorigin = '0 0 0';  // there is no way to recover from this
			}
		}

#ifdef SVQC
		this.viewmodelforclient = this.owner;
#else
		this.renderflags |= RF_VIEWMODEL;
#endif
	}

	this.view_ofs = '0 0 0';
	this.movedir_aligned = this.movedir;

	if (this.movedir.x >= 0)
	{
		//int algn = STAT(GUNALIGN, this.owner);
		int algn = W_GunAlign(this, STAT(GUNALIGN, this.owner));
	#ifdef SVQC
		this.m_gunalign = algn;
	#endif
		vector v = this.movedir;
		this.movedir = shotorg_adjust(v, false, false, algn);
		this.movedir_aligned = shotorg_adjust(v, false, true, algn);
		this.view_ofs = this.movedir_aligned - v;
	}

	// shotorg_adjust can give negative .x from shootfromfixedorigin
	// recheck .x here due to it
	if (this.movedir.x >= 0)
	{
		int compressed_shotorg = compressShotOrigin(this.movedir);
		// make them match perfectly
	#ifdef SVQC
		// null during init
		if (this.owner) STAT(SHOTORG, this.owner) = compressed_shotorg;
	#endif
		this.movedir = decompressShotOrigin(compressed_shotorg);
	}
	else
	{
		// don't support negative x shotorgs
		this.movedir = '0 0 0';

		// reset _aligned here too even though as a side effect
		// g_shootfromfixedorigin can make it reset
		// it'd be only slightly better if it was checked individually
		this.movedir_aligned = '0 0 0';

	#ifdef SVQC
		// null during init
		if (this.owner) STAT(SHOTORG, this.owner) = 0;
	#endif
	}

#ifdef SVQC
	this.spawnorigin += this.view_ofs;  // offset the casings origin by the same amount
#endif

	// check if an instant weapon switch occurred
	setorigin(this, this.view_ofs);
	if (!_anim) return;
	// reset animstate now
	this.wframe = WFRAME_IDLE;
	setanim(this, this.anim_idle, true, false, true);
}
#endif

#ifdef GAMEQC

REGISTER_NET_TEMP(wframe)
#ifdef CSQC
NET_HANDLE(wframe, bool isNew)
{
	WFRAME fr = ReadByte();
	float t = ReadFloat();
	int slot = ReadByte();
	bool restartanim = ReadByte();
	entity wepent = viewmodels[slot];
	if(fr == WFRAME_IDLE)
		wepent.animstate_looping = false; // we don't need to enforce idle animation
	else
	{
		vector a = '0 0 0';
		switch(fr)
		{
			default:
			case WFRAME_IDLE: a = wepent.anim_idle; break;
			case WFRAME_FIRE1: a = wepent.anim_fire1; break;
			case WFRAME_FIRE2: a = wepent.anim_fire2; break;
			case WFRAME_RELOAD: a = wepent.anim_reload; break;
		}
		a.z *= t;
		anim_set(wepent, a, !restartanim, restartanim, restartanim);
	}
	wepent.state = ReadByte();
	wepent.weapon_nextthink = ReadFloat();
	switch (wepent.state)
	{
		case WS_RAISE:
			wepent.weapon_switchdelay = wepent.switchweapon.switchdelay_raise;
			break;
		case WS_DROP:
			wepent.weapon_switchdelay = wepent.activeweapon.switchdelay_drop;
			break;
		default:
			wepent.weapon_switchdelay = 0;
			break;
	}
	return true;
}
#endif

#ifdef SVQC
void wframe_send(entity actor, entity weaponentity, int wepframe, float attackrate, bool restartanim)
{
	if (!IS_REAL_CLIENT(actor)) return;
	int channel = MSG_ONE;
	msg_entity = actor;
	WriteHeader(channel, wframe);
	WriteByte(channel, wepframe);
	WriteFloat(channel, attackrate);
	WriteByte(channel, weaponslot(weaponentity.weaponentity_fld));
	WriteByte(channel, restartanim);
	WriteByte(channel, weaponentity.state);
	WriteFloat(channel, weaponentity.weapon_nextthink);
}
#endif

REGISTER_NET_C2S(w_whereis)
#ifdef SVQC
void Weapon_whereis(Weapon this, entity cl);
NET_HANDLE(w_whereis, bool)
{
	Weapon wpn = ReadRegistered(Weapons);
	if (wpn != WEP_Null) Weapon_whereis(wpn, sender);
	return true;
}
#else
void w_whereis(Weapon this)
{
	int channel = MSG_C2S;
	WriteHeader(channel, w_whereis);
	WriteRegistered(Weapons, channel, this);
}
CLIENT_COMMAND(weapon_find, "Show spawn locations of a weapon")
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string s = argv(1);
			if (s == "all")
			{
				FOREACH(Weapons, it != WEP_Null, w_whereis(it));
				return;
			}
			if (s == "unowned")
			{
				FOREACH(Weapons, it != WEP_Null && !(STAT(WEAPONS) & it.m_wepset), w_whereis(it));
				return;
			}
			FOREACH(Weapons, it != WEP_Null && it.netname == s,
			{
				w_whereis(it);
				return;
			});
		}
		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd weapon_find <weapon>");
			LOG_HELP("  Where <weapon> is the lowercase weapon name, 'all' or 'unowned'.");
			return;
		}
	}
}
#endif

#ifdef SVQC
void W_MuzzleFlash_Model_AttachToShotorg(entity actor, .entity weaponentity, entity flash, vector offset)
{
	flash.owner = actor;
	flash.angles_z = random() * 360;

	entity view = actor.(weaponentity);
	entity exterior = actor.exteriorweaponentity;

	if (view.oldorigin.x > 0)
	{
		setattachment(flash, exterior, "");
		setorigin(flash, view.oldorigin + offset);
	}
	else
	{
		if (gettagindex(exterior, "shot")) setattachment(flash, exterior, "shot");
		else setattachment(flash, exterior, "tag_shot");
		setorigin(flash, offset);
	}
}
#elif defined(CSQC)
void W_MuzzleFlash_Model_AttachToShotorg(entity wepent, entity flash, vector offset)
{
	flash.owner = wepent;
	flash.angles_z = random() * 360;

	if (gettagindex(wepent, "shot")) setattachment(flash, wepent, "shot");
	else setattachment(flash, wepent, "tag_shot");
	setorigin(flash, offset);
}
#endif

void W_MuzzleFlash_Model_Think(entity this)
{
	this.frame += 2;
	this.scale *= 0.5;
	this.alpha -= 0.25;
	this.nextthink = time + 0.05;

	if(this.alpha <= 0)
	{
		setthink(this, SUB_Remove);
		this.nextthink = time;
		this.realowner.muzzle_flash = NULL;
		return;
	}
}

void W_MuzzleFlash_Model(entity wepent, entity muzzlemodel)
{
	if(wepent.muzzle_flash == NULL)
		wepent.muzzle_flash = spawn();

	entity flash = wepent.muzzle_flash;
	setmodel(flash, muzzlemodel); // precision set below

	flash.scale = 0.75;
	setthink(flash, W_MuzzleFlash_Model_Think);
	flash.nextthink = time + 0.02;
	flash.frame = 2;
	flash.alpha = 0.75;
	flash.angles_z = random() * 180;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT;
	flash.owner = flash.realowner = wepent;

#ifdef CSQC
	flash.drawmask = MASK_NORMAL;
#endif
}

REGISTER_NET_TEMP(w_muzzleflash)

#ifdef SVQC
void W_MuzzleFlash(Weapon thiswep, entity actor, .entity weaponentity, vector shotorg, vector shotdir)
{
	// don't show an exterior muzzle effect for the off-hand
	if(weaponslot(weaponentity) == 0)
	{
		Send_Effect_Except(thiswep.m_muzzleeffect, shotorg, shotdir * 1000, 1, '0 0 0', '0 0 0', actor);

		if(thiswep.m_muzzlemodel != MDL_Null)
		{
			W_MuzzleFlash_Model(actor.exteriorweaponentity, thiswep.m_muzzlemodel);
			W_MuzzleFlash_Model_AttachToShotorg(actor, weaponentity, actor.exteriorweaponentity.muzzle_flash, '5 0 0');
		}
	}

	FOREACH_CLIENT(it == actor || (IS_SPEC(it) && it.enemy == actor),
	{
		if(!IS_REAL_CLIENT(it))
			continue;
		int channel = MSG_ONE;
		msg_entity = it;
		WriteHeader(channel, w_muzzleflash);
		WriteByte(channel, thiswep.m_id);
		WriteByte(channel, weaponslot(weaponentity));
		WriteVector(channel, shotorg);
	});
}
#elif defined(CSQC)
NET_HANDLE(w_muzzleflash, bool isNew)
{
	return = true;
	int weapon_id = ReadByte();
	int slot = ReadByte();
	vector sv_shotorg = ReadVector();

	Weapon thiswep = REGISTRY_GET(Weapons, weapon_id);
	vector viewangles = getpropertyvec(VF_CL_VIEWANGLES);
	vector forward, right, up;
	MAKE_VECTORS(viewangles, forward, right, up);

	if(autocvar_chase_active)
	{
		// in third person mode, show the muzzle flash from the server side weapon position
		// we don't have a view model to reference in this case
		pointparticles(thiswep.m_muzzleeffect, sv_shotorg, forward * 1000, 1);
		return;
	}
	if(!autocvar_r_drawviewmodel) return;

	entity wepent = viewmodels[slot];
	// get the local player entity to calculate shot origin
	entity rlplayer = CSQCModel_server2csqc(player_localentnum - 1);
	if(!rlplayer)
		rlplayer = csqcplayer; // fall back to the global

	vector md = wepent.movedir_aligned;
	vector dv = forward * md.x + right * -md.y + up * md.z;
	vector org = rlplayer.origin + rlplayer.view_ofs + dv;

	pointparticles(thiswep.m_muzzleeffect, org, forward * 1000, 1);

	if(thiswep.m_muzzlemodel != MDL_Null)
	{
		W_MuzzleFlash_Model(wepent, thiswep.m_muzzlemodel);
		W_MuzzleFlash_Model_AttachToShotorg(wepent, wepent.muzzle_flash, '5 0 0');
	}
}
#endif


#endif

#endif

#ifdef SVQC
string W_FixWeaponOrder_ForceComplete_AndBuildImpulseList(entity this, string wo)
{
	string o = W_FixWeaponOrder_ForceComplete(wo);
	strcpy(CS_CVAR(this).weaponorder_byimpulse, W_FixWeaponOrder_BuildImpulseList(o));
	return o;
}
#endif

#ifdef CSQC
REPLICATE(cvar_cl_accuracy_data_share, bool, "cl_accuracy_data_share");
REPLICATE(cvar_cl_accuracy_data_receive, bool, "cl_accuracy_data_receive");
#endif

#ifdef GAMEQC
REPLICATE(cvar_cl_gunalign, int, "cl_gunalign");
REPLICATE(cvar_cl_weapon_switch_reload, bool, "cl_weapon_switch_reload");
REPLICATE(cvar_cl_weapon_switch_fallback_to_impulse, bool, "cl_weapon_switch_fallback_to_impulse");
REPLICATE(cvar_cl_weaponimpulsemode, int, "cl_weaponimpulsemode");
REPLICATE(cvar_cl_weaponpriority, string, "cl_weaponpriority", W_FixWeaponOrder_ForceComplete_AndBuildImpulseList);
REPLICATE(cvar_cl_weaponpriorities[0], string, "cl_weaponpriority0", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[1], string, "cl_weaponpriority1", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[2], string, "cl_weaponpriority2", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[3], string, "cl_weaponpriority3", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[4], string, "cl_weaponpriority4", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[5], string, "cl_weaponpriority5", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[6], string, "cl_weaponpriority6", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[7], string, "cl_weaponpriority7", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[8], string, "cl_weaponpriority8", W_FixWeaponOrder_AllowIncomplete);
REPLICATE(cvar_cl_weaponpriorities[9], string, "cl_weaponpriority9", W_FixWeaponOrder_AllowIncomplete);
#endif


#ifdef MENUQC
// Finds keybinds for a weapon
string W_Guide_Keybinds(Weapon wep)
{
	string command, key, keys = "";
	int n, j;
	float k;
	const bool joy_active = cvar("joy_active");

	for (int cmd_type = 0; cmd_type < 2; ++cmd_type)
	{
		command = cmd_type
			? strcat("weapon_", wep.netname)
			: strcat("weapon_group_", itos(wep.impulse));
		n = tokenize(findkeysforcommand(command, 0)); // uses '...' strings

		for (j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if (k == -1)
				continue;
			key = keynumtostring(k);
			if (!joy_active && startsWith(key, "JOY"))
				continue;

			key = translate_key(key);
			if (keys == "")
				keys = strcat("^3", key);
			else
				keys = strcat(keys, "^7, ^3", key);
		}
	}

	if (keys == "")
		return _("This weapon has not been bound directly."); // code may miss some weird bind configs, so say "directly"
	return sprintf(_("You have bound this weapon to: %s."), strcat(keys, "^7"));
}


#define COLORED_DAMAGE(dmg) strcat("^9", dmg, "^7")

#define DPS_ONE(mode) sprintf(_("(DPS: %.2f)"), mode##rft <= 0 ? 1337 : stof(mode##dmg_s) / mode##rft)
#define DPS_MUL(mode) sprintf(_("(DPS: %.2f)"), mode##rft <= 0 ? 1337 : stof(mode##dmg_s) / mode##rft * stof(mode##shots_s))

#define pri_str _("primary")
#define sec_str _("secondary")
#define _IT_DOES_MSG()         strcat("\n* ", sprintf(_("It does %s damage"), COLORED_DAMAGE(dmg_s)), " ", DPS_ONE())
#define _IT_SHOOTS_MSG()       strcat("\n* ", sprintf(_("It shoots %s shots doing %s damage each"), shots_s, COLORED_DAMAGE(dmg_s)), " ", DPS_MUL())
#define _DOES_MSG(mode)        strcat("\n* ", sprintf(_("The %s does %s damage"), mode##str, COLORED_DAMAGE(mode##dmg_s)), " ", DPS_ONE(mode))
#define _DOES_PERSEC_MSG(mode) strcat("\n* ", sprintf(_("The %s does %s damage per second"), mode##str, COLORED_DAMAGE(mode##dmg_s)))
#define _SHOOTS_MSG(mode)      strcat("\n* ", sprintf(_("The %s shoots %s shots doing %s damage each"),    mode##str, mode##shots_s, COLORED_DAMAGE(mode##dmg_s)), " ", DPS_MUL(mode))
#define _SHOOTS_UPTO_MSG(mode) strcat("\n* ", sprintf(_("The %s shoots up to %s shots doing %s damage each"), mode##str, mode##shots_s, COLORED_DAMAGE(mode##dmg_s)), " ", DPS_MUL(mode))

// We could use the *_MSG macros directly but we use these because they are more intuitive and readable
#define IT_DOES()                   _IT_DOES_MSG()
#define IT_SHOOTS()                 _IT_SHOOTS_MSG()
#define THE_PRIMARY_DOES()          _DOES_MSG(pri_)
#define THE_PRIMARY_SHOOTS()        _SHOOTS_MSG(pri_)
#define THE_PRIMARY_SHOOTS_UPTO()   _SHOOTS_UPTO_MSG(pri_)
#define THE_PRIMARY_DOES_PERSEC()   _DOES_PERSEC_MSG(pri_)
#define THE_SECONDARY_DOES()        _DOES_MSG(sec_)
#define THE_SECONDARY_SHOOTS()      _SHOOTS_MSG(sec_)
#define THE_SECONDARY_SHOOTS_UPTO() _SHOOTS_UPTO_MSG(sec_)
#define THE_SECONDARY_DOES_PERSEC() _DOES_PERSEC_MSG(sec_)

// One function for each translatable string

string W_Guide_DPS_onlyOne_unnamed_andDirectHit(string name)
{
	const string wepbal_s = strcat("g_balance_", name);
	const string dmg_s   =      cvar_defstring(strcat(wepbal_s, "_damage"));
	const float rft      = stof(cvar_defstring(strcat(wepbal_s, "_refire")));
	const string dmg2_s  =      cvar_defstring(strcat(wepbal_s, "_damage2"));
	const string dir_dps = sprintf(_("(DPS: %.2f)"), rft <= 0 ? 1337 : stof(dmg2_s) / rft);
	return strcat(_("Default damage stats:"),
		IT_DOES(),
		strcat("\n* ", sprintf(_("A direct hit does %s damage"), COLORED_DAMAGE(dmg2_s)), " ", dir_dps)
	);
}
string W_Guide_DPS_onlyOne_unnamed(string name)
{
	const string wepbal_s = strcat("g_balance_", name);
	const string dmg_s =      cvar_defstring(strcat(wepbal_s, "_damage"));
	const float rft    = stof(cvar_defstring(strcat(wepbal_s, "_refire")));
	return strcat(_("Default damage stats:"),
		IT_DOES()
	);
}
string W_Guide_DPS_onlyOne_andDirectHit(string name, string fire)
{
	return W_Guide_DPS_onlyOne_unnamed_andDirectHit(strcat(name, "_", fire));
}
string W_Guide_DPS_onlyOne(string name, string fire)
{
	return W_Guide_DPS_onlyOne_unnamed(strcat(name, "_", fire));
}
string W_Guide_DPS(string name, string pri, string sec)
{
	// TODO: rename all wep primary cvars to g_balance_*_primary_*, vice versa for secondary.
	// Example exception: g_balance_arc_beam_* (primary)
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string pri_dmg_s =      cvar_defstring(strcat(wepbal_s, pri, "_damage"));
	const float pri_rft    = stof(cvar_defstring(strcat(wepbal_s, pri, "_refire")));
	const string sec_dmg_s =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	const float sec_rft    = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	return strcat(_("Default damage stats:"),
		THE_PRIMARY_DOES(),
		THE_SECONDARY_DOES()
	);
}
string W_Guide_DPS_bothMultishot(string name, string pri, string sec)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string pri_dmg_s   =      cvar_defstring(strcat(wepbal_s, pri, "_damage"));
	const float pri_rft      = stof(cvar_defstring(strcat(wepbal_s, pri, "_refire")));
	const string pri_shots_s =      cvar_defstring(strcat(wepbal_s, pri, "_shots"));
	const string sec_dmg_s   =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	const float sec_rft      = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	const string sec_shots_s =      cvar_defstring(strcat(wepbal_s, sec, "_shots"));
	return strcat(_("Default damage stats:"),
		THE_PRIMARY_SHOOTS(),
		THE_SECONDARY_SHOOTS()
	);
}
string W_Guide_DPS_onlySecondary(string name, string sec)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string sec_dmg_s =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	const float sec_rft    = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	return strcat(_("Default damage stats:"),
		THE_SECONDARY_DOES()
	);
}
string W_Guide_DPS_secondaryMultishot(string name, string pri, string sec, string shots, string refire2, bool sec_variable)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string pri_dmg_s   =      cvar_defstring(strcat(wepbal_s, pri, "_damage"));
	const float pri_rft      = stof(cvar_defstring(strcat(wepbal_s, pri, "_refire")));
	string sec_dmg_s         =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	float sec_rft            = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	const string sec_shots_s =      cvar_defstring(strcat(wepbal_s, shots));
	if (sec_dmg_s == "")
		sec_dmg_s = pri_dmg_s;
	const float num_shots = stof(sec_shots_s);
	if (refire2 != "")
		sec_rft = (num_shots - 1) * sec_rft + stof(cvar_defstring(strcat(wepbal_s, refire2)));
	return strcat(_("Default damage stats:"),
		THE_PRIMARY_DOES(),
		(sec_variable ? THE_SECONDARY_SHOOTS_UPTO() : THE_SECONDARY_SHOOTS())
	);
}
string W_Guide_DPS_primaryMultishot(string name, string pri, string sec, string shots, string refire2)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string pri_dmg_s   =      cvar_defstring(strcat(wepbal_s, pri, "_damage"));
	float pri_rft            = stof(cvar_defstring(strcat(wepbal_s, pri, "_refire")));
	const string pri_shots_s =      cvar_defstring(strcat(wepbal_s, shots));
	const string sec_dmg_s   =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	const float sec_rft      = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	const float num_shots = stof(pri_shots_s);
	if (refire2 != "")
		pri_rft = (num_shots - 1) * pri_rft + stof(cvar_defstring(strcat(wepbal_s, refire2)));
	return strcat(_("Default damage stats:"),
		THE_PRIMARY_SHOOTS(),
		THE_SECONDARY_DOES()
	);
}
string W_Guide_DPS_onlyOneMultishot(string name, string fire, string shots, string refire2)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string dmg_s   =      cvar_defstring(strcat(wepbal_s, fire, "_damage"));
	float rft            = stof(cvar_defstring(strcat(wepbal_s, fire, "_refire")));
	const string shots_s =      cvar_defstring(strcat(wepbal_s, shots));
	const float num_shots = stof(shots_s);
	if (refire2 != "")
		rft = (num_shots - 1) * rft + stof(cvar_defstring(strcat(wepbal_s, refire2)));
	return strcat(_("Default damage stats:"),
		IT_SHOOTS()
	);
}
string W_Guide_DPS_secondaryMultishotWithCombo(string name, string pri, string sec, string shots, string refire2, string combo, bool sec_variable)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string pri_dmg_s   =      cvar_defstring(strcat(wepbal_s, pri, "_damage"));
	const float  pri_rft     = stof(cvar_defstring(strcat(wepbal_s, pri, "_refire")));
	const string sec_dmg_s   =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	float sec_rft            = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	const string sec_shots_s =      cvar_defstring(strcat(wepbal_s, shots));
	const string cmb_dmg_s   =      cvar_defstring(strcat(wepbal_s, combo, "_damage"));
	const float num_shots = stof(sec_shots_s);
	float combo_t = max(pri_rft, sec_rft);
	if (refire2 != "")
	{
		const float sec_rft2 = sec_rft;
		sec_rft = stof(cvar_defstring(strcat(wepbal_s, refire2)));
		combo_t = max(combo_t, num_shots * sec_rft + sec_rft2);
		sec_rft = (num_shots - 1) * sec_rft + sec_rft2;
	}
	const string DPS_combo = sprintf(_("(total DPS: %.2f)"),
		combo_t <= 0 ? 1337 : (stof(pri_dmg_s) + stof(sec_dmg_s) * num_shots + stof(cmb_dmg_s)) / combo_t);
	return strcat(_("Default damage stats:"),
		THE_PRIMARY_DOES(),
		(sec_variable ? THE_SECONDARY_SHOOTS_UPTO() : THE_SECONDARY_SHOOTS()),
		strcat("\n* ", sprintf(_("The combo adds an extra %s damage"), COLORED_DAMAGE(cmb_dmg_s)), " ", DPS_combo)
	);
}
string W_Guide_DPS_primaryDPS(string name, string pri, string sec)
{
	const string wepbal_s = strcat("g_balance_", name, "_");
	const string pri_dmg_s =      cvar_defstring(strcat(wepbal_s, pri, "_damage")); // actually damage per second
	const string sec_dmg_s =      cvar_defstring(strcat(wepbal_s, sec, "_damage"));
	const float sec_rft    = stof(cvar_defstring(strcat(wepbal_s, sec, "_refire")));
	return strcat(_("Default damage stats:"),
		THE_PRIMARY_DOES_PERSEC(),
		THE_SECONDARY_DOES()
	);
}
#endif
