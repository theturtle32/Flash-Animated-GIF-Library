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

package com.worlize.gif
{
	import com.worlize.gif.blocks.ApplicationExtension;
	import com.worlize.gif.blocks.ColorTableBlock;
	import com.worlize.gif.blocks.CommentExtension;
	import com.worlize.gif.blocks.GraphicControlExtension;
	import com.worlize.gif.blocks.HeaderBlock;
	import com.worlize.gif.blocks.IGIFBlockCodec;
	import com.worlize.gif.blocks.ImageDataBlock;
	import com.worlize.gif.blocks.ImageDescriptorBlock;
	import com.worlize.gif.blocks.LogicalScreenDescriptorBlock;
	import com.worlize.gif.blocks.NetscapeExtension;
	import com.worlize.gif.blocks.PlainTextExtension;
	import com.worlize.gif.blocks.TrailerBlock;
	import com.worlize.gif.blocks.UnknownExtension;
	import com.worlize.gif.constants.BlockType;
	import com.worlize.gif.constants.DefaultPalette;
	import com.worlize.gif.constants.DisposalType;
	import com.worlize.gif.errors.FileTypeError;
	import com.worlize.gif.errors.OutOfDataError;
	import com.worlize.gif.events.AsyncDecodeErrorEvent;
	import com.worlize.gif.events.GIFDecoderEvent;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.controls.Image;
	
	[Event(name="asyncDecodeError",type="com.worlize.gif.events.AsyncDecodeErrorEvent")]
	[Event(name="decodeComplete",type="com.worlize.gif.events.GIFDecoderEvent")]
	public class GIFDecoder extends EventDispatcher
	{
		protected var data:ByteArray;
		
		protected var header:HeaderBlock;
		protected var lsd:LogicalScreenDescriptorBlock;
		protected var graphicControlExtension:GraphicControlExtension;
		
		protected var globalColorTable:ColorTableBlock;
		protected var fallbackColorTable:ColorTableBlock;
		protected var activeColorTable:ColorTableBlock;		

		public var width:uint;
		public var height:uint;
		
		public var backgroundColor:uint = 0xFFFFFFFF;
		public var loopCount:uint = 1;
		
		public var frameDecodedCount:uint = 0;
		public var framesToDecode:uint = 0;
		public var frames:Vector.<GIFFrame>;
		
		private var startTime:uint;
		public var totalDecodeTime:uint;
		public var blockingDecodeTime:uint;
		
		private var _hasError:Boolean = false;
		
		// Store the exact sequence of blocks from the stream
		protected var blockSequence:Vector.<IGIFBlockCodec>;
		
		public function get hasError():Boolean {
			return _hasError;
		}
		
		public function decodeBytes(inputData:ByteArray):void {
			startTime = (new Date()).valueOf();
			data = inputData;
			data.endian = Endian.LITTLE_ENDIAN;
			blockSequence = new Vector.<IGIFBlockCodec>();
			frames = new Vector.<GIFFrame>();
			framesToDecode = 0;
			
			try {
				readMetadata();
				readContents();
			}
			catch(e:Error) {
				abortDecode();
				_hasError = true;
				var errorEvent:AsyncDecodeErrorEvent = new AsyncDecodeErrorEvent(AsyncDecodeErrorEvent.ASYNC_DECODE_ERROR);
				errorEvent.text = e.message;
				dispatchEvent(errorEvent);
				return;
			}
			var endTime:uint = (new Date()).valueOf();
			blockingDecodeTime = endTime - startTime;
		}
		
		public function cleanup():void {
			data.clear();
			data = null;
			for (var i:int = 0; i < blockSequence.length; i++) {
				blockSequence[i].dispose();
			}
		}
		
		private function readMetadata():void {
			// File Format Header
			header = new HeaderBlock();
			header.decode(data);
			blockSequence.push(header);
			
			// Logical Screen Descriptor
			lsd = new LogicalScreenDescriptorBlock();
			lsd.decode(data);
			width = lsd.width;
			height = lsd.height;
			blockSequence.push(lsd);
			
			// If we have a global color table, lets decode it.
			if (lsd.hasgct) {
				globalColorTable = new ColorTableBlock();
				globalColorTable.numColors = lsd.gctNumColors;
				globalColorTable.decode(data);
				blockSequence.push(globalColorTable);
				
				// Find the actual background color
				backgroundColor = globalColorTable.table[lsd.backgroundColorIndex];
			}
			else {
				// Initialize the fallback color table just in case.
				fallbackColorTable = new ColorTableBlock();
				fallbackColorTable.numColors = 256;
				fallbackColorTable.table = DefaultPalette.WINDOWS;
			}
		}
		
		private function readContents():void {
			var complete:Boolean = false;
			var code:uint;
			while (!complete) {
				if (data.bytesAvailable < 1) {
					throw new OutOfDataError("Out of data while looking for next block.");
				}
				code = data.readUnsignedByte();
				switch(code) {
					// Decode the extension
					case BlockType.EXTENSION:
						decodeExtension();
						break;

					// We've got an image to decode
					case BlockType.IMAGE_DESCRIPTOR:
						decodeImage();
						break;
					
					// We've reached the end of the file!
					case BlockType.TRAILER:
						blockSequence.push(new TrailerBlock());
						complete = true;
						break;

//					case 0x00: // bad byte, but keep going and see what happens?
					           // No -- this is invalid.
//						break;
					default:
						throw new FileTypeError("Invalid data encountered while decoding GIF stream.");
						break;
				}
			}
		}
		
		private function decodeExtension():void {
			var code:uint;
			if (data.bytesAvailable < 1) {
				throw new OutOfDataError("Out of data while trying to read extension");
			}
			code = data.readUnsignedByte();
			
			switch(code) {
				case BlockType.APPLICATION_EXT:
					decodeAppExtension();
					break;
				
				case BlockType.GRAPHIC_CONTROL_EXT:
					graphicControlExtension = new GraphicControlExtension();
					graphicControlExtension.decode(data);
					blockSequence.push(graphicControlExtension);
					break;
				
				case BlockType.COMMENT_EXT:
					var commentExt:CommentExtension = new CommentExtension();
					commentExt.decode(data);
					blockSequence.push(commentExt);
					break;
				
				case BlockType.PLAIN_TEXT_EXT:
					var plainTextExt:PlainTextExtension = new PlainTextExtension();
					plainTextExt.decode(data);
					blockSequence.push(commentExt);
					break;
				
				default:
					throw new FileTypeError("Invalid GIF data - invalid extension type encountered.")
//					var unknownExt:UnknownExtension = new UnknownExtension();
//					unknownExt.extensionLabel = code;
//					unknownExt.decode(data);
//					blockSequence.push(unknownExt);
					break;
			}
		}
		
		private function decodeAppExtension():void {
			var appExt:ApplicationExtension = new ApplicationExtension();
			appExt.decode(data);
			
			// We only support the NETSCAPE2.0 app extension.  All others
			// are ignored.
			if (appExt.appIdentifier === NetscapeExtension.APP_IDENTIFIER &&
				appExt.appAuthCode === NetscapeExtension.APP_AUTH_CODE)
			{
				var netscapeExt:NetscapeExtension = new NetscapeExtension();
				netscapeExt.decodeFromApplicationExtension(appExt);
				blockSequence.push(netscapeExt);
				loopCount = netscapeExt.loopCount;
			}
			else {
				blockSequence.push(appExt);
			}
		}
		
		private function decodeImage():void {
			var imageDescriptor:ImageDescriptorBlock = new ImageDescriptorBlock();
			imageDescriptor.decode(data);
			blockSequence.push(imageDescriptor);
			
			if (imageDescriptor.haslct) {
				var localColorTable:ColorTableBlock = new ColorTableBlock();
				localColorTable.numColors = imageDescriptor.lctNumColors;
				localColorTable.decode(data);
				blockSequence.push(localColorTable);
				
				// Set local color table as active
				activeColorTable = localColorTable;
			}
			else if (globalColorTable) {
				// Set global color table as active
				activeColorTable = globalColorTable;
			}
			else {
				// If no color table is available, use the default old-school
				// Windows 256-color palette. 
				activeColorTable = fallbackColorTable;
			}
			
			var imageDataBlock:ImageDataBlock = new ImageDataBlock();
			imageDataBlock.decode(data);
			blockSequence.push(imageDataBlock);

			frames.push(buildFrame(imageDescriptor, imageDataBlock));
			
			// Clean up the state after finishing with a frame.
			graphicControlExtension = null;
		}
		
		private function buildFrame(imageDescriptor:ImageDescriptorBlock, imageData:ImageDataBlock):GIFFrame {
			// ByteArray to hold a new GIF file of just this one frame
			var ba:ByteArray = new ByteArray();
			ba.endian = Endian.LITTLE_ENDIAN;
			
			header.encode(ba);
			
			var localLsd:LogicalScreenDescriptorBlock = new LogicalScreenDescriptorBlock();
			localLsd.pixelAspect = lsd.pixelAspect;
			// Render the image at the size of this particular frame only
			localLsd.width = imageDescriptor.width;
			localLsd.height = imageDescriptor.height;
			localLsd.backgroundColorIndex = lsd.backgroundColorIndex;
			localLsd.gctColorResolution = lsd.gctColorResolution;
			// Encode the active color table, whether local or global,
			// as the global color table of the new file.
			localLsd.gctNumColors = activeColorTable.numColors;
			localLsd.hasgct = true;
			localLsd.gctSorted = false;
			localLsd.encode(ba);
			
			// Include the correct color table
			activeColorTable.encode(ba);
			
			if (graphicControlExtension) {
				var localGCE:GraphicControlExtension = new GraphicControlExtension();
				// We're making a single frame image so this shouldn't matter
				localGCE.delayTime = 0;
				localGCE.userInputExpected = false;
				localGCE.disposalMethod = graphicControlExtension.disposalMethod;
				
				// The transparency aspects of the GCE are what's important here
				localGCE.hasTransparency = graphicControlExtension.hasTransparency;
				localGCE.transparencyIndex = graphicControlExtension.transparencyIndex;
				localGCE.encode(ba);
			}
			
			var localId:ImageDescriptorBlock = new ImageDescriptorBlock();
			// No local color table, only a global one
			localId.haslct = false;
			localId.lctNumColors = 2;
			localId.lctSorted = false;
			localId.width = imageDescriptor.width;
			localId.height = imageDescriptor.height;
			// Since we're rendering this image at the size of only this
			// individual frame, we don't want it offset at all.  We will
			// manually apply the offset when compositing the frames together.
			localId.offsetLeft = 0;
			localId.offsetTop = 0;
			localId.reserved = 0;
			localId.interlaced = imageDescriptor.interlaced;
			localId.encode(ba);
			
			imageData.encode(ba);
			
			// Terminate the file properly.
			var trailerBlock:TrailerBlock = new TrailerBlock();
			trailerBlock.encode(ba);
			
			ba.position = 0;

			var frame:GIFFrame = new GIFFrame();
			frame.gifData = ba;
			frame.left = imageDescriptor.offsetLeft;
			frame.top = imageDescriptor.offsetTop;
			frame.width = imageDescriptor.width;
			frame.height = imageDescriptor.height;
			frame.backgroundColor = activeColorTable.table[localLsd.backgroundColorIndex];
			frame.backgroundColorIndex = localLsd.backgroundColorIndex;
			if (graphicControlExtension) {
				frame.delayMs = graphicControlExtension.delayTime * 10;
				frame.disposalType = graphicControlExtension.disposalMethod;
				frame.hasTransparency = graphicControlExtension.hasTransparency;
				frame.transparencyIndex = graphicControlExtension.transparencyIndex;
			}
			else {
				frame.hasTransparency = false;
				frame.transparencyIndex = 0;
				frame.delayMs = 42; // default 24fps
				frame.disposalType = DisposalType.RESTORE_BACKGROUND_COLOR;
			}
			
			// Start decoding the image data
			framesToDecode ++;
			frame.addEventListener(GIFDecoderEvent.DECODE_COMPLETE, handleFrameDecodeComplete);
			frame.addEventListener(AsyncDecodeErrorEvent.ASYNC_DECODE_ERROR, handleFrameAsyncDecodeError);
			frame.decode();
			return frame;
		}
		
		
		protected function renderCompositedFrames():void {
			var startTime:uint = (new Date()).valueOf();
			var w:uint = width;
			var h:uint = height;
			var frame:GIFFrame;
			var prevFrame:GIFFrame;
			var lastNoDisposalFrame:GIFFrame;
			for (var i:uint=0; i < framesToDecode; i++) {
				frame = frames[i];
				
				var source:BitmapData = frame.bitmapData;
				var dest:BitmapData = new BitmapData(w, h, true, 0x00FFFFFF);
				var backgroundColor:uint;
				var rect:Rectangle;
				if (prevFrame === null) {
					// Start the first frame with the correct background fill.
					// ODD NOTE: We always start with a transparent canvas to
					// match Firefox and Chrome's rendering behavior.

//					backgroundColor = frame.backgroundColor;
//					if (frame.hasTransparency) {
//						backgroundColor &= 0x00FFFFFF;
//					}
//					dest.fillRect(new Rectangle(0,0,w,h), backgroundColor);
				}
				else {
					// Start with the exact pixels from the previous frame
					dest.copyPixels(prevFrame.bitmapData, new Rectangle(0, 0, w, h), new Point(0, 0));
					
					var dispose:uint = prevFrame.disposalType;
					
					// Remove previous frame according to specified disposal rules
					if ((dispose === DisposalType.RESTORE_TO_PREVIOUS && lastNoDisposalFrame === null) ||
					    (dispose === DisposalType.RESTORE_BACKGROUND_COLOR))
					{
						// Fill with either the background color or transparency.
						backgroundColor = prevFrame.backgroundColor;
						// ODD NOTE: We always fill with transparency to
						// match Firefox and Chrome's rendering behavior.
//						if (prevFrame.hasTransparency) {
							// Apply correct transparency
							backgroundColor &= 0x00FFFFFF;
//						}
						rect = new Rectangle(prevFrame.left, prevFrame.top, prevFrame.width, prevFrame.height);
						dest.fillRect(rect, backgroundColor);
					}
					else if (dispose === DisposalType.NO_DISPOSAL || dispose == DisposalType.DO_NOT_DISPOSE) {
						// Do nothing, keep entire previous image as starting point
						lastNoDisposalFrame = prevFrame;
					}
					else if (dispose === DisposalType.RESTORE_TO_PREVIOUS && i >= 1) {
						// Restore previously occupied rectangle to what was there before
						var f:GIFFrame = lastNoDisposalFrame;
						rect = new Rectangle(prevFrame.left, prevFrame.top, prevFrame.width, prevFrame.height) ;
						dest.copyPixels(f.bitmapData, rect, new Point(prevFrame.left, prevFrame.top));
					}
				}

				rect = new Rectangle(0,0,frame.width,frame.height);
				dest.copyPixels(frame.bitmapData, rect, new Point(frame.left, frame.top), null, null, true);
				
				// Reclaim the memory for the original image piece that we
				// no longer have any use for.
				frame.bitmapData.dispose();
				
				frame.bitmapData = dest;
				prevFrame = frame;
			}
			var endTime:uint = (new Date()).valueOf();
			blockingDecodeTime += (endTime - startTime);
		}
		
		public function encode():ByteArray {
			var ba:ByteArray = new ByteArray();
			ba.endian = Endian.LITTLE_ENDIAN;
			
			for (var i:int=0,len:int=blockSequence.length; i < len; i++) {
				blockSequence[i].encode(ba);
			}
			
			ba.position = 0;
			return ba;
		}
		
		protected function handleFrameDecodeComplete(event:GIFDecoderEvent):void {
			frameDecodedCount ++;
			if (frameDecodedCount === framesToDecode && !_hasError) {
				renderCompositedFrames();
				
				var endTime:uint = (new Date()).valueOf();
				totalDecodeTime = endTime - startTime;
				
				var decoderEvent:GIFDecoderEvent = new GIFDecoderEvent(GIFDecoderEvent.DECODE_COMPLETE);
				dispatchEvent(decoderEvent);
			}
		}
		
		protected function handleFrameAsyncDecodeError(event:AsyncDecodeErrorEvent):void {
			abortDecode();
			var errorEvent:AsyncDecodeErrorEvent = new AsyncDecodeErrorEvent(AsyncDecodeErrorEvent.ASYNC_DECODE_ERROR);
			errorEvent.text = "An error was encountered while Flash was decoding an image frame.";
			dispatchEvent(errorEvent);
		}
		
		protected function abortDecode():void {
			for (var i:int=0,len:int=frames.length; i < len; i++) {
				frames[i].abortDecode();
			}
			cleanup();
		}
	}
}