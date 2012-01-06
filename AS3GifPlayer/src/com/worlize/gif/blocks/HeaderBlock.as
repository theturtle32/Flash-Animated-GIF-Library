package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.GifVersion;
	import com.worlize.gif.errors.FileTypeError;
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class HeaderBlock implements IGIFBlockCodec
	{
		public var bytes:ByteArray;
		
		public var identifier:String;
		public var version:String;
		
		public function decode(stream:IDataInput):void {
			if (stream.bytesAvailable < 6) {
				throw new OutOfDataError("Ran out of data while reading GIF header.");
			}
			
			bytes = new ByteArray();
			stream.readBytes(bytes, 0, 6);
				
			identifier = bytes.readMultiByte(6, 'ascii');
			
			if (identifier.slice(0,3) !== "GIF") {
				throw new FileTypeError("Invalid file type.");
			}
			
			version = identifier.slice(3);
			if (version !== GifVersion.VERSION_87A && version !== GifVersion.VERSION_89A) {
				throw new FileTypeError("Unsupported GIF version: " + version);
			}
			
			bytes.position = 0;
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			ba.writeMultiByte('GIF', 'ascii');
			if (['89a','87a'].indexOf(version) === -1) {
				throw new Error("Invalid GIF version specified.");
			}
			ba.writeMultiByte(version, 'ascii');
			return ba;
		}
		
		public function dispose():void {
			bytes.clear();
			bytes = null;
		}
	}
}