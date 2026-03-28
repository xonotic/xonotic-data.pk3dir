#include "all.qh"

REGISTER_NET_TEMP(net_effect)
const int SF_EFF_VELOCITY    = BIT(0);
const int SF_EFF_COLOR_MIN   = BIT(1);
const int SF_EFF_COLOR_MAX   = BIT(2);
const int SF_EFF_COLOR_SAME  = BIT(3); ///< optimization bit for sending only one color if min & max match
const int SF_EFF_ALPHA_MIN   = BIT(4);
const int SF_EFF_ALPHA_MAX   = BIT(5);
const int SF_EFF_ALPHA_SAME  = BIT(6); ///< optimization bit for sending only one alpha if min & max match
const int SF_EFF_FADE        = BIT(7);

#ifdef CSQC
NET_HANDLE(net_effect, bool isNew)
{
	int sf = ReadByte();
	entity eff = ReadRegistered(Effects);

	vector vel, org = ReadVector();

	if (sf & SF_EFF_VELOCITY)
		vel = ReadVector();
	else
		vel = '0 0 0';

	int eff_flags = 0;
	if (sf & SF_EFF_COLOR_MIN)
	{
		particles_colormin.x = ReadByte() / 16;
		particles_colormin.y = ReadByte() / 16;
		particles_colormin.z = ReadByte() / 16;
		eff_flags |= PARTICLES_USECOLOR;
	}
	if (sf & SF_EFF_COLOR_MAX)
	{
		particles_colormax.x = ReadByte() / 16;
		particles_colormax.y = ReadByte() / 16;
		particles_colormax.z = ReadByte() / 16;
		eff_flags |= PARTICLES_USECOLOR;
	}
	else if (sf & SF_EFF_COLOR_SAME)
		particles_colormax = particles_colormin;

	if (sf & SF_EFF_ALPHA_MIN)
	{
		particles_alphamin = ReadByte() / BITS(8);
		eff_flags |= PARTICLES_USEALPHA;
	}
	if (sf & SF_EFF_ALPHA_MAX)
	{
		particles_alphamax = ReadByte() / BITS(8);
		eff_flags |= PARTICLES_USEALPHA;
	}
	else if (sf & SF_EFF_ALPHA_SAME)
		particles_alphamax = particles_alphamin;
	if (sf & SF_EFF_FADE)
	{
		particles_fade = ReadByte() / BITS(8);
		eff_flags |= PARTICLES_USEFADE;
	}

	if (eff.eent_eff_trail)
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(eff), org, vel, 1, eff_flags);
	else
		boxparticles(particleeffectnum(eff), NULL, org, org, vel, vel, ReadByte(), eff_flags);
	return true;
}
#endif // CSQC

#ifdef SVQC
void Send_Effect_Core(entity eff, vector eff_loc, vector eff_vel, int eff_cnt, vector eff_col_min, vector eff_col_max, float eff_alpha_min, float eff_alpha_max, float eff_alpha_fade, entity ignore)
{
	if (!eff)
		return;
	if (!eff.eent_eff_trail && !eff_cnt)
		return; // effect has no count!

	int sf = 0;
	if (eff_vel != '0 0 0')
		sf |= SF_EFF_VELOCITY;

	if (eff_col_min != '0 0 0')
	{
		sf |= SF_EFF_COLOR_MIN;
		eff_col_min.x = rint(bound(0, 16 * eff_col_min.x, BITS(8)));
		eff_col_min.y = rint(bound(0, 16 * eff_col_min.y, BITS(8)));
		eff_col_min.z = rint(bound(0, 16 * eff_col_min.z, BITS(8)));
	}
	if (eff_col_max != '0 0 0')
	{
		if (eff_col_min == eff_col_max)
			sf |= SF_EFF_COLOR_SAME; // optimization: only send one color if the min and max match
		else
		{
			sf |= SF_EFF_COLOR_MAX;
			eff_col_max.x = rint(bound(0, 16 * eff_col_max.x, BITS(8)));
			eff_col_max.y = rint(bound(0, 16 * eff_col_max.y, BITS(8)));
			eff_col_max.z = rint(bound(0, 16 * eff_col_max.z, BITS(8)));
		}
	}

	if (eff_alpha_min >= 0)
	{
		sf |= SF_EFF_ALPHA_MIN;
		eff_alpha_min = rint(bound(0, eff_alpha_min, 1) * BITS(8));
	}
	if (eff_alpha_max >= 0)
	{
		if (eff_alpha_min == eff_alpha_max)
			sf |= SF_EFF_ALPHA_SAME; // optimization: only send one alpha if the min and max match
		else
		{
			sf |= SF_EFF_ALPHA_MAX;
			eff_alpha_max = rint(bound(0, eff_alpha_max, 1) * BITS(8));
		}
	}
	if (eff_alpha_fade >= 0)
	{
		sf |= SF_EFF_FADE;
		eff_alpha_fade = rint(bound(0, eff_alpha_max, 1) * BITS(8));
	}

	// now network to every client
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != ignore && !(IS_SPEC(it) && it.enemy && it.enemy == ignore),
	{
		msg_entity = it;
		WriteHeader(MSG_ONE, net_effect);
		WriteByte(MSG_ONE, sf);
		WriteRegistered(Effects, MSG_ONE, eff);
		WriteVector(MSG_ONE, eff_loc);

		// attempt to save a tiny bit more bandwidth by not sending velocity if it isn't set
		if (sf & SF_EFF_VELOCITY)
			WriteVector(MSG_ONE, eff_vel);

		if (sf & SF_EFF_COLOR_MIN)
		{
			WriteByte(MSG_ONE, eff_col_min.x);
			WriteByte(MSG_ONE, eff_col_min.y);
			WriteByte(MSG_ONE, eff_col_min.z);
		}
		if (sf & SF_EFF_COLOR_MAX)
		{
			WriteByte(MSG_ONE, eff_col_max.x);
			WriteByte(MSG_ONE, eff_col_max.y);
			WriteByte(MSG_ONE, eff_col_max.z);
		}

		if (sf & SF_EFF_ALPHA_MIN)
			WriteByte(MSG_ONE, eff_alpha_min);
		if (sf & SF_EFF_ALPHA_MAX)
			WriteByte(MSG_ONE, eff_alpha_max);
		if (sf & SF_EFF_FADE)
			WriteByte(MSG_ONE, eff_alpha_fade);

		if (!eff.eent_eff_trail)
			WriteByte(MSG_ONE, eff_cnt);
	});
}

void Send_Effect(entity eff, vector eff_loc, vector eff_vel, int eff_cnt)
{
	Send_Effect_Core(eff, eff_loc, eff_vel, eff_cnt, '0 0 0', '0 0 0', -1, -1, -1, NULL);
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
