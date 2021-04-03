methodmap HudScore < StringMap {
	public HudScore(int clientId) {
		StringMap map = new StringMap();
		
		map.SetValue("clientId", clientId);
		
		return view_as<HudScore>(map);
	}
	
	property int clientId {
		public get() {
			int value;
		
			this.GetValue("clientId", value);

			return value;
		}
	}
	
	property Handle TimerHandle {
		public get() {
			Handle handle;
			
			this.GetValue("TimerHandle", handle);
			
			return handle;
		}
		
		public set(Handle handle) {
			this.SetValue("TimerHandle", handle);
		}
	}
	
	public void StopTimer() 
	{
		if(this.TimerHandle != INVALID_HANDLE) 
		{
			this.TimerHandle = INVALID_HANDLE;
		}
	}
	
	public bool Display(Timer func) 
	{
		this.StopTimer();
		if(this.TimerHandle == INVALID_HANDLE) {
			this.TimerHandle = CreateTimer(5.0, func, this.clientId);
			return true;
		}
		return false;
	}
	
}