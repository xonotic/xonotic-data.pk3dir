#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "../common/constants.qh"
#endif

void te_csqc_lightningarc(vector from,vector to)
{
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_ARC);

	WriteCoord(MSG_BROADCAST, from.x);
	WriteCoord(MSG_BROADCAST, from.y);
	WriteCoord(MSG_BROADCAST, from.z);
	WriteCoord(MSG_BROADCAST, to.x);
	WriteCoord(MSG_BROADCAST, to.y);
	WriteCoord(MSG_BROADCAST, to.z);
}

