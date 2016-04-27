// interpolating with the engine:
// it.movetype = MOVETYPE_STEP; // engine only interpolates this movetype
// it.flags |= FL_FLY;          // don't apply forces
// it.solid = SOLID_NOT;        // don't make stepping sounds

entity testent;

bool net_object_send(entity this, entity to, int sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_OBJECT);
	serialize(ENT_OBJECT, MSG_ENTITY, this);
	return true;
}

void spawnfunc_worldspawn()
{
	static_init();
	static_init_late();
	// static_init_precache();

	entity it = testent = spawn();
	precache_model("models/player/erebus.iqm");
	_setmodel(it, "models/player/erebus.iqm");

	Net_LinkEntity(it, true, 0, net_object_send);
}

void PlayerPreThink(entity this)
{
	// the truth: time
	// what the client knows: time - this.ping
	// for fairness, don't compensate shots beyond 400ms
	// what the client sees: _ - this.cl_interp;
}

void StartFrame()
{
	float f = 1 / autocvar_xon_sys_phys_dt;
	float n = 5;
	float x = ((floor(time * f) / f) % n) / n;
	vector norg = '0 1 0' * x * 500;
	if (norg != testent.origin)
	{
		if (!norg) testent.effects |= EF_TELEPORT_BIT;
		testent.SendFlags |= 1;
		setorigin(testent, norg);
		testent.angles = '0 -360 0' * x;
		// testent.origin = norg;
	}
}
