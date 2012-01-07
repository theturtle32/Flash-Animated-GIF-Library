package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class UnknownExtension implements IGIFBlockCodec
	{
		public var extensionLabel:uint;
		public var bytes:ByteArray;
		
		public function decode(stream:IDataInput):void {
			bytes = DataBlock.decodeDataBlocks(stream);
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			
			ba.writeByte(BlockType.EXTENSION);
			ba.writeByte(extensionLabel);
			ba.writeBytes(DataBlock.encodeDataBlocks(bytes));
			
			return ba;
		}
		
		public function dispose():void {
			if (bytes) {
				bytes.clear();
				bytes = null;
			}
		}
	}
}