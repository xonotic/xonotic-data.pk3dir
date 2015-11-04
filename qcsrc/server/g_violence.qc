#include "g_violence.qh"

.int state;

REGISTER_NET_TEMP(net_gibsplash, bool isNew)

bool Violence_GibSplash_SendEntity(entity this, entity to, int sf)
{
	int channel = MSG_ONE;
	msg_entity = to;
	WriteHeader(channel, net_gibsplash);
	WriteByte(channel, this.state); // actually type
	WriteByte(channel, bound(1, this.cnt * 16, 255)); // gibbage amount multiplier
	WriteShort(channel, floor(this.origin.x / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(channel, floor(this.origin.y / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(channel, floor(this.origin.z / 4)); // not using a coord here, as gibs don't need this accuracy
	WriteShort(channel, this.oldorigin.x); // acrually compressed velocity
	return true;
}

void Violence_GibSplash_At(vector org, vector dir, float type, float amount, entity gibowner, entity attacker)
{SELFPARAM();
	if(g_cts) // no gibs in CTS
		return;

	entity e = new(gibsplash);
	e.cnt = amount;
	e.state = type; // should stay smaller than 15
	if(!sound_allowed(MSG_BROADCAST, gibowner) || !sound_allowed(MSG_BROADCAST, attacker))
		e.state |= 0x40; // "silence" bit
	e.state |= 8 * self.species; // gib type, ranges from 0 to 15

	// if this is a copied dead body, send the num of its player instead
	// TODO: remove this field, read from model txt files
	if(self.classname == "body")
		e.team = num_for_edict(self.enemy);
	else
		e.team = num_for_edict(self);

	setorigin(e, org);
	e.velocity = dir;

	e.oldorigin_x = compressShortVector(e.velocity);

	entity cl; FOR_EACH_REALCLIENT(cl) Violence_GibSplash_SendEntity(e, cl, 0);
	remove(e);
}

void Violence_GibSplash(entity source, float type, float amount, entity attacker)
{
	Violence_GibSplash_At(source.origin + source.view_ofs, source.velocity, type, amount, source, attacker);
}
