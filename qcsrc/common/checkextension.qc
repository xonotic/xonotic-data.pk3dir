#include "checkextension.qh"

void CheckEngineExtensions(void)
{
	if (!cvar("pr_checkextension"))
		LOG_FATAL("Engine lacks the QC extension system.");

	if (!checkextension("DP_QC_URI_GET") || !checkextension("DP_QC_URI_POST"))
		LOG_WARN("Engine lacks HTTP support, XonStat and map downloads are unavailable.");

	if (!checkextension("DP_CRYPTO"))
		LOG_WARN("Engine lacks DP_CRYPTO, Player IDs (required for XonStat and CTS/CTF records) are unavailable.");

#ifdef SVQC // change to GAMEQC if/when we use nudgeoutofsolid in CSQC
	if (!checkextension("DP_QC_NUDGEOUTOFSOLID"))
	{
		LOG_WARN("Engine lacks DP_QC_NUDGEOUTOFSOLID, falling back to WarpZoneLib_MoveOutOfSolid().");
		// DP_QC_NUDGEOUTOFSOLID fixes many cases WarpZoneLib_MoveOutOfSolid() can't, usually in less CPU time
		nudgeoutofsolid = WarpZoneLib_MoveOutOfSolid;
	}
#endif

	// TODO: add proper warns/errors for other extensions we depend on
}
