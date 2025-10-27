#include "swapper.qh"

#ifdef SVQC
MUTATOR_HOOKFUNCTION(buffs, ForbidThrowCurrentWeapon)
{
	if (MUTATOR_RETURNVALUE || game_stopped)
		return;

	entity player = M_ARGV(0, entity);
	if (StatusEffects_active(BUFF_SWAPPER, player))
	{
		entity head = WarpZone_FindRadius(player.origin, autocvar_g_buffs_swapper_range, false);
		entity closest = NULL;
		float head_dist2, best_dist2 = autocvar_g_buffs_swapper_range ** 2;
		for (; head; head = head.chain)
			if (IS_PLAYER(head) && DIFF_TEAM(head, player))
			if (!IS_DEAD(head) && !STAT(FROZEN, head) && !head.vehicle)
			{
				head_dist2 = vlen2(head.WarpZone_findradius_dist);
				if (head_dist2 < best_dist2)
				{
					best_dist2 = head_dist2;
					closest = head;
				}
			}

		if (closest)
		{
			vector my_org = player.origin;
			vector my_vel = player.velocity;
			vector my_ang = player.angles;
			vector their_org = closest.origin;
			vector their_vel = closest.velocity;
			vector their_ang = closest.angles;

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
#endif // SVQC
#ifdef MENUQC
METHOD(SwapperBuff, describe, string(SwapperBuff this))
{
	TC(SwapperBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff allows you to press %s to switch places with a nearby enemy once."), COLORED_NAME(this), strcat("^3", _("drop weapon"), "^7"));
	PAR(_("A common usage of this buff is to jump over the map's void, then swap with an enemy, to cause them to fall into the void."));
	PAR(_("The range that the buff works over is limited, so sometimes it may do nothing if there are no enemies nearby."));
	return PAGE_TEXT;
}
#endif // MENUQC
