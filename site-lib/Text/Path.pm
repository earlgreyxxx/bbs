#!/usr/bin/perl
package Text::Path;

=com
  * URL path settings...
=cut
use strict;
use warnings;
use utf8;
use base qw/Exporter/;
use File::Basename qw/fileparse/;

our @EXPORT = qw/urlpath realpath/;
our @EXPORT_OK = ();
our $VERSION = '0.0.1';

#------------------------------------------------------------------------------
# 相対アドレスが混じったパスを正規のパスに変換する
#   $limitは、パス区切り文字の位置に変換制限をかける。
#------------------------------------------------------------------------------

sub urlpath
{
  my $script_name = (split /\?/,$ENV{REQUEST_URI},2)[0];

  my ($cginame, $request_vdir, $ext) = ('',$script_name,'');
  ($cginame, $request_vdir, $ext) = fileparse($script_name,qr/\.[^\.]*?/) if(substr($script_name,-1) ne '/');

  chop $request_vdir if(substr($request_vdir,-1) eq '/');

  # if .https exists, use https scheme.
  my $hostname = (-e '.https' ? 'https' : 'http') . "://$ENV{HTTP_HOST}";

  my ($b,$d,$e) = fileparse($ENV{SCRIPT_NAME},qr/\.[^.]*/);
  chop $d;
  my $isrewrite = $request_vdir ne $d;

  'cginame' => $cginame,
  'hostname' => $hostname,
  'script_name' => $script_name,
  'request_vdir' => $request_vdir,
  'extension' => $ext,
  'isrewrite' => $isrewrite,
  'script_filedir' => $d,
  'script_filename' => $b,
  'script_extension' => $e;
}

#------------------------------------------------------------------------------
# 相対アドレスが混じったパスを正規のパスに変換する
#   $limitは、パス区切り文字の位置に変換制限をかける。
#------------------------------------------------------------------------------
sub realpath
{
  my ($path,$limit) = @_;
  $limit = 1 unless(defined $limit);

  my @rva = ();
  my @names = split /\//,$path;

  my $pos = 0;
  foreach my $name_(@names)
    {
      if($name_ eq '..')
        {
          if($pos > $limit)
            {
              $pos--;
              pop @rva;
            }              
        }
      else
        {
          if($name_ ne '.')
            {
              push @rva,$name_;
              $pos++;
            }
        }
    }

  return join '/',@rva;
}

1;

