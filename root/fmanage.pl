#!/usr/bin/perl
##############################################################################
#
#  CGI Script  require Perl 5.008 or heigher.
#
#  Written by K.Nakagawa, except 'jcode','stdio' and 'date' packages
#
#   This script uses 'jcode.pl' and 'stdio.pl' and 'date.pl'.
#   Very thanks to their writer!!!
##############################################################################
use strict;
use warnings;

use List::Util qw(first);

require 'fmanage.inc.pl';
our (%COOKIE,$DIR,$FDIR,$split,$split2,$DIR_DATA,$VDIR_DATA,%SESSION_PARAMS);
our ($CGI_SELF,$DIR_PASSWORD,$LOG_NAME,$DELETE_KEY,$LOCK_NAME);

initialize(2);

session_start($DIR);
main();
session_end();

sub main
{
  my $hform = FORM();
  no strict 'refs';

  #認証開始。クッキー必須
  my $out = <<__HTML__;
<p>@{[ text('session was timeout or authentication error has occured.' ) ]}</p>
<p><a href="sign.cgi?dir=$DIR" target="_top">@{[text('require re-authentication...')]}</a><p>
__HTML__

  fmanageOut($out) unless(validate_session($DIR_PASSWORD));

  #ここまで
  fmanageOut(text('can not open file')) unless(-e "$DIR_DATA/$FDIR/$LOG_NAME");
  fmanageOut(text('invalid cgi access')) unless($hform->{'ac'});

  #モード分岐
  &{*{'on'.ucfirst(exists $hform->{mode} && $hform->{mode} ? $hform->{mode} : 'show')}{CODE}} ($hform->{ac});
}


###################################################
# mode 指定なし
###################################################
sub onShow
{
  no strict 'refs';
  our ($DIR_ATTACHED,$ATTACHED_NAME);
  my $action = shift || '';
  my $hlog = LOG();
  my $hform = FORM();

  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $attacheddir = length($DIR_ATTACHED) > 0 ? $DIR_ATTACHED : "$DIR_DATA/$FDIR/$ATTACHED_NAME";

  fmanageOut(text('there is no index')) if(length $hform->{'key'} <= 0);
  getLogEx($datafile,0,0,$hform->{'key'}) || fmanageOut(text('can not open file'));

  fmanageOut(text('specified index value is unavailable')) unless(exists $hlog->{$hform->{'key'}});

  my %title = ( 'remove' => text('Remove attached files'),
                'rename' => text('Rename attached files'),
                'upload' => text('Upload attached files'),
                'image'  => text('Upload image files'),
                'done'   => text('Process was done') );

  $action = 'image' if($action eq 'imageremove');
  my $doit = *{'table_' . $action}{CODE} || fmanageOut(text('invalid arguments were given'));
  my $r = parse($hlog->{$hform->{'key'}});

  #ここから出力
  http_header();
  fmanage_start($title{$action});

  &$doit($r);

  fmanage_end();
}


#######################
#処理
#######################
sub onRun
{
  my $action = $_[0];
  my $numUpload = 0;
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $hlog = LOG();
  my $hform = FORM();

  my $key = $hform->{'key'};

  fmanageOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  fmanageOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  fmanageOut(text('specified index value is unavailable'),$LOCK_NAME) unless(exists $hlog->{$key});

  my $r = parse($hlog->{$key}); 
  my $public = $r->{'public'};
  my ($attacheddir) = get_attached_info($public);
  my $target = "$attacheddir/$hform->{'file'}";

  #ここにリネーム処理を書く。
  my $attached = $r->{'attached'};
  my $attached_ords = $r->{'attached_ords'};

  #削除キー認証スタート
  fmanageOut(text('delete key authentication was failed'),$LOCK_NAME) if($DELETE_KEY && !delete_auth($r->{dkey}));
  #認証ここまで

  if($action eq 'rename' || $action eq 'remove')
    {
      fmanageOut(text('attached file key not found'),$LOCK_NAME) unless($attached->{$hform->{'file'}});
    }

  #########################################
  if($action eq 'remove')
    {
      Run_Remove($hform->{'file'},$attacheddir,$attached,$attached_ords);
    }
  elsif($action eq 'rename')
    {
      fmanageOut(text('input was empty'),$LOCK_NAME) if(length($hform->{'ren'}) <= 0);
      fmanageOut(sprintf('%s<br><a href="javascript:history.back();">%s</a>',text('use only alphabet,number,under bar,hyphen and period'),text('click here and go back')),$LOCK_NAME) unless(checkFileName($hform->{'ren'}));
      Run_Rename($hform->{'file'},$hform->{'ren'},$attacheddir,$hform->{'desc'},$hform->{'chg'},$attached,$attached_ords);
    }
  elsif($action eq 'upload')
    {
      $numUpload = Run_Upload($attached,$attached_ords,$attacheddir);
    }
   else
     {
       fmanageOut(text('invalid arguments were given'),$LOCK_NAME);
     }
  #########################################
  #ここまで
  
  $hlog->{$key} = create_record($r);

  updateLog($datafile);
  stdio::unlock($LOCK_NAME);

  if($action eq 'upload' && $numUpload > 0)
    {
      redirect("$CGI_SELF?dir=$DIR&ac=done&key=$key");
    }
  else
    {
      redirect("$CGI_SELF?dir=$DIR&ac=$action&key=$key&success=1");
    }
}

#######################
#ファイルアップロード
#######################
sub Run_Upload
{
  my ($r_files,$r_ords,$odir) = @_;
  my $hform = FORM();
  my $at = 0 + $hform->{'at'};
  my $numUpload = 0;
  
  for(0 .. --$at)
    {
      if($hform->{"file_$_->name"})
        {
          my $a  = saveFile($hform,"file_$_",$odir,$_);
          my $an = $hform->{"file_name_$_"} ? $hform->{"file_name_$_"} : $a;
          $r_files->{$a} = $an;
          push(@$r_ords,$a);
          $numUpload++;
        }
    }

  return $numUpload;
}
#######################
#ファイル名変更
#######################
sub Run_Rename
{
  my ($from,$to,$dir,$dfrom,$dto,$fileset,$r_ords) = @_;

  my $renameFrom = "$dir/$from";
  my $renameTo = "$dir/$to";

  fmanageOut(text('file name was already used'),$LOCK_NAME) if(-e $renameTo && ($from ne $to));

  $fileset->{$from} = $dto if(length $dto > 0 && $dfrom ne $dto);

  return if($from eq $to);
  return if(length $to <= 0);

  my $pos = first { $r_ords->[$_] eq $from } (0 .. $#$r_ords);
  $r_ords->[$pos] = $to;

  rename($renameFrom,$renameTo);
  $fileset->{$to} = $fileset->{$from};

  delete $fileset->{$from};
}


#######################
#ファイル削除
#######################
sub Run_Remove
{
  my ($from,$dir,$fileset,$r_ords) = @_;
  my $remove = "$dir/$from";
  my @temp;

  my $pos = first { $r_ords->[$_] eq $from } (0 .. $#$r_ords);

  delete $fileset->{$from};
  unlink($remove);

  @temp = splice(@$r_ords,$pos);
  shift @temp;
  push(@$r_ords,@temp);
}

############################
#ファイル名のチェック。
#アルファベットのみ使用可
############################
sub checkFileName
{
  return ($_[0] =~ m/[^a-z0-9_\-\.]/i ? 0 : 1);
}

###########################
#エラー表示
###########################
sub fmanageOut
{
  our $debug_mode;
  my ($mesg,$lock) = @_;
  my ($hform,$aform) = FORMS();

  stdio::unlock($lock) if($lock);

  http_header();
  fmanage_start();

  print qq(<div class="error">$mesg</div>\n);

  if($debug_mode == 1)
    {
      print qq(<center>\n);
      foreach(@$aform)
        {
          print qq($_ => $hform->{$_}<br>\n);
        }
      print qq(</center>\n);
    }

  print qq(<p> </p>\n);
  fmanage_end();
  cgiExit();
}

1;
