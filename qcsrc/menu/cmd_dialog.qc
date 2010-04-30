void showCommandLineDialog(float arg_min, float arg_count)
{
	string t;
	string prefix;
	float flags;
	t = argv(arg_min);
	prefix = argv(arg_min+1);
	flags = stof(argv(arg_min+2));
	if(!(flags & 1))
	{
		if(cmd_dialog_active)
			return;
	}
	cmd_dialog_prefix = prefix;
	cmd_dialog_flags = flags;
	if(t == "MessageBox")
	{
		if(cmd_dialog_title) strunzone(cmd_dialog_title); cmd_dialog_title = strzone(argv(arg_min+3));
		if(cmd_dialog_message) strunzone(cmd_dialog_message); cmd_dialog_message = strzone(argv(arg_min+4));
		if(cmd_dialog_button1) strunzone(cmd_dialog_button1); cmd_dialog_button1 = strzone(argv(arg_min+5));
		if(cmd_dialog_button2) strunzone(cmd_dialog_button2); cmd_dialog_button2 = strzone(argv(arg_min+6));
		if(cmd_dialog_button3) strunzone(cmd_dialog_button3); cmd_dialog_button3 = strzone(argv(arg_min+7));
		cmd_dialog_active = 1;
		cmd_dialog_messagebox.update(cmd_dialog_messagebox);
		m_goto("cmd_dialog_messagebox");
	}
}
