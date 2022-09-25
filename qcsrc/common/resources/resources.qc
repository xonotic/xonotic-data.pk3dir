#include "resources.qh"

#ifdef GAMEQC
Resource GetResourceType(.float res_field)
{
	FOREACH(Resources, it.m_field == res_field, return it);
	error("GetResourceType: Invalid field.");
	return RES_NONE;
}

.float GetResourceField(Resource res_type)
{
	return res_type.m_field;
}
#endif
