/************************************************************************
 *  Copyright 2012 Worlize Inc.
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ***********************************************************************/

package com.worlize.gif.blocks
{
	import com.worlize.gif.constants.BlockType;
	import com.worlize.gif.constants.DisposalType;
	import com.worlize.gif.errors.FileTypeError;
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	public class GraphicControlExtension implements IGIFBlockCodec
	{
		private var reserved:uint = 0;
		public var disposalMethod:uint = DisposalType.RESTORE_BACKGROUND_COLOR;
		public var userInputExpected:Boolean = false;
		public var hasTransparency:Boolean = false;
		public var delayTime:uint = 0;
		public var transparencyIndex:uint = 0;
		
		// Decode expects the extension block header to already have been
		// read in previously.  It begins reading the data block.
		public function decode(stream:IDataInput):void {
			if (stream.bytesAvailable < 6) {
				throw new OutOfDataError("Out of data while reading graphic control extension.");
			}
			if (stream.readUnsignedByte() !== 4) { // Fixed Block Size
				throw new FileTypeError("Graphic Control Extension has invalid size.");
			}
			packed = stream.readUnsignedByte();
			delayTime = stream.readUnsignedShort();
			transparencyIndex = stream.readUnsignedByte();
			stream.readUnsignedByte(); // Block terminator
		}
		
		// Outputs the encoded extension data, INCLUDING the enclosing
		// extension block and the block terminator.
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			ba.writeByte(BlockType.EXTENSION);
			ba.writeByte(BlockType.GRAPHIC_CONTROL_EXT);
			ba.writeByte(4); // Block size
			ba.writeByte(packed);
			ba.writeShort(delayTime);
			ba.writeByte(transparencyIndex);
			ba.writeByte(0); // Block terminator
			return ba;
		}
		
		
		protected function set packed(byte:uint):void {
			reserved = (byte & 0xE0) >> 5;
			disposalMethod = (byte & 0x1C) >> 2;
			if (disposalMethod > 3) {
				throw new FileTypeError("Invalid disposal method: " + disposalMethod);
			}
			userInputExpected = (byte & 0x02) === 0x02;
			hasTransparency = (byte & 0x01) === 0x01;
		}
		
		protected function get packed():uint {
			var byte:uint = 0;
			byte |= (reserved & 0x03) << 5;
			byte |= (disposalMethod & 0x03) << 2;
			byte |= (userInputExpected ? 0x02 : 0x00);
			byte |= (hasTransparency ? 0x01 : 0x00);
			return byte;
		}
		
		public function dispose():void {
		}
	}
}