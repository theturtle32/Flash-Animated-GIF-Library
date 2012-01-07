package com.worlize.gif.blocks
{
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	public class ColorTableBlock implements IGIFBlockCodec
	{
		public var numColors:uint;
		public var table:Vector.<uint>;
		
		protected var cachedEncodedBytes:ByteArray;
		
		public function decode(stream:IDataInput):void {
			var bytesToRead:int = 3 * numColors;
			
			if (stream.bytesAvailable < bytesToRead) {
				throw new OutOfDataError("Out of data while decoding color table");
			}
			
			var ba:ByteArray = new ByteArray();
			ba.writeByte(0);
			stream.readBytes(ba, 1, bytesToRead);
			
			table = new Vector.<uint>(256); // max size to avoid bounds checks
			
			ba.endian = Endian.BIG_ENDIAN;
			for (var i:uint = 0; i < numColors; i++) 
			{
				ba.position -= 1;
				table[i] = ba.readUnsignedInt() | 0xFF000000;
			}
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (!cachedEncodedBytes) {
				cachedEncodedBytes = new ByteArray();
				cachedEncodedBytes.endian = Endian.LITTLE_ENDIAN;
				for (var i:uint = 0; i < numColors; i++) {
					var c:uint = table[i];
					cachedEncodedBytes.writeByte((c & 0x00FF0000) >> 16); // Red
					cachedEncodedBytes.writeByte((c & 0x0000FF00) >> 8);  // Green
					cachedEncodedBytes.writeByte( c & 0x000000FF);        // Blue
				}
			}
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			ba.writeBytes(cachedEncodedBytes);
			return ba;
		}
		
		public function dispose():void {
			if (cachedEncodedBytes) {
				cachedEncodedBytes.clear();
				cachedEncodedBytes = null;
			}
		}
	}
}