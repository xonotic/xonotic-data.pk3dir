#include "dialog.qh"

#include "borderimage.qh"
#include "button.qh"
#include "nexposee.qh"

	void Dialog_Close(entity button, entity me)
	{
		me.close(me);
	}

	void Dialog_fill(entity me)
	{}

	void Dialog_addItemSimple(entity me, float row, float col, float rowspan, float colspan, entity e, vector v)
	{
		vector o, s;
		o = me.itemOrigin + eX * (col          * me.itemSpacing.x) + eY * (row          * me.itemSpacing.y);
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
		++me.currentRow;
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

		if (me.isTabRoot)
		{
			me.frame = NEW(BorderImage);
			me.frame.configureBorderImage(me.frame, me.title, me.titleFontSize, me.color, me.backgroundImage, me.borderLines * me.titleHeight);
			me.frame.zoomedOutTitleBarPosition = me.zoomedOutTitleBarPosition;
			me.frame.zoomedOutTitleBar = me.zoomedOutTitleBar;
			me.frame.alpha = me.alpha;
			me.addItem(me, me.frame, '0 0 0', '1 1 0', 1);
		}

		if (!me.titleFontSize) me.titleHeight = 0;  // no title bar

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

		if (me.isTabRoot && me.closable && me.borderLines > 0)
		{
			entity closebutton;
			closebutton = me.closeButton = me.frame.closeButton = NEW(Button);
			closebutton.configureButton(closebutton, "", 0, me.closeButtonImage);
			closebutton.onClick = Dialog_Close;
			closebutton.onClickEntity = me;
			closebutton.srcMulti = 0;
			me.addItem(me, closebutton, '0 0 0', '1 1 0', 1);  // put it as LAST
		}
	}

	void Dialog_close(entity me)
	{
		bool closed = false;
		if (me.parent.instanceOfNexposee)
		{
			ExposeeCloseButton_Click(me, me.parent);
			closed = true;
		}
		else if (me.parent.instanceOfModalController)
		{
			DialogCloseButton_Click(me, me);
			closed = true;
		}

		if (closed && me.hideMenuOnClose)
			m_goto(string_null, false);
		me.hideMenuOnClose = false; // reset it regardless
	}

	float Dialog_keyDown(entity me, float key, float ascii, float shift)
	{
		if (me.closable)
		{
			if (key == K_ESCAPE)
			{
				m_play_click_sound(MENU_SOUND_CLOSE);
				me.close(me);
				return 1;
			}
		}
		float r = SUPER(Dialog).keyDown(me, key, ascii, shift);
		if (!me.closable && key == K_ESCAPE)
			return 1;
		return r;
	}
