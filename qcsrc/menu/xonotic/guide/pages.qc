#include "pages.qh"

METHOD(GuidePage, describe, string(GuidePage this))
{
	return this.m_description;
}
METHOD(GuidePage, display, void(GuidePage this, void(string name, string icon) returns))
{
	returns(this.m_title, "nopreview_map");
}
