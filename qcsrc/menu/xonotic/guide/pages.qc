#include "pages.qh"

METHOD(GuidePage, describe, string(GuidePage this))
{
	TC(GuidePage, this);
	return this.m_description;
}
METHOD(GuidePage, display, void(GuidePage this, void(string name, string icon) returns))
{
	TC(GuidePage, this);
	string icon_str;
	if (this.m_title == _("Introduction"))
		icon_str = "gametype_dm";
	else if (this.m_title == _("Movement"))
		icon_str = "gametype_inv";
	else
		icon_str = string_null;
	returns(this.m_title, icon_str);
}
