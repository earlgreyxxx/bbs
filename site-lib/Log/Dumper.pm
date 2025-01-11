#!/usr/bin/perl
package Log::Dumper;
###########################################################
=pod

=head1 Log format is used Data::Dumper Module

=cut
##########################################################
use strict;
use warnings;
use base qw/Exporter/;
our @EXPORT = qw/parse writeLine getLogEx create_record/;
our @EXPORT_OK = qw/init inject/;

use IO::File;
use Data::Dumper;

our ($NUM_OF_IMAGES,$split,$split2);
our $storeTo = sub {};

#Subroutines
#argument 1st is Dumpered string, and 2nd is bool value which is decided splited or not.
sub parse
{
  my ($line,$isRaw) = @_;
  $line = (split /$split/,$line,2)[1] if(defined($isRaw) && $isRaw);
  my $items = eval $line;
  die $@ if($@);

  my @files = ();
  push @files,@{$items->{images}};
  push @files,$_,$items->{attached}{$_} foreach(@{$items->{attached_ord}});

  $items->{files} = [ @files ] ;
  $items->{attrib} = [ $items->{direct},
                       $items->{lastupdate},
                       $items->{registed},
                       $items->{category},
                       $items->{reserve},
                       ('') x 5,
                       $items->{public},
                       $items->{notify},
                       $items->{notify_to},
                       $items->{outline},
                       $items->{headline} ];
  $items->{items} = [ $items->{key},
                      $items->{title},
                      $items->{date},
                      $items->{body},
                      join $split2,@{$items->{attrib}},
                      join $split2,@{$items->{files}},
                      $items->{dkey},
                      @{$items->{options}} ];
  $items->{image} = defined $items->{images}[0] ? $items->{images}[0] : '';

  return $items;
}

sub create_record
{
  my $items = shift;
  return if(ref $items ne 'HASH');

  delete $items->{files};
  delete $items->{image};
  delete $items->{items};

  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Sortkeys = 1;

  return Dumper($items);
}

sub writeLine
{
  my ($fout,$hlog,$key) = @_;
  $fout->print(join($split,$key,$hlog->{$key}),"\n")
}

sub getLogEx
{
  my ($filename,$key,$subkey,$value) = @_;
  my $is_filter = ref($subkey) eq 'CODE';

  $key = 0;
  $subkey = 0 unless($is_filter);

  -e $filename || return 0;
  my $fin = IO::File->new($filename) || cgiOut(text('can not open file'));

  my $header = $fin->getline;
  $header =~ s/[\r\n]//g;

  my ($hkey) = split(/$split/,$header,2);
  $storeTo->($hkey,$header);

  while(defined(local $_ = $fin->getline))
    {
      s/[\r\n]//g;
      next if(/^\s*$/);

      my @log = split(/$split/,$_,2);

      if($is_filter)
        {
          my $result = &$subkey($_);
          if($result)
            {
              $storeTo->(@log);
              last if($result < 0);
            }
        }
      else
        {
          if($value)
            {
              if($log[0] eq $value)
                {
                  $storeTo->(@log);
                  last;
                }
            }
          else
            {
              $storeTo->(@log);
            }
        }
    }
  $fin->close;

  return 1;
}

sub init
{
  ($storeTo,$split,$split2,$NUM_OF_IMAGES) = @_;
}


1;
