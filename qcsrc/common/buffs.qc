#if defined(CSQC)
	#include "../dpdefs/csprogsdefs.qh"
	#include "../client/defs.qh"
	#include "buffs.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../dpdefs/progsdefs.qh"
    #include "../dpdefs/dpextensions.qh"
    #include "buffs.qh"
#endif

vector Buff_Color(int buff_id)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_id == e.items)
			return e.colormod;
	return '1 1 1';
}

string Buff_PrettyName(int buff_id)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_id == e.items)
			return e.message;
	return "";
}

string Buff_Name(int buff_id)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_id == e.items)
			return e.netname;
	return "";
}

int Buff_Type_FromName(string buff_name)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_name == e.netname)
			return e.items;
	return 0;
}

int Buff_Type_FromSprite(string buff_sprite)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_sprite == e.model2)
			return e.items;
	return 0;
}


int Buff_Skin(float buff_id)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_id == e.items)
			return e.skin;
	return 0;
}

string Buff_Sprite(int buff_id)
{
	entity e;
	for(e = Buff_Type_first; e; e = e.enemy)
		if(buff_id == e.items)
			return e.model2;
	return "";
}
