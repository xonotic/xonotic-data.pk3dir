#include "checkextension.qh"

#ifdef GAMEQC
entity findbox_tofield_Fallback(vector mins, vector maxs, .entity tofield)
{
	// 0.03125 minimum radius because findradius returns no results if radius is zero
	// but findbox for a zero-sized box returns entities touching the specified point
	entity chain = findradius_tofield(0.5 * (mins + maxs), max(0.03125, 0.5 * vlen(maxs - mins)), tofield);
	entity prev = NULL;
	for (entity e = chain; e; e = e.tofield)
	{
		if (boxesoverlap(e.absmin, e.absmax, mins, maxs))
			prev = e;
		else // not in box so remove from chain
		{
			if (prev)
				prev.tofield = e.tofield;
			else
				chain = chain.tofield;
		}
	}
	return chain;
}
entity findbox_Fallback(vector mins, vector maxs)
{
	return findbox_tofield_Fallback(mins, maxs, chain);
}
#endif // GAMEQC

void CheckEngineExtensions(void)
{
	if (!cvar("pr_checkextension"))
		LOG_FATAL("Engine lacks the QC extension system.");

	if (!checkextension("DP_QC_URI_GET") || !checkextension("DP_QC_URI_POST"))
		LOG_WARN("Engine lacks HTTP support, XonStat and map downloads are unavailable.");

	if (!checkextension("DP_CRYPTO"))
		LOG_WARN("Engine lacks DP_CRYPTO, Player IDs (required for XonStat and CTS/CTF records) are unavailable.");

#ifdef SVQC // change to GAMEQC if/when we use nudgeoutofsolid in CSQC
	if (checkextension("DP_QC_NUDGEOUTOFSOLID"))
	{
		nudgeoutofsolid_CheckedEngineExtensions_usebuiltin();
	}
	else
	{
		LOG_WARN("Engine lacks DP_QC_NUDGEOUTOFSOLID, falling back to WarpZoneLib_MoveOutOfSolid().");
		// DP_QC_NUDGEOUTOFSOLID fixes many cases WarpZoneLib_MoveOutOfSolid() can't, usually in less CPU time
		nudgeoutofsolid = WarpZoneLib_MoveOutOfSolid;
	}

	if (!world.fullspawndata)
		LOG_WARN("Engine lacks entity fullspawndata, on Quake 3 maps some entities will malfunction.");
#endif

#ifdef GAMEQC
	if (checkextension("DP_QC_FINDBOX"))
	{
		findbox_CheckedEngineExtensions_usebuiltin();
		findbox_tofield_CheckedEngineExtensions_usebuiltin();
	}
	else
	{
		LOG_WARN("Engine lacks DP_QC_FINDBOX, performance will be suboptimal.");
		findbox = findbox_Fallback;
		findbox_tofield = findbox_tofield_Fallback;
	}
#endif

	// TODO: add proper warns/errors for other extensions we depend on
}
