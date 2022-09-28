#include "net_notice.qh"

REGISTER_NET_TEMP(TE_CSQC_SVNOTICE)

#ifdef SVQC
void sv_notice_join_think(entity this)
{
    int argc = tokenizebyseparator(autocvar_sv_join_notices, "|");
    if (argc <= 0) return;
    for (int i = 0; i < argc; ++i)
        sv_notice_to(this, argv(i), autocvar_sv_join_notices_time, false);
}

void sv_notice_join(entity _to)
{
    // to-do: make sv_join_notices support per-entry times
    if (autocvar_sv_join_notices == "") return;
    defer(_to, 1, sv_notice_join_think);
}

void sv_notice_to(entity _to, string _notice, float _howlong, float _modal)
{
	msg_entity = _to;
	WriteHeader(MSG_ONE, TE_CSQC_SVNOTICE);
	WriteString(MSG_ONE, _notice);
	WriteLong(MSG_ONE, _howlong);
	WriteByte(MSG_ONE, _modal);
}

void sv_notice_toall(string _notice, float _howlong, float _modal)
{
    FOREACH_CLIENT(IS_REAL_CLIENT(it), sv_notice_to(it, _notice, _howlong, _modal));
}

#endif // SVQC

#ifdef CSQC
NET_HANDLE(TE_CSQC_SVNOTICE, bool isNew)
{
	cl_notice_read();
	return true;
}
entity cl_notices;
void cl_notice_read()
{
    entity _notice = new_pure(sv_notice);
    _notice.netname = strzone(ReadString());
    _notice.alpha = ReadLong() + time;
    _notice.skin = ReadByte();
    if(!cl_notices)
    	cl_notices = LL_NEW();
    LL_PUSH(cl_notices, _notice);
}

void cl_notice_run()
{
	if (!cl_notices)
		return;

    bool flag = false;
    LL_EACH(cl_notices, it.alpha > time, { flag = true; break; });
	if (!flag)
	{
		LL_DELETE(cl_notices);
		return;
	}

    const int M1 = 30;
    const int M2 = 10;

    vector v1 = '1 1 0' * M1;
    vector v2 = '0 0 0';
    v2.x = vid_conwidth - (2 * M1);
    v2.y = vid_conheight - (2 * M1);
    drawfill(v1, v2, '0 0 0', 0.5, DRAWFLAG_NORMAL);

    v1 = '1 1 0' * (M1 + M2);
    v2.x = vid_conwidth - (2 * (M1 + M2));
    v2.y = vid_conheight - (2 * (M1 + M2));
    drawfill(v1, v2, '0.5 0.5 0.5', 0.5, DRAWFLAG_NORMAL);

    vector v3 = v1 + '10 10 0';
	#define OUT(s, z) MACRO_BEGIN \
		drawcolorcodedstring(v3, s, '1 1 0' * z, 1, DRAWFLAG_NORMAL); \
		v3.y += z + 4; \
	MACRO_END

    float cur_time = 0;
    float time_width = 48;
    OUT(_("^1Server notices:"), 32);
    LL_EACH(cl_notices, it.alpha > time, {
        if(it.alpha - cur_time > 0.1)
        {
            cur_time = it.alpha;
            string s = sprintf("^3%d", ceil(cur_time - time));
            drawcolorcodedstring(v3 + eX * 0.5 * (time_width - stringwidth(s, true, '1 1 0' * 16)), s, '1 1 0' * 16, 1, DRAWFLAG_NORMAL);
            v3.x = v1.x + 10 + time_width;
        }
        OUT(it.netname, 16);
    });
    #undef OUT
}

#endif // CSQC
