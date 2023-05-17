#include "cl_squad.qh"

int csqcsquad_cnt = 0;
int csqcsquad[255]; // 255 is the engine limit on maxclients

NET_HANDLE(TE_CSQC_BR_SQUAD, bool isNew)
{
    csqcsquad_cnt = ReadByte();

    if(csqcsquad_cnt == 0)
    {
        LOG_SEVERE("server sent empty squad data");
        return true;
    }

    for(int i = 0; i < csqcsquad_cnt; ++i)
    {
        int entnum = ReadByte();
        csqcsquad[i] = entnum;
    }

    return true;
}

bool br_isSameSquad(entity this)
{
    for(int i = 0; i < csqcsquad_cnt; ++i)
    {
        int member = csqcsquad[i];

        if(this.entnum == member)
            return true;
    }

    return false;
}

bool br_inSquad()
{
    return (csqcsquad_cnt > 0);
}
