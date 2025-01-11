# Old cgi scripts for bbs (keijiban)

## require following modules

* CGI::Carp
* Data::Dumper;
* Digest::MD5
* Digest::SHA
* File::Basename
* File::Copy;
* GD or Image::Magick
* IO::Dir;
* IO::File;
* List::Util
* POSIX;
* Time::Local
* URI::Escape

Not for FAST-CGI or mod_perl (global values are scattered many.)  
if file '.https' exists, then using https intead of http protocol  
if file 'VERSION' exists, load version number from this file.

## setup ....

1. setting global.cgi
2. rename or copy dot.htaccess to .htaccess and modify RewriteBase directive.
3. run shell and execute setup_with_shell.pl ( option 1 are 'not modify acl')