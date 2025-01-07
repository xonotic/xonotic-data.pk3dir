#include "spawnpoints.qh"

#include <client/hud/hud.qh>
#include <client/main.qh>
#include <client/view.qh>

void Spawn_Draw(entity this)
{
	bool dodraw = autocvar_cl_spawn_point_particles;
	if(dodraw && autocvar_cl_spawn_point_dist_max)
	{
		vector org = getpropertyvec(VF_ORIGIN);
		dodraw = vdist(org - this.origin, <, autocvar_cl_spawn_point_dist_max);
	}

	if(dodraw)
		pointparticles(((!teamplay) ? EFFECT_SPAWNPOINT_NEUTRAL : EFFECT_SPAWNPOINT(this.team - 1)), this.origin + '0 0 28', '0 0 2', bound(0, frametime, 0.1));
}

NET_HANDLE(ENT_CLIENT_SPAWNPOINT, bool is_new)
{
	float teamnum = (ReadByte() - 1);
	vector spn_origin = ReadVector();

	this.team = (teamnum + 1);

	this.origin = spn_origin;
	setsize(this, PL_MIN_CONST, PL_MAX_CONST);

	this.draw = Spawn_Draw;
	if (is_new) IL_PUSH(g_drawables, this);

	return true;
}

NET_HANDLE(ENT_CLIENT_SPAWNEVENT, bool is_new)
{
	// If entnum is 0, ONLY do the local spawn actions
	// this way the server can disable the sending of
	// spawn origin or such to clients if wanted.
	float entnum = ReadByte();

	if(entnum)
	{
		this.origin = ReadVector();

		int teamnum = ReadByte() - 1;
		int particlesAndOrSound = ReadByte();

		if(is_new)
		{
			if(autocvar_cl_spawn_event_particles && (particlesAndOrSound & BIT(0)))
			{
				switch(teamnum)
				{
					case NUM_TEAM_1: pointparticles(EFFECT_SPAWN_RED, this.origin, '0 0 0', 1); break;
					case NUM_TEAM_2: pointparticles(EFFECT_SPAWN_BLUE, this.origin, '0 0 0', 1); break;
					case NUM_TEAM_3: pointparticles(EFFECT_SPAWN_YELLOW, this.origin, '0 0 0', 1); break;
					case NUM_TEAM_4: pointparticles(EFFECT_SPAWN_PINK, this.origin, '0 0 0', 1); break;
					default: pointparticles(EFFECT_SPAWN_NEUTRAL, this.origin, '0 0 0', 1); break;
				}
			}

			if(autocvar_cl_spawn_event_sound && (particlesAndOrSound & BIT(1)))
			{
				sound(this, CH_TRIGGER, SND_SPAWN, VOL_BASE, ATTEN_NORM);
			}
		}
	}
	return = true;

	// local spawn actions
	if(is_new && (!entnum || (entnum == player_localentnum)))
	{
		if(!spectatee_status)
		if(autocvar_cl_autodemo_delete_keepmatches >= 2 || (!warmup_stage && autocvar_cl_autodemo_delete_keepmatches == 1))
		{
			float del = autocvar_cl_autodemo_delete;
			del &= ~1;
			cvar_set("cl_autodemo_delete", ftos(del)); // don't delete demo where the player joined the match
		}

		if(autocvar_cl_spawnzoom && !autocvar_cl_lockview)
		{
			zoomin_effect = 1;
			current_viewzoom = (1 / bound(1, autocvar_cl_spawnzoom_factor, 16));
		}

		if(autocvar_cl_unpress_zoom_on_spawn)
		{
			localcmd("-zoom\n");
			button_zoom = false;
		}
		HUD_Radar_Hide_Maximized();
	}
}
