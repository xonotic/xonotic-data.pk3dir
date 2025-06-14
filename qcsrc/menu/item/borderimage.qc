#include "borderimage.qh"

#include "nexposee.qh"
#include "dialog.qh"
	void BorderImage_recalcPositionWithText(entity me, string t)
	{
		if (me.isNexposeeTitleBar)
		{
			vector scrs;
			scrs = eX * conwidth + eY * conheight;
			me.resizeNotify(me, me.saveRelOrigin, me.saveRelSize, boxToGlobal(me.parent.Nexposee_smallOrigin, '0 0 0', scrs), boxToGlobalSize(me.parent.Nexposee_smallSize, scrs));
			SUPER(BorderImage).recalcPositionWithText(me, t);
			me.realOrigin_y = me.realFontSize.y * me.zoomedOutTitleBarPosition;
			me.realOrigin_Nexposeed = me.realOrigin;
			me.realFontSize_Nexposeed = me.realFontSize;
			me.resizeNotify(me, me.saveRelOrigin, me.saveRelSize, boxToGlobal(me.parent.Nexposee_initialOrigin, '0 0 0', scrs), boxToGlobalSize(me.parent.Nexposee_initialSize, scrs));
		}
		SUPER(BorderImage).recalcPositionWithText(me, t);
	}
	void BorderImage_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		me.isNexposeeTitleBar = false;
		if (me.zoomedOutTitleBar)
			if (me.parent.parent.instanceOfNexposee)
				if (me.parent.instanceOfDialog)
					if (me == me.parent.frame) me.isNexposeeTitleBar = true;
		me.saveRelOrigin = relOrigin;
		me.saveRelSize = relSize;
		SUPER(BorderImage).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
		me.borderVec_x = me.borderHeight / absSize.x;
		me.borderVec_y = me.borderHeight / absSize.y;
		me.realOrigin_y = 0.5 * (me.borderVec.y - me.realFontSize.y);
		if (me.closeButton)
		{
			// move the close button to the right place
			me.closeButton.Container_origin = '1 0 0' * (1 - me.borderVec.x);
			me.closeButton.Container_size = me.borderVec;
			me.closeButton.color = me.color;
			me.closeButton.colorC = me.color;
			me.closeButton.colorF = me.color;
		}
	}
	void BorderImage_configureBorderImage(entity me, string theTitle, float sz, vector theColor, string path, float theBorderHeight)
	{
		me.configureLabel(me, theTitle, sz, 0.5);
		me.src = path;
		me.color = theColor;
		me.borderHeight = theBorderHeight;
	}
	void BorderImage_draw(entity me)
	{
		if (me.src) draw_BorderPicture('0 0 0', me.src, '1 1 0', me.color, 1, me.borderVec);

		if (me.fontSize > 0)
		{
			if (me.recalcPos) me.recalcPositionWithText(me, me.text);

			if (me.isNexposeeTitleBar)
			{
				vector ro, rf, df;

				// me.parent.Nexposee_animationFactor 0 (small) or 1 (full)
				// default values are for 1
				ro = me.realOrigin;
				rf = me.realFontSize;
				df = draw_fontscale;
				me.realOrigin = ro * me.parent.Nexposee_animationFactor + me.realOrigin_Nexposeed * (1 - me.parent.Nexposee_animationFactor);
				me.realFontSize = rf * me.parent.Nexposee_animationFactor + me.realFontSize_Nexposeed * (1 - me.parent.Nexposee_animationFactor);
				draw_fontscale = globalToBoxSize(boxToGlobalSize(df, me.realFontSize), rf);

				SUPER(BorderImage).draw(me);

				// me.Nexposee_animationState 0 (small) or 1 (full)
				// default values are for 1
				me.realOrigin = ro;
				me.realFontSize = rf;
				draw_fontscale = df;
			}
			else
			{
				SUPER(BorderImage).draw(me);
			}
		}
		else
		{
			SUPER(BorderImage).draw(me);
		}
	}
