#include "net_notice.qh"

REGISTER_NET_TEMP(TE_CSQC_SVNOTICE)

#ifdef SVQC
void sv_notice_join_think()
{
    SELFPARAM();
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
    entity _head;
    FOR_EACH_REALCLIENT(_head)
        sv_notice_to(_head, _notice, _howlong, _modal);

}

#endif // SVQC

#ifdef CSQC
NET_HANDLE(TE_CSQC_SVNOTICE, bool isNew)
{
	cl_notice_read();
	return true;
}
entity cl_notices;
STATIC_INIT(cl_notice)
{
    cl_notices = LL_NEW();
}
void cl_notice_read()
{
    entity _notice = new(sv_notice);
    make_pure(_notice);
    _notice.netname = strzone(ReadString());
    _notice.alpha = ReadLong() + time;
    _notice.skin = ReadByte();
    LL_PUSH(cl_notices, _notice);
}

void cl_notice_run()
{
    bool flag = false;
    LL_EACH(cl_notices, it.alpha > time, LAMBDA(flag = true; break));
    if (!flag) return;
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
    #define OUT(s, z) MACRO_BEGIN { drawcolorcodedstring(v3, s, '1 1 0' * z, 1, DRAWFLAG_NORMAL); v3.y += z + 4; } MACRO_END

    OUT(_("^1Server notices:"), 32);
    LL_EACH(cl_notices, it.alpha > time, LAMBDA(
        string s = sprintf(_("^7%s (^3%d sec left)"), it.netname , rint(it.alpha - time));
        OUT(s, 16);
    ));
    #undef OUT
}

#endif // CSQC
