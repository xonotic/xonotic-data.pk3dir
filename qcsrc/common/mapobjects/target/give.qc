#ifdef SVQC

/*QUAKED target_give (1 0 0) (-8 -8 -8) (8 8 8)
Gives the activator all the items pointed to.
*/
void target_give_use(entity this, entity actor, entity trigger)
{
	if (!IS_PLAYER(actor) || IS_DEAD(actor))
		return;

	IL_EACH(g_items, it.targetname == this.target,
	{
		// Q3 calls the item's touch func then disables respawn, probably not a good idea here.
		if (it.itemdef)
		{
			if (!ITEM_HANDLE(Pickup, it.itemdef, it, actor))
				continue;
			int ch = (it.itemdef.instanceOfPowerup && it.itemdef.m_itemid != IT_RESOURCE) ? CH_TRIGGER_SINGLE : CH_TRIGGER;
			_sound(actor, ch, it.item_pickupsound, VOL_BASE, ATTEN_NORM);
		}
		else if (it.buffdef)
		{
			if (!GiveBuff(actor, it.buffdef, OP_PLUS, it.buffs_finished ? it.buffs_finished : it.buffdef.m_time(it.buffdef)))
				continue;
			sound(actor, CH_TRIGGER, SND_SHIELD_RESPAWN, VOL_BASE, ATTN_NORM);
		}

		if (it.target != "" && it.target != "###item###") // q3compat
			SUB_UseTargets(it, actor, trigger);
	});
}

spawnfunc(target_give)
{
	this.use = target_give_use;
}

#endif // SVQC
