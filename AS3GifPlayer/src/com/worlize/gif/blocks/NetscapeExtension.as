package com.worlize.gif.blocks
{
	import com.worlize.gif.errors.FileTypeError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	public class NetscapeExtension implements IGIFBlockCodec
	{
		public static const APP_IDENTIFIER:String = "NETSCAPE";
		public static const APP_AUTH_CODE:String = "2.0";
		
		protected var appExtension:ApplicationExtension;
		public var loopCount:uint = 0;
		
		function NetscapeExtension() {
			appExtension = new ApplicationExtension();
			appExtension.appIdentifier = APP_IDENTIFIER;
			appExtension.appAuthCode = APP_AUTH_CODE;
		}
		
		public function decodeFromApplicationExtension(extension:ApplicationExtension):void {
			appExtension = extension;
			if (appExtension.appIdentifier !== APP_IDENTIFIER ||
				appExtension.appAuthCode !== APP_AUTH_CODE) {
				throw new FileTypeError("Unknown application data block.  Was expecting a NETSCAPE2.0 block.");
			}
			if (appExtension.bytes.readUnsignedByte() === 1) {
				loopCount = appExtension.bytes.readUnsignedShort();
			}
		}
		
		public function decode(stream:IDataInput):void {
			var ext:ApplicationExtension = new ApplicationExtension();
			ext.decode(stream);
			decodeFromApplicationExtension(ext);
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			var bytes:ByteArray;
			appExtension.bytes = bytes = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.writeByte(1); // Identify loop count parameter
			bytes.writeShort(loopCount);
			bytes.position = 0;
			return appExtension.encode(ba);
		}
		
		public function dispose():void {
		}
	}
}