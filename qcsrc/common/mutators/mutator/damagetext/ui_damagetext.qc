#include "ui_damagetext.qh"

#include <menu/gamesettings.qh>
#include <menu/xonotic/tab.qh>

CLASS(XonoticDamageTextSettings, XonoticTab)
    REGISTER_SETTINGS(damagetext, NEW(XonoticDamageTextSettings));
    ATTRIB(XonoticDamageTextSettings, title, string, _("Damage"));
    ATTRIB(XonoticDamageTextSettings, titleTooltip, string, _("Adjust damage numbers, effects, gibs and harsh language"));
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

	this.TR(this);
	this.TR(this);
		this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Damage to models:")));
		this.TD(this, 1, 2, e = makeXonoticTextSlider("cl_damageeffect"));
			e.addValue(e, ZCTX(_("DMGFX^Disabled")), "0");
			e.addValue(e, _("Skeletal"), "1");
			e.addValue(e, ZCTX(_("DMGFX^All")), "2");
			e.configureXonoticTextSliderValues(e);
	this.TR(this);
	this.TR(this);
		this.TD(this, 1, 3, e = makeXonoticCheckBox_T(0, "cl_gentle", _("Disable all gibs, blood and harsh language"),
			_("Replace blood and gibs with content that does not have any gore effects")));
			e.sendCvars = true;
	this.TR(this);
		this.TD(this, 1, 3, e = makeXonoticCheckBox_T(0, "cl_gentle_messages", _("Disable harsh language in centreprints and frag messages"),
			_("Replace blood and gibs with content that does not have any gore effects")));
			e.sendCvars = true;
			setDependent(e, "cl_gentle", 0, 0);
	this.TR(this);
		this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Blood effect:")));
			setDependent(e, "cl_gentle", 0, 0);
		this.TD(this, 1, 2, e = makeXonoticTextSlider("cl_gentle_damage"));
			e.addValue(e, _("Blood"), "0");
			e.addValue(e, _("White flash"), "1");
			e.addValue(e, _("Colorful flash"), "2");
			e.configureXonoticTextSliderValues(e);
			e.sendCvars = true;
			setDependent(e, "cl_gentle", 0, 0);
	this.TR(this);
		this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Gib effect:")));
			setDependent(e, "cl_gentle", 0, 0);
		this.TD(this, 1, 2, e = makeXonoticTextSlider("cl_gentle_gibs"));
			e.addValue(e, _("Gibs"), "0");
			e.addValue(e, _("White smoke"), "1");
			e.addValue(e, _("Colorful clouds"), "2");
			e.configureXonoticTextSliderValues(e);
			e.sendCvars = true;
			setDependent(e, "cl_gentle", 0, 0);
	this.TR(this);
		this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Gib quantity:")));
			setDependent(e, "cl_gentle", 0, 0);
		this.TD(this, 1, 2, e = makeXonoticTextSlider("cl_nogibs"));
			e.addValue(e, ZCTX(_("GIBS^None")), "1");
			e.addValue(e, ZCTX(_("GIBS^Few")), "0.75");
			e.addValue(e, ZCTX(_("GIBS^Many")), "0.5");
			e.addValue(e, ZCTX(_("GIBS^Lots")), "0");
			e.configureXonoticTextSliderValues(e);
			e.sendCvars = true;
			setDependent(e, "cl_gentle", 0, 0);
    }
ENDCLASS(XonoticDamageTextSettings)
