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
	import com.worlize.gif.errors.FileTypeError;
	import com.worlize.gif.errors.OutOfDataError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;

	public class DataBlock implements IGIFBlockCodec
	{
		public var blockSize:uint;
		public var bytes:ByteArray;
		public var isTerminator:Boolean = false;
		
		public static function decodeDataBlocks(stream:IDataInput):ByteArray {
			var ba:ByteArray = new ByteArray();
			ba.endian = Endian.LITTLE_ENDIAN;
			var length:uint;
			do {
				if (stream.bytesAvailable === 0) {
					throw new OutOfDataError("Out of data while reading data block.");
				}
				length = stream.readUnsignedByte();
				if (length > 0) {
					if (stream.bytesAvailable < length) {
						throw new OutOfDataError("Out of data while reading data block.");
					}
					stream.readBytes(ba, ba.length, length);
				}
			}
			while (length > 0);
			return ba;
		}
		
		public static function encodeDataBlocks(data:ByteArray):ByteArray {
			data.position = 0;
			
			var ba:ByteArray = new ByteArray();
			ba.endian = Endian.LITTLE_ENDIAN;
			
			var pos:int = 0;
			var length:int = data.length;
			while (pos < length) {
				var bytesThisBlock:int = Math.min(length-pos, 0xFF);
				ba.writeByte(bytesThisBlock);
				ba.writeBytes(data, pos, bytesThisBlock);
				pos += bytesThisBlock;
			}
			ba.writeByte(0); // Block terminator
			return ba;
		}
		
		public function decode(stream:IDataInput):void {
			if (stream.bytesAvailable === 0) {
				throw new OutOfDataError("Out of data while reading data block.");
			}
			blockSize = stream.readUnsignedByte();
			bytes = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			if (blockSize === 0) {
				isTerminator = true;
				return;
			}
			if (blockSize > 0) {
				if (stream.bytesAvailable < blockSize) {
					throw new OutOfDataError("Out of data while reading data block.");
				}
				stream.readBytes(bytes, 0, blockSize);
			}
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			if (isTerminator) {
				ba.writeByte(0); // zero-length block is a terminator.
				return ba;
			}

			if (bytes.length > 0xFF) {
				throw new RangeError("Block size cannot exceed 255");
			}
			ba.writeByte(bytes.length);
			ba.writeBytes(bytes, 0, bytes.length);
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