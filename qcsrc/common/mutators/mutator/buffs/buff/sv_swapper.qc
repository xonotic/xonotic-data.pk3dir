#include "sv_swapper.qh"

MUTATOR_HOOKFUNCTION(buffs, ForbidThrowCurrentWeapon)
{
	if(MUTATOR_RETURNVALUE || game_stopped) return;
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(BUFF_SWAPPER, player))
	{
		float best_distance = autocvar_g_buffs_swapper_range;
		entity closest = NULL;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if(!IS_DEAD(it) && !STAT(FROZEN, it) && !it.vehicle)
			if(DIFF_TEAM(it, player))
			{
				float test = vlen2(player.origin - it.origin);
				if(test <= best_distance * best_distance)
				{
					best_distance = sqrt(test);
					closest = it;
				}
			}
		});

		if(closest)
		{
			vector my_org, my_vel, my_ang, their_org, their_vel, their_ang;

			my_org = player.origin;
			my_vel = player.velocity;
			my_ang = player.angles;
			their_org = closest.origin;
			their_vel = closest.velocity;
			their_ang = closest.angles;

			Drop_Special_Items(closest);

			MUTATOR_CALLHOOK(PortalTeleport, player); // initiate flag dropper

			setorigin(player, their_org);
			setorigin(closest, my_org);

			closest.velocity = my_vel;
			closest.angles = my_ang;
			if (IS_BOT_CLIENT(closest))
			{
				closest.v_angle = closest.angles;
				bot_aim_reset(closest);
			}
			closest.fixangle = true;
			closest.oldorigin = my_org;
			closest.oldvelocity = my_vel;
			player.velocity = their_vel;
			player.angles = their_ang;
			if (IS_BOT_CLIENT(player))
			{
				player.v_angle = player.angles;
				bot_aim_reset(player);
			}
			player.fixangle = true;
			player.oldorigin = their_org;
			player.oldvelocity = their_vel;

			// set pusher so player gets the kill if they fall into void
			closest.pusher = player;
			closest.pushltime = time + autocvar_g_maxpushtime;
			closest.istypefrag = PHYS_INPUT_BUTTON_CHAT(closest);

			Send_Effect(EFFECT_ELECTRO_COMBO, their_org, '0 0 0', 1);
			Send_Effect(EFFECT_ELECTRO_COMBO, my_org, '0 0 0', 1);

			sound(player, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NORM);
			sound(closest, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NORM);

			// TODO: add a counter to handle how many times one can teleport, and a delay to prevent spam
			buff_RemoveAll(player, STATUSEFFECT_REMOVE_NORMAL);
			return true;
		}
	}
}
