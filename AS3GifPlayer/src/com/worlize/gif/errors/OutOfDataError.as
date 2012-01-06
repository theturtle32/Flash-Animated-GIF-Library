package com.worlize.gif.errors
{
	public class OutOfDataError extends Error
	{
		public function OutOfDataError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}