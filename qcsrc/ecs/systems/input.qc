#include "input.qh"

void sys_in_update(entity this, float dt)
{
	this.com_in_jump = PHYS_INPUT_BUTTON_JUMP(this);
	this.com_in_crouch = PHYS_INPUT_BUTTON_CROUCH(this);
}
