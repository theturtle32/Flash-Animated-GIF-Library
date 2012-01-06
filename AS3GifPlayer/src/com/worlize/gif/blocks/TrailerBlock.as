package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class TrailerBlock implements IGIFBlockCodec
	{
		public function decode(stream:IDataInput):void {
			// No-op
		}
		
		public function encode(ba:ByteArray=null):ByteArray
		{
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			ba.writeByte(BlockType.TRAILER);
			
			return ba;
		}
		
		public function dispose():void {
		}
	}
}