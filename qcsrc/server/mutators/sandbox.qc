MUTATOR_HOOKFUNCTION(sandbox_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return 0;
	if(cmd_name == "g_sandbox" && cmd_argc >= 2)
	{
		print(strcat("Sandbox command received. Player sending the command is ", self.netname, "\n"));
		return 1;
	}
	return 0;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);

	return 0;
}
