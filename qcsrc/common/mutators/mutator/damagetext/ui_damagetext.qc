#include "ui_damagetext.qh"

#include <menu/gamesettings.qh>
#include <menu/xonotic/tab.qh>

CLASS(XonoticDamageTextSettings, XonoticTab)
    REGISTER_SETTINGS(damagetext, NEW(XonoticDamageTextSettings));
    ATTRIB(XonoticDamageTextSettings, title, string, _("Damage text"));
    ATTRIB(XonoticDamageTextSettings, intendedWidth, float, 0.9);
    ATTRIB(XonoticDamageTextSettings, rows, float, 15.5);
    ATTRIB(XonoticDamageTextSettings, columns, float, 5);
    INIT(XonoticDamageTextSettings) { this.configureDialog(this); }
    METHOD(XonoticDamageTextSettings, showNotify, void(entity this)) { loadAllCvars(this); }
    METHOD(XonoticDamageTextSettings, fill, void(entity this))
    {
        entity e;
        this.gotoRC(this, 0, 1); this.setFirstColumn(this, this.currentColumn);
            this.TD(this, 1, 3, makeXonoticCheckBox(0, "cl_damagetext", _("Draw damage numbers")));
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Font size minimum:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size_min"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Font size maximum:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size_max"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Accumulate range:")));
                setDependent(e, "cl_damagetext", 1, 1);
            // 1 as min because shotgun sends damagetext per pellet (see https://gitlab.com/xonotic/xonotic-data.pk3dir/issues/1994).
            // It's capped to 1 in code too but let's not lie to users by allowing the slider to go to 0, it would still accumulate
            // when hitting a stationary player using a weapon with no push.
            this.TD(this, 1, 2, e = makeXonoticSlider(1, 500, 1, "cl_damagetext_accumulate_range"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Lifetime:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 10, 1, "cl_damagetext_alpha_lifetime"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_color", "cl_damagetext_color"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
        this.TR(this);
        // friendly fire
            this.TD(this, 1, 3, e = makeXonoticCheckBox(0, "cl_damagetext_friendlyfire", _("Draw damage numbers for friendly fire")));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
                setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_friendlyfire", 1, 1);
            this.TD(this, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_friendlyfire_color", "cl_damagetext_friendlyfire_color"));
                setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_friendlyfire", 1, 1);
        this.TR(this);
    }
ENDCLASS(XonoticDamageTextSettings)
