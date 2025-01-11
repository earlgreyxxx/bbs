#!/usr/bin/perl
package Thumbnail::ImageMagick;
###########################################################
=pod

=head1 Create Smaller Image.

=cut
##########################################################
use strict;
use warnings;
use base qw/Exporter/;
our @EXPORT = qw/createSmallImage/;

use Image::Magick;
our $IMAGE_WIDTH = 0;

#Subroutines
#縮小画像の作成(PerlMagick版)
sub createSmallImage
{
  my ($filename,$odir) = @_;
  $filename || return;

  #サポートされる画像フォーマット
  my $imageType = do { $1 if($filename =~ /\.(jpe?g|png)$/i); } || return;

  my $destPath = "$odir/s";
  mkdir $destPath unless(-d $destPath);
  $destPath .= "/$filename";

  my $destW = $IMAGE_WIDTH * 2 || return;
  my $srcPath = "$odir/$filename";
  my $src = do
    {
      my $img = Image::Magick->new;
      $img->Read($srcPath);

      $img;
    } || return;

  my ($w,$h) = $src->Get('width','height');
  my $aspect = $h / $w;

  #縮小サイズの面積比2倍より小さい場合は縮小は行わない。
  return if($w < int($destW * 1.414));

  my $dest = $src->Clone();
  $dest->Resize(geometry => sprintf('%dx%d',$destW,int($destW * $aspect)));
  $dest->Write($destPath);

  undef $src;
  undef $dest;
}
1;
