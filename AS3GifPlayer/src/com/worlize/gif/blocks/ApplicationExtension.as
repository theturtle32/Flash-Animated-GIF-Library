package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	public class ApplicationExtension implements IGIFBlockCodec
	{
		public var appIdentifier:String;
		public var appAuthCode:String;
		public var bytes:ByteArray;
		
		public function decode(stream:IDataInput):void {
			// Read application identifier
			var identifierBlock:DataBlock = new DataBlock();
			identifierBlock.decode(stream);
			
			// Decode application identifier
			appIdentifier = identifierBlock.bytes.readMultiByte(8, "ascii");
			appAuthCode = identifierBlock.bytes.readMultiByte(3, "ascii");
			
			// Read actual application data
			bytes = DataBlock.decodeDataBlocks(stream);
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (appIdentifier.length !== 8) {
				throw new Error("Application Extension field appIdentifier must be exactly 8 characters long.");
			}
			if (appAuthCode.length !== 3) {
				throw new Error("Application Extension field appAuthCode must be exactly 3 characters long.");
			}
			var identifierBlock:DataBlock = new DataBlock();
			identifierBlock.bytes = new ByteArray();
			identifierBlock.bytes.writeMultiByte(appIdentifier, "ascii");
			identifierBlock.bytes.writeMultiByte(appAuthCode, "ascii");
			
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			
			// Write out the data
			ba.writeByte(BlockType.EXTENSION);
			ba.writeByte(BlockType.APPLICATION_EXT);
			ba.writeBytes(identifierBlock.encode());
			ba.writeBytes(DataBlock.encodeDataBlocks(bytes));

			return ba;
		}
		
		public function dispose():void {
			bytes.clear();
			bytes = null;
		}
	}
}