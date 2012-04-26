void error(...) = #1;

void Oassignments(float foo) // pass 1
{
	float bar;
	bar = 2;
	bar = (foo ? 0 : (foo & 1));
	if(bar == 2)
		error("FTEQCC SUCKS");
}

void Oreturn_only(float foo) // pass 0
{
	if(foo)
	{
		return;
	}
}

void Oreturn_only_trap(void)
{
	error("FTEQCC SUCKS");
}
