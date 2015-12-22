#ifndef DIALOG_VCALL_H
#define DIALOG_VCALL_H
#include "rootdialog.qc"
CLASS(XonoticVcallDialog, XonoticRootDialog)
	ATTRIB(XonoticVcallDialog, title, string, _("Call a vote"))
	ATTRIB(XonoticVcallDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticVcallDialog, intendedWidth, float, 1)
	ATTRIB(XonoticVcallDialog, rows, float, 16)
	ATTRIB(XonoticVcallDialog, columns, float, 20)
	ATTRIB(XonoticVcallDialog, name, string, "Vcall")

	ATTRIB(XonoticVcallDialog, voteList, entity, NULL)
	ATTRIB(XonoticVcallDialog, optionList, entity, NULL)
	ATTRIB(XonoticVcallDialog, inputBox, entity, NULL)

	METHOD(XonoticVcallDialog, fill, void(XonoticVcallDialog this));
	METHOD(XonoticVcallDialog, setFocus, void(XonoticVcallDialog this, entity a));
ENDCLASS(XonoticVcallDialog)
#endif

#ifdef IMPLEMENTATION
METHOD(XonoticVcallDialog, setFocus, void(XonoticVcallDialog this, entity a))
{
	SUPER(XonoticVcallDialog).setFocus(this, a);
	entity vlist = this.voteList;
	vlist.refilter(vlist);
}

STATIC_METHOD(XonoticVcallDialog, Send, void(entity, XonoticVcallDialog this))
{
	localcmd("vcall ", this.inputBox.text, "\n");
	this.close(this);
}

STATIC_METHOD(XonoticVcallDialog, Change, void(entity, XonoticVcallDialog this))
{
	entity vlist = this.voteList;
	entity options = this.optionList;
	vlist.source.getEntry(vlist.source, vlist.selectedItem, XonoticVoteList_cb);
	string vote = XonoticVoteList_cb_name;
	options.source.getEntry(options.source, options.selectedItem, XonoticVoteList_cb);
	string option = XonoticVoteList_cb_name;
	string s = (option != "") ? strcat(vote, " ", option) : vote;
	entity t = this.inputBox;
	t.setText(t, s);
	t.cursorPos = strlen(s);
}

STATIC_METHOD(XonoticVcallDialog, ChangeVote, void(entity, XonoticVcallDialog this))
{
	entity vlist = this.voteList;
	entity entries = this.optionList;
	int i = vlist.selectedItem;
	vlist.source.getEntry(vlist.source, i, XonoticVoteList_cb);
	if (entries.source.CvarStringSource_cvar) strunzone(entries.source.CvarStringSource_cvar);
	entries.source.CvarStringSource_cvar = strzone(strcat("__vcall_", XonoticVoteList_cb_name));
	entries.refilter(entries);
	entries.setSelected(entries, 0);
	XonoticVcallDialog_Change(NULL, this);
}

METHOD(XonoticVcallDialog, fill, void(XonoticVcallDialog this))
{
	entity vlist, olist;
	this.TR(this);
	{
		this.TD(this, 1, 10, makeXonoticTextLabel(0, _("Available votes:")));
		this.TD(this, 1, 10, makeXonoticTextLabel(0, _("Available options:")));
	}
	this.TR(this);
	{
		DataSource votes = NEW(CvarStringSource, "__vcall", " ");
		this.TD(this, 13, 10, vlist = this.voteList = NEW(XonoticVoteList, votes));
		{
			vlist.onChange = XonoticVcallDialog_ChangeVote;
			vlist.onChangeEntity = this;
		}
		DataSource options = NEW(CvarStringSource, string_null, " ");
		this.TD(this, 13, 10, olist = this.optionList = NEW(XonoticVoteList, options));
		{
			olist.onChange = XonoticVcallDialog_Change;
			olist.onChangeEntity = this;
		}
		this.gotoRC(this, this.rows - 2, 0);
		this.TD(this, 1, 20, this.inputBox = makeXonoticInputBox(1, string_null));
	}
	this.TR(this);
	{
		entity e;
		this.TD(this, 1, 10, e = makeXonoticButton(_("Call the vote"), '0 0 0'));
		{
			e.onClick = XonoticVcallDialog_Send;
			e.onClickEntity = this;
		}
		this.TD(this, 1, 10, e = makeXonoticCommandButton(_("Cancel"), '0 0 0', "", 1));
		{
			e.onClick = Dialog_Close;
			e.onClickEntity = this;
		}
	}
}
#endif
