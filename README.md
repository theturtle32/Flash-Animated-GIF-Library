This is a library that I had to write in order to facilitate animated avatars and room objects in Worlize.  Haven't gotten around to writing any documentation.  For a usage example, take a look at GifTest/src/GifTest.mxml and if you would like me to spend some time writing up documentation, vote for it by sending me a message! ;-)

In my tests it is two orders of magnitude faster than Thibault Imbert's [AS3 Gif Player Class](http://www.bytearray.org/?p=95), and it manages to correctly render every valid GIF file I could find.  Its parser is quite strict, however, so if you have a GIF that works in the browser but not with this library it probably means your browser is being overly lenient with the corrupt image data.

The speed gains are achieved by specifically avoiding doing any pixel decoding at all and instead splitting and re-packaging each frame of the animation into its own freestanding gif file, handing the resulting single-frame GIF files to Flash to decode the frame's image data internally via the Loader class.

Try the test app:
[Try the test app](http://theturtle32.github.io/Flash-Animated-GIF-Library)

Check out [Worlize](http://www.worlize.com) and try uploading an animated GIF as your avatar!  :)

This library is made available under the Apache License, Version 2.0
