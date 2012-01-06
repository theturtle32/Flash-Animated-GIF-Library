package com.worlize.gif.errors
{
	public class FileTypeError extends Error
	{
		public function FileTypeError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}