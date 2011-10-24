MUTATOR_HOOKFUNCTION(sandbox_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return 0;
	if(cmd_name == "g_sandbox")
	{
		if(cmd_argc < 2)
		{
			print_to(self, "Sandbox mode is active. For more information, use 'g_sandbox help'");
			return 1;
		}

		if(argv(1) == "help")
		{
			print_to(self, "You can use the following sandbox commands:");
			return 1;
		}
	}
	return 0;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);

	return 0;
}
