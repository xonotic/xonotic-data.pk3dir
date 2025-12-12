#include "all.qh"

const int EFF_NET_VELOCITY    = BIT(0);
const int EFF_NET_COLOR_MIN   = BIT(1);
const int EFF_NET_COLOR_MAX   = BIT(2);
const int EFF_NET_COLOR_SAME  = BIT(3); // optimization bit for sending only one color

REGISTER_NET_TEMP(net_effect)
#ifdef CSQC
NET_HANDLE(net_effect, bool isNew)
{
	int net_name = (REGISTRY_COUNT(Effects) >= 255) ? ReadShort() : ReadByte();

	entity eff = REGISTRY_GET(Effects, net_name);

	vector vel = '0 0 0';
	int eff_flags = 0;
	bool eff_trail = eff.eent_eff_trail;
	vector v = ReadVector();
	int extraflags = ReadByte();

	if (extraflags & EFF_NET_VELOCITY)
		vel = ReadVector();

	if (extraflags & EFF_NET_COLOR_MIN)
	{
		particles_colormin.x = ReadByte() / 16;
		particles_colormin.y = ReadByte() / 16;
		particles_colormin.z = ReadByte() / 16;
		eff_flags |= PARTICLES_USECOLOR;
	}
	else
		particles_colormin = '0 0 0';
	if (extraflags & EFF_NET_COLOR_MAX)
	{
		particles_colormax.x = ReadByte() / 16;
		particles_colormax.y = ReadByte() / 16;
		particles_colormax.z = ReadByte() / 16;
		eff_flags |= PARTICLES_USECOLOR;
	}
	else if (extraflags & EFF_NET_COLOR_SAME)
		particles_colormax = particles_colormin;
	else
		particles_colormax = '0 0 0';

	if (eff_trail)
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(eff), v, vel, 1, eff_flags);
	else
		boxparticles(particleeffectnum(eff), NULL, v, v, vel, vel, ReadByte(), eff_flags);
	return true;
}
#endif

#ifdef SVQC
void Send_Effect_Except(entity eff, vector eff_loc, vector eff_vel, int eff_cnt, vector eff_col_min, vector eff_col_max, entity ignore)
{
	if (!eff)
		return;
	if (!eff.eent_eff_trail && !eff_cnt)
		return; // effect has no count!

	int eff_flags = 0;
	if (eff_vel != '0 0 0')
		eff_flags |= EFF_NET_VELOCITY;
	if (eff_col_min != '0 0 0')
		eff_flags |= EFF_NET_COLOR_MIN;
	// optimization: only send one color if the min and max match
	if (eff_col_min != '0 0 0' && eff_col_min == eff_col_max)
		eff_flags |= EFF_NET_COLOR_SAME;
	else if (eff_col_max != '0 0 0')
		eff_flags |= EFF_NET_COLOR_MAX;

	if (eff_flags & EFF_NET_COLOR_MIN) // only rint & bound once, not for each client
	{
		eff_col_min.x = rint(bound(0, 16 * eff_col_min.x, 255));
		eff_col_min.y = rint(bound(0, 16 * eff_col_min.y, 255));
		eff_col_min.z = rint(bound(0, 16 * eff_col_min.z, 255));
	}
	if (eff_flags & EFF_NET_COLOR_MAX) // ...
	{
		eff_col_max.x = rint(bound(0, 16 * eff_col_max.x, 255));
		eff_col_max.y = rint(bound(0, 16 * eff_col_max.y, 255));
		eff_col_max.z = rint(bound(0, 16 * eff_col_max.z, 255));
	}

	// now network to every client
	int channel = MSG_ONE;
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != ignore && !(IS_SPEC(it) && it.enemy && it.enemy == ignore),
	{
		msg_entity = it;
		WriteHeader(channel, net_effect);
		if (REGISTRY_COUNT(Effects) >= 255)
			WriteShort(channel, eff.m_id);
		else
			WriteByte(channel, eff.m_id);
		WriteVector(channel, eff_loc);
		WriteByte(channel, eff_flags);

		// attempt to save a tiny bit more bandwidth by not sending velocity if it isn't set
		if (eff_flags & EFF_NET_VELOCITY)
			WriteVector(channel, eff_vel);

		if (eff_flags & EFF_NET_COLOR_MIN)
		{
			WriteByte(channel, eff_col_min.x);
			WriteByte(channel, eff_col_min.y);
			WriteByte(channel, eff_col_min.z);
		}
		if (eff_flags & EFF_NET_COLOR_MAX)
		{
			WriteByte(channel, eff_col_max.x);
			WriteByte(channel, eff_col_max.y);
			WriteByte(channel, eff_col_max.z);
		}

		if (!eff.eent_eff_trail)
			WriteByte(channel, eff_cnt);
	});
}

void Send_Effect(entity eff, vector eff_loc, vector eff_vel, int eff_cnt)
{
	Send_Effect_Except(eff, eff_loc, eff_vel, eff_cnt, '0 0 0', '0 0 0', NULL);
}

void Send_Effect_(string eff_name, vector eff_loc, vector eff_vel, int eff_cnt)
{
	// problem with this is, we might not have all the available effects for it
	FOREACH(Effects, it.eent_eff_name == eff_name,
	{
		Send_Effect(it, eff_loc, eff_vel, eff_cnt);
		return;
	});
	// revert to engine handling TODO: send the effect name and draw it on the client side? not as light on networking, but resolves the use of server side effects
	__pointparticles(_particleeffectnum(eff_name), eff_loc, eff_vel, eff_cnt);
}
#endif

#if ENABLE_EFFECTINFO
	#include "effectinfo.qc"
#endif
