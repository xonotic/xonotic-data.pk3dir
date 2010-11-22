.entity accuracy;
.float accuracy_hit[WEP_MAXCOUNT];
.float accuracy_fired[WEP_MAXCOUNT];

void accuracy_send(entity to, float sf)
{
	float w, f;
	WriteByte(MSG_ENTITY, ENT_CLIENT_ACCURACY);
	if(to != self.owner)
		if not(self.owner.cvar_cl_accuracy_data_share && autocvar_sv_accuracy_data_share)
			sf = 0;
	// note: zero sendflags can never be sent... so we can use that to say that we send no accuracy!
	WriteInt24_t(MSG_ENTITY, sf);
	if(sf == 0)
		return TRUE;
	// note: we know that client and server agree about SendFlags...
	for(w = 0, f = 1; w <= WEP_LAST - WEP_FIRST; ++w, f *= 2)
	{
		if(sf & f)
		{
			if(self.(accuracy_fired[w]))
				WriteByte(MSG_ENTITY, 0);
			else
				WriteByte(MSG_ENTITY, 1 + bound(0, (254.0 * self.(accuracy_hit[w])) / self.(accuracy_fired[w]), 254));
		}
	}
	return TRUE;
}

// init/free
void accuracy_init(entity e)
{
	e.accuracy = spawn();
	e.accuracy.owner = e;
	e.accuracy.classname = "accuracy";
	e.accuracy.SendEntity = accuracy_send;
}

void accuracy_free(entity e)
{
	remove(e.accuracy);
}

// force a resend of a player's accuracy stats
void accuracy_resend(entity e)
{
	e.accuracy.SendFlags = 0xFFFFFF;
}

// update accuracy stats
void accuracy_set(entity e, float w, float hit, float fired)
{
	e = e.accuracy;
	w -= WEP_FIRST;
	e.(accuracy_hit[w]) = hit;
	e.(accuracy_fired[w]) = fired;
	e.SendFlags |= pow(2, w);
}

void accuracy_add(entity e, float w, float hit, float fired)
{
	e = e.accuracy;
	w -= WEP_FIRST;
	e.(accuracy_hit[w]) += hit;
	e.(accuracy_fired[w]) += fired;
	e.SendFlags |= pow(2, w);
}
