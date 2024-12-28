#include "all.qh"

const int EFF_NET_VELOCITY = BIT(0);
const int EFF_NET_COLOR = BIT(1);

REGISTER_NET_TEMP(net_effect)
#ifdef CSQC
NET_HANDLE(net_effect, bool isNew)
{
	int net_name = (REGISTRY_COUNT(Effects) >= 255) ? ReadShort() : ReadByte();

	entity eff = REGISTRY_GET(Effects, net_name);

	vector vel = '0 0 0';
	int eff_cnt = 1;
	int eff_flags = 0;
	bool eff_trail = eff.eent_eff_trail;
	vector v = ReadVector();
	int extraflags = ReadByte();

	if(extraflags & EFF_NET_VELOCITY)
		vel = ReadVector();

	if(extraflags & EFF_NET_COLOR)
	{
		vector col;
		col.x = ReadByte() / 16;
		col.y = ReadByte() / 16;
		col.z = ReadByte() / 16;
		particles_colormin = particles_colormax = col;
		eff_flags |= PARTICLES_USECOLOR;
	}

	if(!eff_trail)
		eff_cnt = ReadByte();

	if(eff_trail)
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(eff), v, vel, 1, eff_flags);
	else
		boxparticles(particleeffectnum(eff), NULL, v, v, vel, vel, 1, eff_flags);
	return true;
}
#endif

#ifdef SVQC
bool Net_Write_Effect(entity this, entity client, int sf)
{
	int channel = MSG_ONE;
	msg_entity = client;
	WriteHeader(channel, net_effect);
	(REGISTRY_COUNT(Effects) >= 255)
	? WriteShort(channel, this.m_id)
	: WriteByte(channel, this.m_id);
	WriteVector(channel, this.eent_net_location);

	int extraflags = 0;
	if(this.eent_net_velocity)
		extraflags |= EFF_NET_VELOCITY;
	if(this.eent_net_color)
		extraflags |= EFF_NET_COLOR;

	WriteByte(channel, extraflags);

	// attempt to save a tiny bit more bandwidth by not sending velocity if it isn't set
	if(extraflags & EFF_NET_VELOCITY)
		WriteVector(channel, this.eent_net_velocity);

	if(extraflags & EFF_NET_COLOR)
	{
		vector col = this.eent_net_color;
		WriteByte(channel, rint(bound(0, 16 * col.x, 255)));
		WriteByte(channel, rint(bound(0, 16 * col.y, 255)));
		WriteByte(channel, rint(bound(0, 16 * col.z, 255)));
	}

	if(!this.eent_eff_trail) { WriteByte(channel, this.eent_net_count); }
	return true;
}

void Send_Effect_Except(entity eff, vector eff_loc, vector eff_vel, int eff_cnt, vector eff_col, entity ignore)
{
	if(!eff) { return; }
	if(!eff.eent_eff_trail && !eff_cnt) { return; } // effect has no count!
	entity net_eff = new_pure(net_effect);
	net_eff.owner = eff;
	//net_eff.eent_broadcast = broadcast;
	net_eff.m_id = eff.m_id;
	net_eff.eent_net_velocity = eff_vel;
	net_eff.eent_net_location = eff_loc;
	net_eff.eent_net_count = eff_cnt;
	net_eff.eent_net_color = eff_col;
	net_eff.eent_eff_trail = eff.eent_eff_trail;

	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != ignore && !(IS_SPEC(it) && it.enemy && it.enemy == ignore), Net_Write_Effect(net_eff, it, 0));
	delete(net_eff);
}

void Send_Effect(entity eff, vector eff_loc, vector eff_vel, int eff_cnt)
{
	Send_Effect_Except(eff, eff_loc, eff_vel, eff_cnt, '0 0 0', NULL);
}

void Send_Effect_(string eff_name, vector eff_loc, vector eff_vel, int eff_cnt)
{
	// problem with this is, we might not have all the available effects for it
	FOREACH(Effects, it.eent_eff_name == eff_name, {
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
