#include "inputbox.qh"

.float cb_offset;
.string cb_src;

	void InputBox_configureInputBox(entity me, string theText, float theCursorPos, float theFontSize, string gfx)
	{
		SUPER(InputBox).configureLabel(me, theText, theFontSize, 0.0);
		me.src = gfx;
		me.cursorPos = theCursorPos;
	}
	void InputBox_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		SUPER(InputBox).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
		if (me.enableClearButton)
		{
			me.cb_width = absSize.y / absSize.x;
			me.cb_offset = bound(-1, me.cb_offset, 0) * me.cb_width;  // bound to range -1, 0
			me.keepspaceRight = me.keepspaceRight - me.cb_offset + me.cb_width;
		}
	}

	void InputBox_setText(entity me, string txt)
	{
		strfree(me.text);
		SUPER(InputBox).setText(me, strzone(txt));
	}

	float over_ClearButton(entity me, vector pos)
	{
		if (me.text == "")
			return 0;
		if (pos.x >= 1 + me.cb_offset - me.cb_width)
			if (pos.x < 1 + me.cb_offset)
				if (pos.y >= 0)
					if (pos.y < 1) return 1;
		return 0;
	}

	float InputBox_mouseMove(entity me, vector pos)
	{
		if (me.enableClearButton)
		{
			if (over_ClearButton(me, pos))
			{
				me.cb_focused = true;
				return 1;
			}
			me.cb_focused = false;
		}
		return 1;
	}

	float InputBox_mouseDrag(entity me, vector pos)
	{
		float p;
		if (me.pressed)
		{
			me.dragScrollPos = pos;
			p = me.scrollPos + pos.x - me.keepspaceLeft;
			me.cursorPos = draw_TextLengthUpToWidth(me.text, p, 0, me.realFontSize);
			me.lastChangeTime = time;
		}
		else if (me.enableClearButton)
		{
			if (over_ClearButton(me, pos))
			{
				me.cb_pressed = true;
				return 1;
			}
		}
		me.cb_pressed = false;
		return 1;
	}

	METHOD(InputBox, mousePress, bool(InputBox this, vector pos))
	{
		if (this.enableClearButton)
			if (over_ClearButton(this, pos))
			{
				this.cb_pressed = true;
				return true;
			}
		this.dragScrollTimer = time;
		this.pressed = 1;
		return InputBox_mouseDrag(this, pos);
	}

	float InputBox_mouseRelease(entity me, vector pos)
	{
		if (me.cb_pressed)
			if (over_ClearButton(me, pos))
			{
				m_play_click_sound(MENU_SOUND_CLEAR);
				me.setText(me, "");
				if(me.applyButton)
					me.applyButton.disabled = false;
				me.cb_pressed = false;
				return 1;
			}
		float r = InputBox_mouseDrag(me, pos);
		// reset cb_pressed after mouseDrag, mouseDrag could set cb_pressed in this case:
		// mouse press out of the clear button, drag and then mouse release over the clear button
		me.cb_pressed = false;
		me.pressed = 0;
		return r;
	}

	void InputBox_enterText(entity me, string ch)
	{
		int len = strlen(ch);
		for (int i = 0; i < len; ++i)
		{
			// if there is a list of allowed characters, forbid all other
			if (me.allowedCharacters != string_null
			&&  strstrofs(me.allowedCharacters, substring(ch, i, 1), 0) == -1) return;

			// don't allow forbidden characters
			if (strstrofs(me.forbiddenCharacters, substring(ch, i, 1), 0) > -1) return;
		}
		if (me.maxLength > 0)
		{
			if (len + strlen(me.text) > me.maxLength) return;
		}
		else if (me.maxLength < 0)
		{
			if (u8_strsize(ch) + u8_strsize(me.text) > -me.maxLength) return;
		}
		me.setText(me, strcat(substring(me.text, 0, me.cursorPos), ch, substring(me.text, me.cursorPos, strlen(me.text) - me.cursorPos)));
		me.cursorPos += len;
	}

	float InputBox_keyDown(entity me, float key, float ascii, float shift)
	{
		me.lastChangeTime = time;
		me.dragScrollTimer = time;
		if (ascii >= 32 && ascii != 127)
		{
			me.enterText(me, chr(ascii));
			if(me.applyButton)
				me.applyButton.disabled = false;
			return 1;
		}
		switch (key)
		{
			case K_KP_LEFTARROW:
			case K_LEFTARROW:
				--me.cursorPos;
				return 1;
			case K_KP_RIGHTARROW:
			case K_RIGHTARROW:
				++me.cursorPos;
				return 1;
			case K_KP_HOME:
			case K_HOME:
				me.cursorPos = 0;
				return 1;
			case K_KP_END:
			case K_END:
				me.cursorPos = strlen(me.text);
				return 1;
			case K_BACKSPACE:
				if (me.cursorPos > 0)
				{
					--me.cursorPos;
					me.setText(me, strcat(substring(me.text, 0, me.cursorPos), substring(me.text, me.cursorPos + 1, strlen(me.text) - me.cursorPos - 1)));
					if(me.applyButton)
						me.applyButton.disabled = false;
				}
				return 1;
			case K_KP_DEL:
			case K_DEL:
				if (shift & S_CTRL)
				{
					m_play_click_sound(MENU_SOUND_CLEAR);
					me.setText(me, "");
				}
				else
					me.setText(me, strcat(substring(me.text, 0, me.cursorPos), substring(me.text, me.cursorPos + 1, strlen(me.text) - me.cursorPos - 1)));
				if(me.applyButton)
					me.applyButton.disabled = false;
				return 1;
		}
		return 0;
	}

	void InputBox_draw(entity me)
	{
		string CURSOR = "_";
		float cursorPosInWidths, totalSizeInWidths;

		if (me.pressed) me.mouseDrag(me, me.dragScrollPos);  // simulate mouseDrag event

		if (me.recalcPos) me.recalcPositionWithText(me, me.text);

		me.focusable = !me.disabled;
		if (me.disabled) draw_alpha *= me.disabledAlpha;

		if (me.src)
		{
			if (me.focused && !me.disabled) draw_ButtonPicture('0 0 0', strcat(me.src, "_f"), '1 1 0', me.colorF, 1);
			else draw_ButtonPicture('0 0 0', strcat(me.src, "_n"), '1 1 0', me.color, 1);
		}

		me.cursorPos = bound(0, me.cursorPos, strlen(me.text));
		cursorPosInWidths = draw_TextWidth(substring(me.text, 0, me.cursorPos), 0, me.realFontSize);
		totalSizeInWidths = draw_TextWidth(strcat(me.text, CURSOR), 0, me.realFontSize);

		if (me.dragScrollTimer < time)
		{
			float save;
			save = me.scrollPos;
			me.scrollPos = bound(cursorPosInWidths - (0.875 - me.keepspaceLeft - me.keepspaceRight), me.scrollPos, cursorPosInWidths - 0.125);
			if (me.scrollPos != save) me.dragScrollTimer = time + 0.2;
		}
		me.scrollPos = min(me.scrollPos, totalSizeInWidths - (1 - me.keepspaceRight - me.keepspaceLeft));
		me.scrollPos = max(0, me.scrollPos);

		draw_SetClipRect(eX * me.keepspaceLeft, eX * (1 - me.keepspaceLeft - me.keepspaceRight) + eY);
		if (me.editColorCodes)
		{
			vector p = me.realOrigin - eX * me.scrollPos;
			vector theColor = '1 1 1';
			float theAlpha = 1;

			for (int i = 0, n = strlen(me.text); i < n; ++i)
			{
				string ch = substring(me.text, i, 1);
				if (ch == "^")
				{
					float w;
					string ch2 = substring(me.text, i + 1, 1);
					w = draw_TextWidth(strcat(ch, ch2), 0, me.realFontSize);
					float fill_alpha = 0.4;
					if (ch2 == "^")
					{
						if (me.cursorPos > i && me.cursorPos <= i + 2)
							fill_alpha = 0.6;
						draw_Fill(p, eX * w + eY * me.realFontSize.y, '1 1 1', fill_alpha);
						draw_Text(p + eX * 0.25 * w, "^", me.realFontSize, theColor, theAlpha, 0);
					}
					else if (IS_DIGIT(ch2))
					{
						theAlpha = 1;
						switch (stof(ch2))
						{
							case 0: theColor = '0 0 0'; break;
							case 1: theColor = '1 0 0'; break;
							case 2: theColor = '0 1 0'; break;
							case 3: theColor = '1 1 0'; break;
							case 4: theColor = '0 0 1'; break;
							case 5: theColor = '0 1 1'; break;
							case 6: theColor = '1 0 1'; break;
							case 7: theColor = '1 1 1'; break;
							case 8: theColor = '1 1 1'; theAlpha = 0.5; break;
							case 9: theColor = '0.5 0.5 0.5'; break;
						}
						if (me.cursorPos > i && me.cursorPos <= i + 2)
							fill_alpha = 0.6;
						draw_Fill(p, eX * w + eY * me.realFontSize.y, '1 1 1', fill_alpha);
						draw_Text(p, strcat(ch, ch2), me.realFontSize, theColor, theAlpha, 0);
					}
					else if (ch2 == "x")  // ^x found
					{
						vector theTempColor;
						theColor = '1 1 1';
						float component = HEXDIGIT_TO_DEC(substring(me.text, i + 2, 1));
						if (component >= 0)  // ^xr found
						{
							theTempColor.x = component / 15;

							component = HEXDIGIT_TO_DEC(substring(me.text, i + 3, 1));
							if (component >= 0)  // ^xrg found
							{
								theTempColor.y = component / 15;

								component = HEXDIGIT_TO_DEC(substring(me.text, i + 4, 1));
								if (component >= 0)  // ^xrgb found
								{
									theTempColor.z = component / 15;
									theColor = theTempColor;
									w = draw_TextWidth(substring(me.text, i, 5), 0, me.realFontSize);

									if (me.cursorPos > i && me.cursorPos <= i + 5)
										fill_alpha = 0.8;
									draw_Fill(p, eX * w + eY * me.realFontSize.y, '1 1 1', fill_alpha);
									draw_Text(p, substring(me.text, i, 5), me.realFontSize, theColor, 1, 0);
									i += 3;
								}
								else
								{
									// blue missing
									w = draw_TextWidth(substring(me.text, i, 4), 0, me.realFontSize);
									draw_Fill(p, eX * w + eY * me.realFontSize.y, eZ, fill_alpha);
									draw_Text(p, substring(me.text, i, 4), me.realFontSize, '1 1 1', theAlpha, 0);
									i += 2;
								}
							}
							else
							{
								// green missing
								w = draw_TextWidth(substring(me.text, i, 3), 0, me.realFontSize);
								draw_Fill(p, eX * w + eY * me.realFontSize.y, eY, fill_alpha);
								draw_Text(p, substring(me.text, i, 3), me.realFontSize, '1 1 1', theAlpha, 0);
								++i;
							}
						}
						else
						{
							// red missing
							// w = draw_TextWidth(substring(me.text, i, 2), 0) * me.realFontSize_x;
							draw_Fill(p, eX * w + eY * me.realFontSize.y, eX, fill_alpha);
							draw_Text(p, substring(me.text, i, 2), me.realFontSize, '1 1 1', theAlpha, 0);
						}
					}
					else
					{
						draw_Fill(p, eX * w + eY * me.realFontSize.y, '1 1 1', fill_alpha);
						draw_Text(p, strcat(ch, ch2), me.realFontSize, theColor, theAlpha, 0);
					}
					p += w * eX;
					++i;
					continue;
				}
				draw_Text(p, ch, me.realFontSize, theColor, theAlpha, 0);
				p += eX * draw_TextWidth(ch, 0, me.realFontSize);
			}
		}
		else
		{
			draw_Text(me.realOrigin - eX * me.scrollPos, me.text, me.realFontSize, '1 1 1', 1, 0);
		}

		if (!me.focused || (time - me.lastChangeTime) < floor(time - me.lastChangeTime) + 0.5)
			draw_Text(me.realOrigin + eX * (cursorPosInWidths - me.scrollPos), CURSOR, me.realFontSize, '1 1 1', 1, 0);

		draw_ClearClip();

		if (me.enableClearButton && me.text != "")
		{
			if (me.focused && me.cb_pressed)
				draw_Picture(eX * (1 + me.cb_offset - me.cb_width), strcat(me.cb_src, "_c"), eX * me.cb_width + eY, me.cb_colorC, 1);
			else if (me.focused && me.cb_focused)
				draw_Picture(eX * (1 + me.cb_offset - me.cb_width), strcat(me.cb_src, "_f"), eX * me.cb_width + eY, me.cb_colorF, 1);
			else
				draw_Picture(eX * (1 + me.cb_offset - me.cb_width), strcat(me.cb_src, "_n"), eX * me.cb_width + eY, me.cb_color, 1);
		}

		// skipping SUPER(InputBox).draw(me);
		MenuItem_draw(me);
	}

	void InputBox_showNotify(entity me)
	{
		me.focusable = !me.disabled;
	}
