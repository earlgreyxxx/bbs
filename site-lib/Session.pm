#!/usr/bin/perl
###########################################################
=pod

=head1 HTTP SESSION subroutines.

セッションを扱う関数を定義します。

ex)
use Session;

Session::init(scriptname    => 'http://hoge.com/cgi/xxx/sss.cgi',
              datadir       => 'template',
              expire        => 3600,
              cookie_expire => 86400,
              sessiondir    => './tmp/session',
              sessionname   => 'sid');

=cut
##########################################################
package Session;
use 5.008;
use strict;
use warnings;
use Digest::SHA qw/sha1_hex/;
use Data::Dumper;
use IO::File;
use IO::Dir;
use base qw/Exporter/;

our @EXPORT = qw/session_start
                 session_end
                 session_value
                 session_delete_value
                 get_session
                 regenerate_session
                 validate_session
                 certified_session
                 uncertified_session/;

#version 
our $VERSION = '0.01';

our $SESSION_EXPIRE;
our $SESSION_COOKIE_EXPIRE;
my $DIR;
our $script_name;
our $sign_url;

my  $DIR_SESSION = './session';
my  $DEFAULT_SESSION_NAME = 'sid';

my $SESSION;
my $COOKIES;

sub init
{
  my %param = @_;

  $script_name = $param{scriptname} || '';
  $sign_url = $param{sign} || $script_name;
  $SESSION_EXPIRE = $param{expire} || 3600;
  $SESSION_COOKIE_EXPIRE = $param{cookie_expire} || 2592000;
  $DIR_SESSION = $param{sessiondir} if($param{sessiondir});
  $DEFAULT_SESSION_NAME = $param{sessionname} if($param{sessionname});
}

#セッションの開始
sub session_start
{
  my $dir = shift;
  my $cookie_name = shift || $DEFAULT_SESSION_NAME;
  my $id = get_session_cookie($cookie_name);

  $DIR = $dir;

  if($id)
  {
    if(-e "$DIR_SESSION/sess_$id")
    {
      my $data = read_session(undef,1);
      if( $data->{ctime} + $SESSION_EXPIRE < time )
      {
        $data->{session} = {};
        delete_session();
        session_redirect();
      }
      $SESSION = $data->{session};
    }
    else
    {
      delete_session_cookie();
      session_redirect();
    }
  }
  else
  {
    $id = write_session();
    set_session_cookie($id,$cookie_name,$SESSION_COOKIE_EXPIRE);
  }
}

#セッションの終了
sub session_end
{
  write_session($SESSION) if(ref $SESSION eq 'HASH');
}

#壊れているセッション＆期限切れのセッション復旧後の処理
sub session_redirect
{
  my $cookie_name = shift || $DEFAULT_SESSION_NAME;
  my $id = write_session();
  set_session_cookie($id,$cookie_name,$SESSION_COOKIE_EXPIRE);
}


#セッション認証照合
sub validate_session
{
  my $phrase = shift;

  my $rv = (ref $SESSION eq 'HASH') &&
           exists($SESSION->{$DIR}) &&
           exists($SESSION->{$DIR}->{admin}) &&
           ($SESSION->{$DIR}->{admin} eq sha1_hex($phrase));

  uncertified_session() unless($rv);

  return $rv;
}

#セッションに認証済みをマークする/外す
sub certified_session
{
  $SESSION->{$DIR} = {} unless(exists $SESSION->{$DIR});
  $SESSION->{$DIR}->{admin} = sha1_hex(shift);
}
sub uncertified_session
{
  delete $SESSION->{$DIR}->{admin};
}


#セッション再生成
sub regenerate_session
{
  my $cookie_name = shift || $DEFAULT_SESSION_NAME;
  my $newid = create_session_id();
  my $id = get_session_cookie($cookie_name);

  my $opath = "$DIR_SESSION/sess_$id";
  my $npath = "$DIR_SESSION/sess_$newid";

  set_session_cookie($newid,$cookie_name,$SESSION_COOKIE_EXPIRE) if(rename($opath,$npath));
}


#(1)セッションクッキーの取得・セット・削除
sub get_session_cookie
{
  my $name = shift || $DEFAULT_SESSION_NAME;

  unless($COOKIES)
    {
      $COOKIES = {};
      my $cookies = $ENV{HTTP_COOKIE} || '';
      foreach(split /; /,$cookies)
        {
          my ($n,$v) = split /=/;
          $n =~ tr/ \a\b\f\r\n\t//d;
          $COOKIES->{$n} = $v;
        }
    }
  return $COOKIES->{$name};
}

sub set_session_cookie
{
  my ($cvalue,$cname,$expires,$path,$domain,$secure) = @_;

  $cname = $DEFAULT_SESSION_NAME unless($cname);
  $cvalue = '' unless defined($cvalue);
  $expires = 0 unless($expires);

  map {
    s/([^ 0-9a-zA-Z])/"%".uc(unpack("H2",$1))/eg;
    s/ /+/g;
  }($cname,$cvalue);

  my @cookie = ("$cname=$cvalue");

  if($expires eq "-1")
  {
    push @cookie,'expires=Mon, 01-Jan-1990 00:00:00 GMT';
  }
  elsif($expires =~ /^\d+$/)
  {
    my @gmtime = split / +/, scalar gmtime(time + $expires);
    push @cookie,"expires=$gmtime[0], $gmtime[2]-$gmtime[1]-$gmtime[4] $gmtime[3] GMT";
  }
  elsif($expires)
  {
    push @cookie,"expires=$expires";
  }
  push @cookie,"domain=$domain" if($domain);
  push @cookie,"path=$path" if($path);
  push @cookie,"secure" if($secure);

  print 'Set-Cookie: ',join('; ',@cookie),"\n";
  $COOKIES->{$cname} = $cvalue;
}


sub delete_session_cookie
{
  my $cookie_name = shift;
  $cookie_name = $DEFAULT_SESSION_NAME unless($cookie_name);

  set_session_cookie(1,$cookie_name,-1);

  delete $COOKIES->{$cookie_name} if(exists $COOKIES->{$cookie_name});
}


sub create_session_id
{
  sha1_hex(join('!',time,rand,$$,));
}

sub delete_session
{
  #session file を削除する
  my $id = get_session_cookie(shift);
  my $session_path = "$DIR_SESSION/sess_$id";
  unlink $session_path if(-e $session_path);
  $SESSION = '';

  delete_session_cookie();
}

#session getter & setter
sub get_session
{
  return $SESSION;
}
sub set_session
{
  my $v = shift;
  $SESSION = defined($v) ? $v : '';
}

sub session_value
{
  my ($k,$v) = @_;
  $SESSION->{$DIR} = {} unless(exists $SESSION->{$DIR});
  return $SESSION->{$DIR}->{$k} unless defined($v);
  return $SESSION->{$DIR}->{$k} = $v;
}

sub session_delete_value
{
  my $k = shift;
  delete $SESSION->{$DIR}->{$k};
}

#(1)cookie name
sub read_session
{
  my ($cookie_name,$is_raw) = @_;
  my $session_id = get_session_cookie($cookie_name);
  return unless($session_id);

  my $data = do "$DIR_SESSION/sess_${session_id}";
  return $is_raw ? {ctime => time,session => {}} : {} unless(defined($data));

  return $is_raw ? $data : $data->{session};
}

#(1)cookie name
#(2)session hash reference
sub write_session
{
  my ($session,$cookie_name) = @_;
  my $id = get_session_cookie($cookie_name);

  $id = create_session_id() unless($id);
  $session = {} if(!$session || ref $session ne 'HASH');

  my $data = { session => $session, ctime => time };

  mkdir $DIR_SESSION unless(-d $DIR_SESSION);

  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 0;

  my $session_path = "$DIR_SESSION/sess_$id";
  my $fout = IO::File->new($session_path,'>') or die "can not open session file...";
  $fout->print(Dumper($data));
  $fout->close;

  $SESSION = $session;

  $id;
}

sub clean
{
  my $dir = IO::Dir->new($DIR_SESSION);
  foreach($dir->read)
  {
    my $path = "$DIR_SESSION/$_";
    next unless(-f $path);
    unlink $path if(-C $path >= 1);
  }

  $dir->close;
}

1;
