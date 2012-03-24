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
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	
	public class LogicalScreenDescriptorBlock implements IGIFBlockCodec
	{
		public var width:uint = 0;
		public var height:uint = 0;
		public var hasgct:Boolean = false;
		public var gctColorResolution:uint = 0;
		public var gctSorted:Boolean = false;
		public var gctNumColors:uint = 0;
		public var backgroundColorIndex:uint = 0;
		public var pixelAspect:uint = 0;
		
		private var _packed:uint;
		
		public function decode(stream:IDataInput):void {
			if (stream.bytesAvailable < 7) {
				throw new OutOfDataError("Out of data while reading logical screen descriptor.");
			}
			
			// logical screen size
			width = stream.readUnsignedShort();
			height = stream.readUnsignedShort();
			packed = stream.readUnsignedByte();
			backgroundColorIndex = stream.readUnsignedByte(); // background color index
			pixelAspect = stream.readUnsignedByte(); // pixel aspect ratio
		}
		
		public function encode(ba:ByteArray = null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			
			ba.writeShort(width);
			ba.writeShort(height);
			ba.writeByte(packed);
			ba.writeByte(backgroundColorIndex);
			ba.writeByte(pixelAspect);
			
			return ba;
		}
		
		// packed fields
		public function set packed(newValue:uint):void {
			hasgct = (newValue & 0x80) !== 0; // 1   : global color table flag
			gctColorResolution = (newValue & 0x70) >> 4; // 2-4 : color resolution
			gctSorted = (newValue & 0x08) !== 0; // 5   : gct sort flag
			gctNumColors = 2 << (newValue & 0x07); // 6-8 : gct size	
		}
		
		public function get packed():uint {
			var byte:uint = 0;
			if (hasgct) {
				byte |= 0x80;
			}
			byte |= (gctColorResolution & 0x07) << 4;
			if (gctSorted) {
				byte |= 0x08;
			}
			switch (gctNumColors) {
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
					throw new Error("Invalid global color table size: " + gctNumColors);
					break;
			}
			
			return byte;
		}
		
		public function dispose():void {
		}
	}
}