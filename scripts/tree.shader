morph/leaves3
{
cull none
	qer_editorimage leaves6.tga
	qer_trans 0.6
	surfaceparm trans
//	surfaceparm nolightmap
	surfaceparm alphashadow
	deformVertexes autosprite
	q3map_vertexScale 1
	deformVertexes wave 128 sin 0 1 0 0.4 
	{
		map leaves6.tga
		alphaFunc GT0
		rgbGen vertex
	}
}

grass02
{
	distancecull 256 1024 0.4
	cull none
	qer_editorimage grass2.tga
	qer_trans 0.2
	surfaceparm nolightmap
	surfaceparm trans
	q3map_vertexScale 1
	deformVertexes autosprite
	deformVertexes wave 128 sin 0 1 0 0.1 
	{
		map grass2.tga
		alphaFunc GT0
		rgbGen vertex
	}
}

leaves4
{
cull none
	qer_editorimage leaves7.tga
	qer_trans 0.6
	deformVertexes autosprite
	surfaceparm nolightmap
	surfaceparm trans
	q3map_vertexScale 1
	deformVertexes wave 128 sin 0 1 0 0.5
	{
		map leaves7.tga
		alphaFunc GT0
		rgbGen vertex
	}
}

e8teamcolor
	{
	qer_editorimage morphed/e8support02c_shirt.jpg
	map morphed/e8support02c.tga
		{
		map $lightmap
		rgbGen identity
		}
	}
