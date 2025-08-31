#include "magnet.qh"

#ifdef SVQC
METHOD(MagnetBuff, m_tick, void(StatusEffect this, entity actor))
{
	if (IS_PLAYER(actor))
	{
		entity head = WarpZone_FindRadius(
			actor.origin + actor.view_ofs,  // line from eyes
			autocvar_g_buffs_magnet_range,
			true                            // require line of sight
		);
		for (; head; head = head.chain)
			if (head.itemdef) // intentionally doesn't apply to other buffs
			if (gettouch(head))
				gettouch(head)(head, actor);
	}

	SUPER(MagnetBuff).m_tick(this, actor);
}
#endif // SVQC
