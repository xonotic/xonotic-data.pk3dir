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

float Violence_WeaponDamage_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_WEAPONDAMAGE);
	WriteByte(MSG_ENTITY, self.cnt); // the damage weapon
	WriteByte(MSG_ENTITY, self.state); // species
	WriteCoord(MSG_ENTITY, floor(self.origin_x));
	WriteCoord(MSG_ENTITY, floor(self.origin_y));
	WriteCoord(MSG_ENTITY, floor(self.origin_z));
	return TRUE;
}

void Violence_WeaponDamage(entity pl, float type)
{
	entity e;

	e = spawn();
	e.classname = "weapondamage";
	e.cnt = type;
	e.state |= 8 * pl.species; // gib type, ranges from 0 to 15
	setorigin(e, pl.origin);

	Net_LinkEntity(e, FALSE, 0.2, Violence_WeaponDamage_SendEntity);
}

.float lifetime;
.float weapondamage_counter;

void Violence_WeaponDamage_DoRepeat()
{
	if(time > self.lifetime)
	{
		self.nextthink = 0;
		remove(self);
		return;
	}

	if(time > self.weapondamage_counter)
	{
		Violence_WeaponDamage(self.owner, self.cnt);
		self.weapondamage_counter = time + 0.5; // TO BE CVARED
	}
}

void Violence_WeaponDamage_SetRepeat(entity pl, float type)
{
	entity repeater;
	repeater = spawn();
	repeater.classname = "weapondamage_repeater";
	repeater.owner = pl;
	repeater.origin = pl.origin;
	repeater.cnt = type;
	repeater.lifetime = time + 3; // TO BE CVARED
	repeater.think = Violence_WeaponDamage_DoRepeat;
	repeater.nextthink = time;
}
