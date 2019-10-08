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
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_color", "cl_damagetext_color"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
        this.TR(this);
            this.TD(this, 1, 3, e = makeXonoticCheckBox(0, "cl_damagetext_friendlyfire", _("Draw damage numbers for friendly fire")));
                setDependent(e, "cl_damagetext", 1, 1);
    }
ENDCLASS(XonoticDamageTextSettings)
