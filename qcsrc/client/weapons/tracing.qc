#include "tracing.qh"

#include <client/csqcmodel_hooks.qh>
#include <client/hud/crosshair.qh>
#include <client/main.qh>
#include <client/view.qh>
#include <common/physics/player.qh>
#include <common/weapons/all.qh>
#include <common/wepent.qh>
#include <lib/csqcmodel/common.qh>
#include <lib/warpzone/common.qh>

int W_SetupShot_Dir_ProjectileSize_Range(entity ent, entity wepent, vector s_forward, vector mi, vector ma, float antilag, float recoil, Sound snd, float chan, float maxdamage, float range)
{
	float nudge = 1; // added to traceline target and subtracted from result  TOOD(divVerent): do we still need this? Doesn't the engine do this now for us?
	vector vecs;
	int oldsolid = ent.dphitcontentsmask;
	if (IS_PLAYER(ent) && wepent.activeweapon == WEP_RIFLE)
		ent.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	else
		ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	WarpZone_TraceLine(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NOMONSTERS, ent);
	ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	vector forward, right, up;
	forward = v_forward;
	right = v_right;
	up = v_up;
	w_shotend = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos); // warpzone support
	v_forward = forward;
	v_right = right;
	v_up = up;

	// perform the test now as future traces will affect the accuracy of the test
	return = EnemyHitCheck(false);

	// un-adjust trueaim if shotend is too close
	if(vdist(w_shotend - (ent.origin + ent.view_ofs), <, g_trueaim_minrange))
		w_shotend = ent.origin + ent.view_ofs + s_forward * g_trueaim_minrange;

	vector md = wepent.movedir;
	if(md.x > 0)
		vecs = md;
	else
		vecs = '0 0 0';

	vector dv = right * -vecs.y + up * vecs.z;
	w_shotorg = ent.origin + ent.view_ofs + dv;

	int oldsurfaceflags = trace_dphitq3surfaceflags;

	// now move the shotorg forward as much as requested if possible
	tracebox(w_shotorg, mi, ma, w_shotorg + forward * (vecs.x + nudge), MOVE_NORMAL, ent);
	w_shotorg = trace_endpos - forward * nudge;
	// calculate the shotdir from the chosen shotorg
	w_shotdir = normalize(w_shotend - w_shotorg);

	// restore flags for later use
	trace_dphitq3surfaceflags = oldsurfaceflags;

	//vector prevdir = w_shotdir;
	//vector prevorg = w_shotorg;
	//vector prevend = w_shotend;

	ent.dphitcontentsmask = oldsolid;

	// nudge w_shotend so a trace to w_shotend hits
	w_shotend = w_shotend + normalize(w_shotend - w_shotorg) * nudge;
	//if(w_shotend != prevend) { printf("CLIENT: shotEND differs: %s - %s\n", vtos(w_shotend), vtos(prevend)); }
	//if(w_shotorg != prevorg) { printf("CLIENT: shotORG differs: %s - %s\n", vtos(w_shotorg), vtos(prevorg)); }
	//if(w_shotdir != prevdir) { printf("CLIENT: shotDIR differs: %s - %s\n", vtos(w_shotdir), vtos(prevdir)); }
}

void HUD_Crosshair_ClientBeam(entity this)
{
	// TODO: make player_blocked a generic function for use here!
	if(time < STAT(GAMESTARTTIME) || time < STAT(ROUNDSTARTTIME) || STAT(FROZEN) || spectatee_status)
		return;

	entity localplayer = playerslots[player_localnum];
	if(!(autocvar_cl_clientbeams > 0 || (localplayer.ping >= autocvar_cl_clientbeams_minping && autocvar_cl_clientbeams != -1)))
		return;

	bool button_atck = (input_buttons & BIT(0));
	bool button_atck2 = (input_buttons & BIT(2));

	vector viewangles = getpropertyvec(VF_CL_VIEWANGLES);
	makevectors(viewangles);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		entity wepent = viewmodels[slot];
		Weapon wep = wepent.activeweapon;
		if(wep != WEP_Null)
			wep.wr_clientbeam(wep, localplayer, wepent, button_atck | (button_atck2 << 1));
	}
}
