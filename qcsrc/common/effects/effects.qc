#ifdef CSQC
void Read_Effect(bool is_new)
{
	int net_name = (EFFECT_COUNT >= 255) ? ReadShort() : ReadByte();

	entity eff = effects_ent[net_name];

	vector v, vel = '0 0 0';
	int eff_cnt = 1;
	bool eff_trail = eff.eent_eff_trail;
	v_x = ReadCoord();
	v_y = ReadCoord();
	v_z = ReadCoord();

	bool use_vel = ReadByte();
	if(use_vel)
	{
		vel_x = ReadCoord();
		vel_y = ReadCoord();
		vel_z = ReadCoord();
	}

	if(!eff_trail)
		eff_cnt = ReadByte();

	if(is_new)
	{
		if(eff_trail)
			WarpZone_TrailParticles(world, particleeffectnum(eff), v, vel);
		else
			pointparticles(particleeffectnum(eff), v, vel, eff_cnt);
	}
}
#endif

#ifdef SVQC
bool Net_Write_Effect(entity client, int sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_EFFECT);
	(EFFECT_COUNT >= 255)
	? WriteShort(MSG_ENTITY, self.m_id)
	: WriteByte(MSG_ENTITY, self.m_id);
	WriteCoord(MSG_ENTITY, self.eent_net_location_x);
	WriteCoord(MSG_ENTITY, self.eent_net_location_y);
	WriteCoord(MSG_ENTITY, self.eent_net_location_z);

	// attempt to save a tiny bit more bandwidth by not sending velocity if it isn't set
	if(self.eent_net_velocity)
	{
		WriteByte(MSG_ENTITY, true);
		WriteCoord(MSG_ENTITY, self.eent_net_velocity_x);
		WriteCoord(MSG_ENTITY, self.eent_net_velocity_y);
		WriteCoord(MSG_ENTITY, self.eent_net_velocity_z);
	}
	else { WriteByte(MSG_ENTITY, false); }

	if(!self.eent_eff_trail) { WriteByte(MSG_ENTITY, self.eent_net_count); }
	return true;
}

void Send_Effect(entity eff, vector eff_loc, vector eff_vel, int eff_cnt)
{
	if(!eff) { return; }
	if(!eff.eent_eff_trail && !eff_cnt) { return; } // effect has no count!
	entity net_eff = spawn();
	net_eff.owner = eff;
	net_eff.classname = "net_effect";
	//net_eff.eent_broadcast = broadcast;
	net_eff.m_id = eff.m_id;
	net_eff.eent_net_velocity = eff_vel;
	net_eff.eent_net_location = eff_loc;
	net_eff.eent_net_count = eff_cnt;
	net_eff.eent_eff_trail = eff.eent_eff_trail;

	net_eff.think = SUB_Remove;
	net_eff.nextthink = time + 0.2; // don't need to keep this long

	Net_LinkEntity(net_eff, false, 0, Net_Write_Effect);
}

void Send_Effect_(string eff_name, vector eff_loc, vector eff_vel, int eff_cnt)
{
	// problem with this is, we might not have all the available effects for it
	FOREACH(effects_ent, it.eent_eff_name == eff_name, LAMBDA(
		Send_Effect(it, eff_loc, eff_vel, eff_cnt);
		return;
	));
	// revert to engine handling
	pointparticles(_particleeffectnum(eff_name), eff_loc, eff_vel, eff_cnt);
}
#endif
