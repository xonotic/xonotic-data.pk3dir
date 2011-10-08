/*
Touch handler.
*/
void item_key_touch(void) {
	if (other.classname != "player")
		return;
		
	// player already picked up this key
	if (other.itemkeys & self.itemkeys)
		return;
	
	other.itemkeys |= self.itemkeys;
	
	if (self.message)
		centerprint(other, self.message);
}

/*
Spawn a key with given model, key code and color.
*/
void spawn_item_key(float key_code) {
	self.itemkeys = key_code;
	precache_model(self.model);
	
	if(self.spawnflags & 1)
		self.noalign = 1;
	if (self.noalign)
		self.movetype = MOVETYPE_NONE;
	else
		self.movetype = MOVETYPE_TOSS;
		
	setsize(self, '-16 -16 -24', '16 16 32');
	setmodel(self, self.model);
	self.modelflags |= MF_ROTATE;
	
	if (!self.noalign)
	{
		// first nudge it off the floor a little bit to avoid math errors
		setorigin(self, self.origin + '0 0 1');
		// note droptofloor returns FALSE if stuck/or would fall too far
		droptofloor();
	}

	self.touch = item_key_touch;
}


/*
Spawn silver key.
*/
void spawnfunc_item_key1(void) {
	if (!self.model)
		self.model = "models/keys/key.md3";
	
	if (!self.colormod)
		self.colormod = '.9 .9 .9';
			
	if (!self.message)
		self.message = "You've picked up the silver key!";
		
	spawn_item_key(KEYS_SILVER_KEY);
}

/*
Spawn gold key.
*/
void spawnfunc_item_key2(void) {
	if (!self.model)
		self.model = "models/keys/key.md3";
		
	if (!self.colormod)
		self.colormod = '1 .9 0';
	
	if (!self.message)
		self.message = "You've picked up the gold key!";
		
	spawn_item_key(KEYS_GOLD_KEY);
}


