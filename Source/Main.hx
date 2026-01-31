package;

import RSDK.Core.RetroEngine;

class Main extends Application
{
	public function new()
	{
		super();
		Engine.Init();
		Engine.Run();
	}
}