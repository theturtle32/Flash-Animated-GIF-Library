package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	public class CommentExtension implements IGIFBlockCodec
	{
		public var text:String;
		
		public function decode(stream:IDataInput):void {
			var textBytes:ByteArray = DataBlock.decodeDataBlocks(stream);
			text = textBytes.readMultiByte(textBytes.length, 'ascii');
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			var textBytes:ByteArray = new ByteArray();
			textBytes.writeMultiByte(text, 'ascii');
			
			ba.writeByte(BlockType.EXTENSION);
			ba.writeByte(BlockType.COMMENT_EXT);
			ba.writeBytes(DataBlock.encodeDataBlocks(textBytes));
			
			return ba;
		}
		
		public function dispose():void {
		}
	}
}