float Violence_GibSplash_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_GIBSPLASH);
	WriteByte(MSG_ENTITY, self.state); // actually type
	WriteByte(MSG_ENTITY, bound(1, self.cnt * 16, 255)); // gibbage amount multiplier
	WriteShort(MSG_ENTITY, floor(self.origin_x / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(MSG_ENTITY, floor(self.origin_y / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(MSG_ENTITY, floor(self.origin_z / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(MSG_ENTITY, self.oldorigin_x); // acrually compressed velocity
	return TRUE;
}

// TODO maybe convert this to a TE?
void Violence_GibSplash_At(vector org, vector dir, float type, float amount, entity gibowner, entity attacker)
{
	if(g_cts) // no gibs in CTS
		return;

	entity e;

	e = spawn();
	e.classname = "gibsplash";
	e.cnt = amount;
	e.state = type; // should stay smaller than 15
	if(!sound_allowed(MSG_BROADCAST, gibowner) || !sound_allowed(MSG_BROADCAST, attacker))
		e.state |= 0x40; // "silence" bit
	e.state |= 8 * self.species; // gib type, ranges from 0 to 15
	setorigin(e, org);
	e.velocity = dir;

	e.oldorigin_x = compressShortVector(e.velocity);

	Net_LinkEntity(e, FALSE, 0.2, Violence_GibSplash_SendEntity);
}

void Violence_GibSplash(entity source, float type, float amount, entity attacker)
{
	Violence_GibSplash_At(source.origin + source.view_ofs, source.velocity, type, amount, source, attacker);
}

float Violence_DamageEffect_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_DAMAGEEFFECT);
	WriteByte(MSG_ENTITY, self.cnt); // the damage weapon
	WriteByte(MSG_ENTITY, self.state); // species
	WriteCoord(MSG_ENTITY, floor(self.origin_x));
	WriteCoord(MSG_ENTITY, floor(self.origin_y));
	WriteCoord(MSG_ENTITY, floor(self.origin_z));
	return TRUE;
}

void Violence_DamageEffect(entity pl, float type)
{
	entity e;

	e = spawn();
	e.classname = "weapondamage";
	e.cnt = type;
	e.state |= 8 * pl.species; // gib type, ranges from 0 to 15
	setorigin(e, pl.origin);

	Net_LinkEntity(e, FALSE, 0.2, Violence_DamageEffect_SendEntity);
}

.entity damageeffect_repeater;
.float lifetime;

void Violence_DamageEffect_DoRepeat()
{
	if(time > self.lifetime)
	{
		self.nextthink = 0;
		remove(self.owner.damageeffect_repeater);
		self.owner.damageeffect_repeater = world;
		return;
	}

	Violence_DamageEffect(self.owner, self.cnt);
	self.nextthink = time + autocvar_sv_damageeffect_tick;
}

void Violence_DamageEffect_SetRepeat(entity pl, float damage, float type)
{
	if not(autocvar_sv_damageeffect_tick && autocvar_sv_damageeffect_lifetime)
		return;
	if(sv_gentle || !type)
		return; // return if gentle mode is enabled or the damage was not caused by a weapon

	// if a repeater doesn't exist, spawn one, else update the existing one
	if(pl.damageeffect_repeater == world)
	{
		pl.damageeffect_repeater = spawn();
		pl.damageeffect_repeater.classname = "damageeffect_repeater";
		pl.damageeffect_repeater.owner = pl;
		pl.damageeffect_repeater.think = Violence_DamageEffect_DoRepeat;

		pl.damageeffect_repeater.lifetime = time + (autocvar_sv_damageeffect_lifetime * damage);
	}
	else
	{
		// if the repeater is being updated, increase its lifetime instead of re-setting it entirely
		// this fixes the shotgun among other things, where only the damage of one bullet would be taken into account
		pl.damageeffect_repeater.lifetime += (autocvar_sv_damageeffect_lifetime * damage);
	}

	pl.damageeffect_repeater.cnt = type;
	pl.damageeffect_repeater.nextthink = time;
}
