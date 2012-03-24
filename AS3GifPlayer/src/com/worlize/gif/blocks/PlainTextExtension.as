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
	import com.worlize.gif.errors.FileTypeError;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	public class PlainTextExtension implements IGIFBlockCodec
	{
		public var text:String;
		public var metadataBlock:DataBlock;
		
		public function decode(stream:IDataInput):void {
			try {
				// Read metadata
				metadataBlock = new DataBlock();
				metadataBlock.decode(stream);
				
				// Read actual text
				var textBytes:ByteArray = DataBlock.decodeDataBlocks(stream);
			}
			catch (e:FileTypeError) {
				throw new FileTypeError("Error while decoding a plain text block.");
			}
			
			// Decode ASCII text
			text = textBytes.readMultiByte(textBytes.length, "ascii");
		}
		
		public function encode(ba:ByteArray=null):ByteArray {
			if (ba === null) {
				ba = new ByteArray();
				ba.endian = Endian.LITTLE_ENDIAN;
			}
			
			ba.writeByte(BlockType.EXTENSION);
			ba.writeByte(BlockType.PLAIN_TEXT_EXT);
			
			// Write metadata block
			ba.writeBytes(metadataBlock.encode());
			
			// Write actual text
			var textBytes:ByteArray = new ByteArray();
			textBytes.writeMultiByte(text, "ascii");
			ba.writeBytes(DataBlock.encodeDataBlocks(textBytes));
			
			return ba;
		}
		
		public function dispose():void {
		}
	}
}