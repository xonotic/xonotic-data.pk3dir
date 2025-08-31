#include "magnet.qh"

#ifdef SVQC
METHOD(MagnetBuff, m_tick, void(StatusEffect this, entity actor))
{
	if (IS_PLAYER(actor))
	{
		bool brs = autocvar_g_buffs_magnet_range_buff <= autocvar_g_buffs_magnet_range_item; // buff range smaller
		entity head = WarpZone_FindRadius(
			actor.origin + actor.view_ofs,
			(brs ? autocvar_g_buffs_magnet_range_item : autocvar_g_buffs_magnet_range_buff),
			true // require line of sight
		);
		for (; head; head = head.chain)
			if (head.itemdef)
			{
				if ((brs &&  head.buffdef)  // using the smaller range, so have to check vdist
				|| (!brs && !head.buffdef)) //
				{
					if (vdist(head.WarpZone_findradius_dist, >, (brs ? autocvar_g_buffs_magnet_range_buff : autocvar_g_buffs_magnet_range_item)))
						continue;
				}
				if (gettouch(head))
					gettouch(head)(head, actor);
			}
	}

	SUPER(MagnetBuff).m_tick(this, actor);
}
#endif // SVQC
