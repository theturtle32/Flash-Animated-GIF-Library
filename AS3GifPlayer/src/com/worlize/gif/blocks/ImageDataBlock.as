package com.worlize.gif.blocks
{
	import com.worlize.gif.errors.FileTypeError;
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class ImageDataBlock implements IGIFBlockCodec
	{
		public var bytes:ByteArray;
		
		public var lzwMinCodeSize:uint;
		
		public function decode(stream:IDataInput):void {
			if (stream.bytesAvailable < 1) {
				throw new OutOfDataError("Out of data while reading image data block LZW minimum code size.");
			}
			lzwMinCodeSize = stream.readUnsignedByte();
			if (lzwMinCodeSize < 2 || lzwMinCodeSize > 8) {
				throw new FileTypeError("Invalid GIF Data: LZW minimum code size is out of bounds.");
			}
			try {
				bytes = DataBlock.decodeDataBlocks(stream);
			}
			catch (e:OutOfDataError) {
				throw new OutOfDataError("Out of data while reading image data.");
			}
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			
			ba.writeByte(lzwMinCodeSize);
			ba.writeBytes(DataBlock.encodeDataBlocks(bytes));
			
			return ba;
		}
		
		public function dispose():void {
			bytes.clear();
			bytes = null;
		}
	}
}