#!/usr/bin/perl
package Thumbnail::GD;
###########################################################
=pod

=head1 Create Smaller Image.

=cut
##########################################################
use strict;
use warnings;
use base qw/Exporter/;
our @EXPORT = qw/createSmallImage/;

use GD;
our $IMAGE_WIDTH = 0;

#Subroutines
#縮小画像の作成(GD::Image版)
sub createSmallImage
{
  my ($filename,$odir) = @_;
  $filename || return;

  #GD::Imageでサポートされる画像フォーマット
  my $imageType = do { $1 if($filename =~ /\.(jpe?g|png)$/i); } || return;

  my $destPath = "$odir/s";
  mkdir $destPath unless(-d $destPath);
  $destPath .= "/$filename";

  my $destW = $IMAGE_WIDTH * 2 || return;
  my $srcPath = "$odir/$filename";
  my $src = do
    {
      if($imageType =~ /png/i)
        {
          GD::Image->newFromPng($srcPath,1)
        }
      else
        {
          GD::Image->newFromJpeg($srcPath);
        }
    } || return;

  my ($w,$h) = ($src->width,$src->height);
  my $aspect = $h / $w;

  #縮小サイズの面積比2倍より小さい場合は縮小は行わない。
  return if($w < int($destW * 1.414));

  my $dest = GD::Image->newTrueColor($destW,int($destW * $aspect));
  $dest->copyResampled($src,
                       0,0,
                       0,0,
                       $dest->width,$dest->height,
                       $w,$h);

  my $fout = IO::File->new(">$destPath");
  $fout->binmode;
  $fout->print($imageType =~ /png/i ? $dest->png : $dest->jpeg(90));
  $fout->close;

  undef $src;
  undef $dest;
}

1;
