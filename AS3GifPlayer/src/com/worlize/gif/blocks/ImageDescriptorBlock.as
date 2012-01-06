package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class ImageDescriptorBlock implements IGIFBlockCodec
	{
		public var offsetLeft:uint;
		public var offsetTop:uint;
		public var width:uint;
		public var height:uint;
		public var haslct:Boolean;
		public var interlaced:Boolean;
		public var lctSorted:Boolean;
		public var reserved:uint;
		public var lctNumColors:uint;
		
		public function decode(stream:IDataInput):void {
			if (stream.bytesAvailable < 9) {
				throw new OutOfDataError("Out of data while reading image descriptor block.");
			}
			offsetLeft = stream.readUnsignedShort();
			offsetTop = stream.readUnsignedShort();
			width = stream.readUnsignedShort();
			height = stream.readUnsignedShort();
			packed = stream.readUnsignedByte();
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			
			ba.writeByte(BlockType.IMAGE_DESCRIPTOR);
			ba.writeShort(offsetLeft);
			ba.writeShort(offsetTop);
			ba.writeShort(width);
			ba.writeShort(height);
			ba.writeByte(packed);
			
			return ba;
		}
		
		public function set packed(byte:uint):void {
			haslct = Boolean(byte & 0x80);
			interlaced = Boolean(byte & 0x40);
			lctSorted = Boolean(byte & 0x20);
			reserved = (byte & 0x18) >> 3;
			lctNumColors = 2 << (byte & 0x07);
		}
		
		public function get packed():uint {
			var byte:uint = 0;
			if (haslct) {
				byte |= 0x80
			}
			if (interlaced) {
				byte |= 0x40;
			}
			if (lctSorted) {
				byte |= 0x20;
			}
			byte |= ((reserved & 0x03) << 3);
			
			switch (lctNumColors) {
				case 2:
					byte |= 0;
					break;
				case 4:
					byte |= 1;
					break;
				case 8:
					byte |= 2;
					break;
				case 16:
					byte |= 3;
					break;
				case 32:
					byte |= 4;
					break;
				case 64:
					byte |= 5;
					break;
				case 128:
					byte |= 6;
					break;
				case 256:
					byte |= 7;
					break;
				default:
					throw new Error("Invalid local color table size: " + lctNumColors);
					break;
			}
			
			return byte;
		}
		
		public function dispose():void {
		}
	}
}