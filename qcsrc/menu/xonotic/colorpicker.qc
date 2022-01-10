#include "colorpicker.qh"

#include "inputbox.qh"

entity makeXonoticColorpicker(entity theTextbox)
{
	entity me;
	me = NEW(XonoticColorpicker);
	me.configureXonoticColorpicker(me, theTextbox);
	return me;
}

void XonoticColorpicker_configureXonoticColorpicker(entity me, entity theTextbox)
{
	me.controlledTextbox = theTextbox;
	me.configureImage(me, me.image);
}

METHOD(XonoticColorpicker, mousePress, bool(XonoticColorpicker this, vector pos))
{
	this.mouseDrag(this, pos);
	return true;
}

// must match hslimage.c
vector hslimage_color(vector v, vector margin)
{
    v_x = (v.x - margin.x) / (1 - 2 * margin.x);
    v_y = (v.y - margin.y) / (1 - 2 * margin.y);
    if(v.x < 0) v_x = 0;
    if(v.y < 0) v_y = 0;
    if(v.x > 1) v_x = 1;
    if(v.y > 1) v_y = 1;
    if(v.y > 0.875) // grey bar
        return hsl_to_rgb(eZ * v.x);
    else
        return hsl_to_rgb(v.x * 6 * eX + eY + v.y / 0.875 * eZ);
}

vector color_hslimage(vector v, vector margin)
{
	vector pos = '0 0 0';
	v = rgb_to_hsl(v);
	if (v.y)
	{
		pos_x = v.x / 6;
		pos_y = v.z * 0.875;
	}
	else // grey scale
	{
		pos_x = v.z;
		pos_y = 0.875 + 0.07;
	}
	pos_x = margin.x + pos.x * (1 - 2 * margin.x);
	pos_y = margin.y + pos.y * (1 - 2 * margin.y);
	return pos;
}

float XonoticColorpicker_mouseDrag(entity me, vector coords)
{
	int i;
	for (;;)
	{
		i = me.controlledTextbox.cursorPos;
		string theText = me.controlledTextbox.text;
		vector res = checkColorCode(theText, strlen(theText), i, true);
		if (!res.x)
			break;

		int cc_len = res.x;
		int new_pos = i - res.y;
		theText = strcat(substring(theText, 0, new_pos), substring(theText, new_pos + cc_len, -1));
		me.controlledTextbox.setText(me.controlledTextbox, theText);
		me.controlledTextbox.cursorPos = new_pos;
	}

	if(substring(me.controlledTextbox.text, i-1, 1) == "^")
	{
		if(!isCaretEscaped(me.controlledTextbox.text, i-1))
			me.controlledTextbox.enterText(me.controlledTextbox, "^"); // escape previous caret
	}

	vector margin;
	margin = me.imagemargin;
	if(coords.x >= margin.x)
	if(coords.y >= margin.y)
	if(coords.x <= 1 - margin.x)
	if(coords.y <= 1 - margin.y)
		me.controlledTextbox.enterText(me.controlledTextbox, rgb_to_hexcolor(hslimage_color(coords, margin)));

	return 1;
}

float XonoticColorpicker_mouseRelease(entity me, vector coords)
{
	m_play_click_sound(MENU_SOUND_SLIDE);
	me.mouseDrag(me, coords);
	return 1;
}

void XonoticColorpicker_focusLeave(entity me)
{
	me.controlledTextbox.saveCvars(me.controlledTextbox);
}
float XonoticColorpicker_keyDown(entity me, float key, float ascii, float shift)
{
	return me.controlledTextbox.keyDown(me.controlledTextbox, key, ascii, shift);
}
void XonoticColorpicker_draw(entity me)
{
	SUPER(XonoticColorpicker).draw(me);

	float B, C, aC;
	C = cvar("r_textcontrast");
	B = cvar("r_textbrightness");

	// for this to work, C/(1-B) must be in 0..1
	// B must be < 1
	// C must be < 1-B

	B = bound(0, B, 1);
	C = bound(0, C, 1-B);

	aC = 1 - C / (1 - B);

	draw_Picture(me.imgOrigin, strcat(me.src, "_m"), me.imgSize, '0 0 0', aC);
	draw_Picture(me.imgOrigin, strcat(me.src, "_m"), me.imgSize, me.color, B);
}
