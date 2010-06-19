#ifdef INTERFACE
CLASS(Item) EXTENDS(Object)
	METHOD(Item, draw, void(entity))
	METHOD(Item, keyDown, float(entity, float, float, float))
	METHOD(Item, keyUp, float(entity, float, float, float))
	METHOD(Item, mouseMove, float(entity, vector))
	METHOD(Item, mousePress, float(entity, vector))
	METHOD(Item, mouseDrag, float(entity, vector))
	METHOD(Item, mouseRelease, float(entity, vector))
	METHOD(Item, focusEnter, void(entity))
	METHOD(Item, focusLeave, void(entity))
	METHOD(Item, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(Item, relinquishFocus, void(entity))
	METHOD(Item, showNotify, void(entity))
	METHOD(Item, hideNotify, void(entity))
	METHOD(Item, toString, string(entity))
	METHOD(Item, destroy, void(entity))
	ATTRIB(Item, focused, float, 0)
	ATTRIB(Item, focusable, float, 0)
	ATTRIB(Item, parent, entity, NULL)
	ATTRIB(Item, preferredFocusPriority, float, 0)
	ATTRIB(Item, origin, vector, '0 0 0')
	ATTRIB(Item, size, vector, '0 0 0')
	ATTRIB(Item, tooltip, string, string_null)
ENDCLASS(Item)
#endif

#ifdef IMPLEMENTATION
void Item_destroy(entity me)
{
	// free memory associated with me
}

void Item_relinquishFocus(entity me)
{
	if(me.parent)
		if(me.parent.instanceOfContainer)
			me.parent.setFocus(me.parent, NULL);
}

void Item_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.origin = absOrigin;
	me.size = absSize;
	// me.tooltip = "The quick brown fox jumped over the lazy sleeping dog's back then sat on a tack. Franz jagt im komplett verwahrlosten Taxi quer durch Bayern.";
}

void Item_draw(entity me)
{
}

void Item_showNotify(entity me)
{
}

void Item_hideNotify(entity me)
{
}

float Item_keyDown(entity me, float scan, float ascii, float shift)
{
	return 0; // unhandled
}

float Item_keyUp(entity me, float scan, float ascii, float shift)
{
	return 0; // unhandled
}

float Item_mouseMove(entity me, vector pos)
{
	return 0; // unhandled
}

float Item_mousePress(entity me, vector pos)
{
	return 0; // unhandled
}

float Item_mouseDrag(entity me, vector pos)
{
	return 0; // unhandled
}

float Item_mouseRelease(entity me, vector pos)
{
	return 0; // unhandled
}

void Item_focusEnter(entity me)
{
}

void Item_focusLeave(entity me)
{
}

string Item_toString(entity me)
{
	return string_null;
}
#endif
