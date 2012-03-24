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
			if (bytes) {
				bytes.clear();
				bytes = null;
			}
		}
	}
}