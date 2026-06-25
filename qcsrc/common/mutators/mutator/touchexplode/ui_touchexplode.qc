#include "ui_touchexplode.qh"

#include <menu/xonotic/slider.qh>

entity makeXonoticMutatorTouchExplodeTab()
{
	entity me = NEW(XonoticMutatorTouchExplodeTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorTouchExplodeTab_fill(entity me)
{
	entity e;

	Mutators_main_checkbox(me);

	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Damage:")));
		me.TD(me, 1, 2.5, e = makeXonoticSlider(0, 100, 5, "g_touchexplode_damage"));
}

METHOD(XonoticMutatorTouchExplodeTab, describe, string(XonoticMutatorTouchExplodeTab me))
{
	return _("An explosion occurs when two players collide.");
}
METHOD(XonoticMutatorTouchExplodeTab, canEnable, bool(XonoticMutatorTouchExplodeTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
