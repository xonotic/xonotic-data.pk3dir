#include "test.qh"

int TEST_RunAll_accumulated(int init);
bool RUN_ALL_TESTS()
{
	int f = TEST_RunAll_accumulated(0);
	if (f)
	{
		LOG_HELPF("%d tests failed", f);
		return true;
	}
	else
	{
		LOG_HELP("All tests OK");
		return false;
	}
}

bool TEST_Run(string s)
{
	LOG_HELPF("%s: testing...", s);
	TEST_failed = 0;
	TEST_fatal = 0;
	TEST_ok = false;
	string fn = strcat("_TEST_", s);
	if (isfunction(fn)) callfunction(fn);
	if (TEST_failed > 0)
	{
		LOG_HELPF("%s: %d items failed.", s, TEST_failed);
		return false;
	}
	else if (!TEST_ok)
	{
		LOG_HELPF("%s: did not complete.", s);
		return false;
	}
	return true;
}
