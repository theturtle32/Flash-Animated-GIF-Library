This is a library that I had to write in order to facilitate animated avatars and room objects in Worlize.  Hope to write some documentation and examples sometime after coming back from CES.

In my tests it is two orders of magnitude faster than Thibault Imbert's [AS3 Gif Player Class](http://www.bytearray.org/?p=95), and it manages to render every valid GIF file I could find correctly.  Its parser is quite strict, so if you have a GIF that works in the browser but not with this class that probably means your browser is being overly lenient with the corrupt image data.

The speed gains are achieved by avoiding doing any pixel decoding at all by instead splitting and re-packaging each frame of the animation into its own freestanding gif file and then handing the resulting files to Flash to decode the image frame internally via the Loader class.

Check out [http://www.worlize.com](Worlize) and try uploading an animated GIF as your avatar!  :)
