RL
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/rl_new.tga
		rgbgen lightingDiffuse
	}
}
RocketThrust
{
	cull none
	{
	animMap 50 textures/rl_trust01.tga textures/rl_trust02.tga textures/rl_trust03.tga textures/rl_trust04.tga
	blendFunc GL_ONE GL_ONE
	rgbGen wave sawtooth 0 1 0 10
	}

}
