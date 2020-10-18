#include "scrollpanel.qh"

METHOD(XonoticScrollPanel, drawListBoxItem, void(XonoticScrollPanel this, int i, vector absSize, bool isSelected, bool isFocused))
{
	XonoticTab p = this.currentPanel;
	p.draw(p);
}

METHOD(XonoticScrollPanel, resizeNotify, void(XonoticScrollPanel this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
{
	SUPER(XonoticScrollPanel).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);
	this.scrollToItem(this, 0);
	XonoticTab p = this.currentPanel;
	float m = p.firstChild.rows / this.viewportHeight;
	this.itemHeight = m;
	relSize.y *= m;
	absSize.y *= m;
	p.resizeNotify(p, relOrigin, relSize, absOrigin, absSize);
}

#define X(mouseFunc) \
METHOD(XonoticScrollPanel, mouseFunc, bool(XonoticScrollPanel this, vector pos)) \
{ \
	SUPER(XonoticScrollPanel).mouseFunc(this, pos); \
	XonoticTab p = this.currentPanel; \
	this.setFocus(this, p); \
	\
	vector o = -eY * this.scrollPos; \
	vector s = eX * (1 - this.controlWidth) + eY * this.itemHeight; \
	return p.mouseFunc(p, globalToBox(pos, o, s)); \
}
X(mouseMove)
X(mousePress)
X(mouseDrag)
X(mouseRelease)
#undef X

#define X(keyFunc) \
METHOD(XonoticScrollPanel, keyFunc, bool(XonoticScrollPanel this, int key, int ascii, bool shift)) \
{ \
	XonoticTab p = this.currentPanel; \
	return p.keyFunc(p, key, ascii, shift) || SUPER(XonoticScrollPanel).keyFunc(this, key, ascii, shift); \
}
X(keyDown)
X(keyUp)
#undef X
