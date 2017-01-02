#SMMOCM
###A 3DS homebrew app written in Lua to allow people to exchange courses over the internet
####Feature List:
* Users can choose the name of their course before uploading it.
* A level ID is randomly generated and told to the user during the upload process.  Currently there is no guarantee they are unique, but that will be fixed soon
* Courses cannot be downloaded unless they are added to the IDlist file on the server, this gives server owners the ability to look over courses before letting users download them.  Also courses are uploaded in hex so even if a user downloaded them it would be useless
* Before uploading, each level is checked to make sure the user has cleared it so you cannot upload unbeatable levels
* Before uploading, the level is translated into hex digits so it can be uploaded, and the user's unique LockoutID is overwritten with zeros for security.  The server owner then can put those hex digits into a hex editor so the level can be downloaded
* Downloading is done using the generated level ID, the user enters it and the download begins
* The file is downloaded to a temporary file on the SD card for reading and then is read, translated out of hex, the downloading user's LockoutID is injected, and the data is written to the course file in extdata that the user selected.
* Automatically generates a configuration file on first run that obtains the user's LockoutID and asks for the server IP  
* A decent GUI
  
####Planned Features:
* PHP scripts that aren't a hacker's friend (maybe)  
* Integration with Makers of Mario (to be used as a server and a way to integrate the metadata system/browsing)
* A metadata system (stars, comments, downloads, etc.)
* A CIA version
* Browsing

##Use:
It's pretty simple, just place SMMOCM.(lua/3dsx/smdh) in /3ds/SMMOCM and you are good to go  
If you want to look at the source code, it's in Lua so have fun.  It's in the "source" folder.  
  
####Notes on the LPP edits:
* If you want to compile LPP for yourself then just replace the luaNetwork.cpp and main.cpp files with mine.
* I honestly don't know if HTTP redirects will work if you make a server that does that, but one of the edits enables 302 as a valid response code so contact me if you find out.

##Credits:
* Rinnegatamante for [Lua Player Plus](https://github.com/Rinnegatamante/lpp-3ds)
* Marc Robledo for [SMDH Creator](http://usuaris.tinet.cat/mark/smdh_creator/)
* BrokenR3C0RD#7695 & jaku#5640 on discord for criticising my code and helping me understand POST
