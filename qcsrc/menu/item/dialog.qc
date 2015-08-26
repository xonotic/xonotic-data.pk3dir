// Note: this class is called Dialog, but it can also handle a tab under the following conditions:
// - isTabRoot is 0
// - backgroundImage is the tab's background
// - closable is 0
// - rootDialog is 0
// - title is ""
// - marginTop is
// - intendedHeight ends up to be the tab's actual height, or at least close
// - titleFontSize is 0
// - marginTop cancels out as much of titleHeight as needed (that is, it should be actualMarginTop - titleHeight)
// To ensure the latter, you best create all tabs FIRST and insert the tabbed
// control to your dialog THEN - with the right height
//
// a subclass may help with using this as a tab

#ifndef ITEM_DIALOG_H
#define ITEM_DIALOG_H
#include "inputcontainer.qc"
CLASS(Dialog, InputContainer)
	METHOD(Dialog, configureDialog, void(entity)); // no runtime configuration, all parameters are given in the code!
	METHOD(Dialog, fill, void(entity)); // to be overridden by user to fill the dialog with controls
	METHOD(Dialog, keyDown, float(entity, float, float, float));
	METHOD(Dialog, close, void(entity));
	METHOD(Dialog, addItemSimple, void(entity, float, float, float, float, entity, vector));

	METHOD(Dialog, TD, void(entity, float, float, entity));
	METHOD(Dialog, TDNoMargin, void(entity, float, float, entity, vector));
	METHOD(Dialog, TDempty, void(entity, float));
	METHOD(Dialog, setFirstColumn, void(entity, float));
	METHOD(Dialog, TR, void(entity));
	METHOD(Dialog, gotoRC, void(entity, float, float));

	ATTRIB(Dialog, isTabRoot, float, 1)
	ATTRIB(Dialog, closeButton, entity, NULL)
	ATTRIB(Dialog, intendedHeight, float, 0)
	ATTRIB(Dialog, itemOrigin, vector, '0 0 0')
	ATTRIB(Dialog, itemSize, vector, '0 0 0')
	ATTRIB(Dialog, itemSpacing, vector, '0 0 0')
	ATTRIB(Dialog, currentRow, float, 0)
	ATTRIB(Dialog, currentColumn, float, 0)
	ATTRIB(Dialog, firstColumn, float, 0)

	// to be customized
	ATTRIB(Dialog, closable, float, 1)
	ATTRIB(Dialog, title, string, "Form1") // ;)
	ATTRIB(Dialog, color, vector, '1 0.5 1')
	ATTRIB(Dialog, intendedWidth, float, 0)
	ATTRIB(Dialog, rows, float, 3)
	ATTRIB(Dialog, columns, float, 2)

	ATTRIB(Dialog, marginTop, float, 0) // pixels
	ATTRIB(Dialog, marginBottom, float, 0) // pixels
	ATTRIB(Dialog, marginLeft, float, 0) // pixels
	ATTRIB(Dialog, marginRight, float, 0) // pixels
	ATTRIB(Dialog, columnSpacing, float, 0) // pixels
	ATTRIB(Dialog, rowSpacing, float, 0) // pixels
	ATTRIB(Dialog, rowHeight, float, 0) // pixels
	ATTRIB(Dialog, titleHeight, float, 0) // pixels
	ATTRIB(Dialog, titleFontSize, float, 0) // pixels; if 0, title causes no margin
	ATTRIB(Dialog, zoomedOutTitleBarPosition, float, 0)
	ATTRIB(Dialog, zoomedOutTitleBar, float, 0)

	ATTRIB(Dialog, requiresConnection, float, 0) // set to true if the dialog requires a connection to be opened

	ATTRIB(Dialog, backgroundImage, string, string_null)
	ATTRIB(Dialog, borderLines, float, 1)
	ATTRIB(Dialog, closeButtonImage, string, string_null)

	ATTRIB(Dialog, frame, entity, NULL)
ENDCLASS(Dialog)
#endif

#ifdef IMPLEMENTATION
void Dialog_Close(entity button, entity me)
{
	me.close(me);
}

void Dialog_fill(entity me)
{
}

void Dialog_addItemSimple(entity me, float row, float col, float rowspan, float colspan, entity e, vector v)
{
	vector o, s;
	o = me.itemOrigin + eX * ( col          * me.itemSpacing.x) + eY * ( row          * me.itemSpacing.y);
	s = me.itemSize   + eX * ((colspan - 1) * me.itemSpacing.x) + eY * ((rowspan - 1) * me.itemSpacing.y);
	o.x -= 0.5 * (me.itemSpacing.x - me.itemSize.x) * v.x;
	s.x +=       (me.itemSpacing.x - me.itemSize.x) * v.x;
	o.y -= 0.5 * (me.itemSpacing.y - me.itemSize.y) * v.y;
	s.y +=       (me.itemSpacing.y - me.itemSize.y) * v.y;
	me.addItem(me, e, o, s, 1);
}

void Dialog_gotoRC(entity me, float row, float col)
{
	me.currentRow = row;
	me.currentColumn = col;
}

void Dialog_TR(entity me)
{
	me.currentRow += 1;
	me.currentColumn = me.firstColumn;
}

void Dialog_TD(entity me, float rowspan, float colspan, entity e)
{
	me.addItemSimple(me, me.currentRow, me.currentColumn, rowspan, colspan, e, '0 0 0');
	me.currentColumn += colspan;
}

void Dialog_TDNoMargin(entity me, float rowspan, float colspan, entity e, vector v)
{
	me.addItemSimple(me, me.currentRow, me.currentColumn, rowspan, colspan, e, v);
	me.currentColumn += colspan;
}

void Dialog_setFirstColumn(entity me, float col)
{
	me.firstColumn = col;
}

void Dialog_TDempty(entity me, float colspan)
{
	me.currentColumn += colspan;
}

void Dialog_configureDialog(entity me)
{
	float absWidth, absHeight;

	if(me.isTabRoot)
	{
		me.frame = NEW(BorderImage);
		me.frame.configureBorderImage(me.frame, me.title, me.titleFontSize, me.color, me.backgroundImage, me.borderLines * me.titleHeight);
		me.frame.zoomedOutTitleBarPosition = me.zoomedOutTitleBarPosition;
		me.frame.zoomedOutTitleBar = me.zoomedOutTitleBar;
		me.frame.alpha = me.alpha;
		me.addItem(me, me.frame, '0 0 0', '1 1 0', 1);
	}

	if (!me.titleFontSize)
		me.titleHeight = 0; // no title bar

	absWidth = me.intendedWidth * conwidth;
	absHeight = me.borderLines * me.titleHeight + me.marginTop + me.rows * me.rowHeight + (me.rows - 1) * me.rowSpacing + me.marginBottom;
	me.itemOrigin  = eX * (me.marginLeft / absWidth)
	               + eY * ((me.borderLines * me.titleHeight + me.marginTop) / absHeight);
	me.itemSize    = eX * ((1 - (me.marginLeft + me.marginRight + me.columnSpacing * (me.columns - 1)) / absWidth) / me.columns)
	               + eY * (me.rowHeight / absHeight);
	me.itemSpacing = me.itemSize
	               + eX * (me.columnSpacing / absWidth)
	               + eY * (me.rowSpacing / absHeight);
	me.intendedHeight = absHeight / conheight;
	me.currentRow = -1;
	me.currentColumn = -1;

	me.fill(me);

	if(me.isTabRoot && me.closable && me.borderLines > 0)
	{
		entity closebutton;
		closebutton = me.closeButton = me.frame.closeButton = NEW(Button);
		closebutton.configureButton(closebutton, "", 0, me.closeButtonImage);
		closebutton.onClick = Dialog_Close; closebutton.onClickEntity = me;
		closebutton.srcMulti = 0;
		me.addItem(me, closebutton, '0 0 0', '1 1 0', 1); // put it as LAST
	}
}

void Dialog_close(entity me)
{
	if(me.parent.instanceOfNexposee)
	{
		ExposeeCloseButton_Click(me, me.parent);
	}
	else if(me.parent.instanceOfModalController)
	{
		DialogCloseButton_Click(me, me);
	}
}

float Dialog_keyDown(entity me, float key, float ascii, float shift)
{
	if(me.closable)
	{
		if(key == K_ESCAPE)
		{
			m_play_click_sound(MENU_SOUND_CLOSE);
			me.close(me);
			return 1;
		}
	}
	return SUPER(Dialog).keyDown(me, key, ascii, shift);
}
#endif
