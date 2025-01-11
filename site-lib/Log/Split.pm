#!/usr/bin/perl
package Log::Split;
###########################################################
=pod

=head1 Log format is used text split data

=cut
##########################################################
use strict;
use warnings;
no warnings qw/uninitialized numeric/;
use base qw/Exporter/;
our @EXPORT = qw/parse writeLine getLogEx create_record/;
our @EXPORT_OK = qw/init inject/;

use IO::File;
use HTML::Entities qw/encode_entities_numeric/;

our ($NUM_OF_IMAGES,$split,$split2);
my ($L_KEY,$L_TITLE,$L_DATE,$L_BODY,$L_ATTR,$L_FILE,$L_DELETE,$L_OPTION_START);
our $storeTo = sub {};

# start position of attribute($L_ATTR) element only for compatibility.
my $A_HEADER = 5;
my $A_BODY = 5;
my $A_PUBLIC = 0;
my $A_NOTIFICATION = 1;
my $A_NTF_TO = 2;
my $A_OUTLINE = 3;
my $A_HEADLINE = 4;

# position of each attribute($L_ATTR) element.
my $A_DIRECT_LINK  = 0;
my $A_LAST_UPDATE  = 1;
my $A_REGIST_DATE  = 2;
my $A_CATEGORY     = 3;
my $A_RESERVE_DATE = 4;


my $A_ARTICLE_PUBLIC = 10;
my $A_ARTICLE_NOTIFY = 11;
my $A_ARTICLE_PERIOD = 12;
my $A_SHOW_OUTLINE = 13;
my $A_SHOW_HEADLINE = 14;

# position of image and attached file in file($L_FILE) element.
my $F_IMAGE = 0;
my $F_FILE = $NUM_OF_IMAGES;

# only for compatibility. (position of regist date time value after $L_KEY was splitten.
my $K_TIME = 4;

# flag of modification.
my $FG_MODIFY = 1;

# flag of registration.
my $FG_POST = 2;

#Subroutines
#arguments is array of string by splited with $split and $split2
sub parse
{
  no warnings qw/numeric/;
  my $items = do {
    my $line = shift || return {};

    if((my $what = ref $line) eq 'ARRAY')
      {
        $line;
      }
    elsif(!$what)
      {
        [ split(/$split/,$line) ];
      }
    else
      {
        die "invalid data type has given.";
      }
  };

  my $attrib = [split(/$split2/,$items->[$L_ATTR])];
  my $files = [split(/$split2/,$items->[$L_FILE])];
  my $images = [@$files[0 .. $NUM_OF_IMAGES - 1]];
  #添付ファイルの表示順を決定
  my $attached_ords = [];
  for(my $i=$NUM_OF_IMAGES;$i<$#$files;$i+=2)
    {
      push(@$attached_ords,$files->[$i]);
    }

  {
    items         => $items,
    key           => $items->[$L_KEY],
    title         => $items->[$L_TITLE],
    date          => $items->[$L_DATE],
    body          => $items->[$L_BODY],
    dkey          => $items->[$L_DELETE],
    options       => [ @$items[$L_OPTION_START .. $#$items] ],
    attrib        => $attrib,
    direct        => $attrib->[$A_DIRECT_LINK],
    registed      => int $attrib->[$A_REGIST_DATE],
    registdate    => (split /-/,$items->[$L_KEY])[$K_TIME],
    lastupdate    => 0 + $attrib->[$A_LAST_UPDATE],
    category      => 0 + $attrib->[$A_CATEGORY],
    reserve       => 0 + $attrib->[$A_RESERVE_DATE],
    public        => 0 + $attrib->[$A_ARTICLE_PUBLIC],
    notify        => 0 + $attrib->[$A_ARTICLE_NOTIFY],
    notify_to     => 0 + $attrib->[$A_ARTICLE_PERIOD],
    period        => 0 + $attrib->[$A_ARTICLE_PERIOD],
    outline       => 0 + $attrib->[$A_SHOW_OUTLINE],
    headline      => 0 + $attrib->[$A_SHOW_HEADLINE],
    files         => $files,
    images        => $images,
    image         => defined $images->[0] ? $images->[0] : '',
    attached_ords => $attached_ords,
    attached      => { @$files[$NUM_OF_IMAGES .. $#$files] }
  };
}

sub create_record
{
  my $items = shift;
  return if(ref $items ne 'HASH');

  my @attrib = ( $items->{direct},
                 $items->{lastupdate},
                 $items->{registed},
                 $items->{category},
                 $items->{reserve},
                 ('') x 5,
                 $items->{public},
                 $items->{notify},
                 $items->{notify_to},
                 $items->{outline},
                 $items->{headline} );
  my @files = ();
  push @files,@{$items->{images}};
  push @files,map { $_,$items->{attached}{$_} } @{$items->{attached_ords}};

  my @record = ();
  my @keys = ($L_KEY,$L_TITLE,$L_DATE,$L_BODY,$L_ATTR,$L_FILE,$L_DELETE);
  @record[@keys] = ( $items->{key} || getLUID(),
                     $items->{title} || '',
                     $items->{date} || '',
                     $items->{body} || '',
                     join($split2,@attrib),
                     join($split2,@files),
                     $items->{dkey} || '' );

  push @record,@{$items->{options}};

  my $conv = sub {
    my $s = shift;
    join '',map { sprintf('&#%d;',ord($_)); } split(//,$s);
  };

  foreach(@record)
    {
      s/($split)/&$conv($1)/eg;
    }

  return wantarray ? @record : join($split,@record);
}

sub writeLine
{
  my ($fout,$hlog,$key) = @_;
  $fout->print($hlog->{$key},"\n")
}

sub getLogEx
{
  my ($filename,$key,$subkey,$value) = @_;
  my $is_filter = ref($subkey) eq 'CODE';

  $key = 0 + $key;
  $subkey = (defined $subkey ?  0 + $subkey : -1) unless($is_filter);

  -e $filename || return 0;
  my $fin = IO::File->new($filename) || cgiOut(text('can not open file'));

  my $header = $fin->getline;
  $header =~ s/[\r\n]//g;
  my ($hkey,$hother) = split(/$split/,$header,2);
  $storeTo->($hkey,$header);

  while(defined(local $_ = $fin->getline))
    {
      s/[\r\n]//g;
      next if(/^\s*$/);

      my @log = split(/$split/,$_,2);

      if($is_filter || $subkey >= 0)
        {
          if($is_filter)
            {
              my $result = &$subkey($_);
              if($result)
                {
                  $storeTo->($log[$key],$_);
                  last if($result < 0);
                }
            }
          else
            {
              if($log[$subkey] eq $value)
                {
                  $storeTo->($log[$key],$_);
                  last if($subkey == 0);
                }
            }
        }
      else
        {
          $storeTo->($log[$key],$_);
        }
    }
  $fin->close;

  return 1;
}

sub init
{
  ($storeTo,$split,$split2,$NUM_OF_IMAGES) = @_;
}
sub inject
{
  ($L_KEY,
   $L_TITLE,
   $L_DATE,
   $L_BODY,
   $L_ATTR,
   $L_FILE,
   $L_DELETE,
   $L_OPTION_START) = @_;
}

1;
