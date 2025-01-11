#!/usr/bin/perl
package stdio;
;# <stdio.pl> CGI STandarD Input Output - Perl Library.
;#   Version 9.10 (Updated at Sep 10, 2006)
;#   Copyright(C)1998-2006 WEB POWER. All Rights Reserved.
;#   The latest programs are found at <http://www.webpower.jp/>

;$version     = 'stdio.pl/9.10fix';  # Version information about 'stdio.pl'.
;$max_byte    = 1048576 * 4;         # Maximum bytes to accept by multipart/form-data.
;$sendmail    = '/usr/lib/sendmail'; # Path of 'sendmail' program.
;$tmp_dir     = '/tmp/';             # Path of directory for temporary files. (chmod 777)
;$enc_key     = '';                  # Keyword for encrypt cookie data.
;$inet        = 2;                   # AF_INET (for Socket connection)
;$stream      = 1;                   # SOCK_STREAM (for Socket connection)
;$buffer_byte = 65536;

srand(time^($$+($$<<15))||time);
$version   = $version;

use Jcode;
use MIME::Base64;
use List::Util qw/shuffle/;

;# ============================
;# Set/Get Cookies.
;# ============================

sub setCookie #($r_cookie_body, $cookie_id, $expires, $path, $domain, $secure, $return_value, $encookey)
{
  my ($r_cookie_body, $cookie_id, $expires, $path, $domain, $secure, $return_value, $encookey) = @_;
  my $cookie;

  $encookey = $enc_key if ($encookey eq "" && $enc_key ne "");
  $cookie_id = $1 if ($cookie_id eq "" && $ENV{'SCRIPT_NAME'} =~ /([^\\\/]+)$/);
  &urlencode(\$cookie_id);
  if(ref $r_cookie_body eq 'SCALAR') {
    $cookie = $$r_cookie_body;
  } elsif(ref $r_cookie_body eq 'HASH') {
    my @cookie;
    while(my($key, $val) = each %$r_cookie_body) {
      push @cookie, &urlencode_($key) . "=" . &urlencode_($val);
    }
    $cookie = join "&", @cookie;
  } elsif (ref $r_cookie_body eq 'ARRAY') {
    my @cookie;
    foreach (@$r_cookie_body) {
      push @cookie, &urlencode_($_);
    }
    $cookie = join "&", @cookie;
  } elsif (defined $$r_cookie_body) {
    $cookie = $$r_cookie_body;
  }
  $cookie = encrypt($cookie, $encookey) if ($encookey ne "");
  if ($expires eq "-1") {
    $cookie .= '; expires=Mon, 01-Jan-1990 00:00:00 GMT';
  } elsif ($expires =~ /^\d+$/) {
    my @gmtime = split / +/, scalar gmtime(time + $expires);
    $cookie .= "; expires=$gmtime[0], $gmtime[2]-$gmtime[1]-$gmtime[4] $gmtime[3] GMT";
  } elsif ($expires) {
    $cookie .= "; expires=$expires";
  }
  $cookie .= "; domain=$domain" if ($domain);
  $cookie .= "; path=$path" if ($path);
  $cookie .= "; secure" if ($secure);
  return "$cookie_id=$cookie" if ($return_value && $cookie_id ne "" && $cookie ne "");
  print "Set-Cookie: $cookie_id=$cookie\n" if ($cookie_id ne "" && $cookie ne "");
  return;
}

sub getCookie #($r_cookie_body, $cookie_id, $encookey)
{
  my ($r_cookie_body, $cookie_id, $encookey) = @_;
  my @array;

  $encookey = $enc_key if ($encookey eq "" && $enc_key ne "");
  $cookie_id = $1 if ($cookie_id eq "" && $ENV{'SCRIPT_NAME'} =~ /([^\\\/]+)$/);
  &urlencode(*cookie_id);
  foreach (split /;/, $ENV{'HTTP_COOKIE'}) {
    my ($key, $val) = split /=/, $_, 2;
    $key =~ tr/ \a\b\f\r\n\t//d;
    if ($key eq $cookie_id) {
      if ($encookey ne "") {
        $val = decrypt($val, $encookey);
        return if ($val eq "");
      }
      foreach (split /&/, $val) {
        if (!/=/ && (ref $r_cookie_body eq 'ARRAY')) {
          push @$r_cookie_body, &urldecode_($_);
          @array = @$r_cookie_body
        } else {
          my($key, $val) = split /=/, $_, 2;
          &urldecode(\$key);
          $r_cookie_body->{$key} = &urldecode_($val);
          push @array, $key;
        }
      }
      return @array;
    }
  }
  return;
}

;# ============================
;# Get STDIN Data & Decode.
;# ============================

sub getFormData #(*IN, $tr_tags, $jcode, $multi_keys, $file_dir)
{
  return $ENV{'CONTENT_TYPE'} =~ /^multipart\/form-data;/i ? &getMultipartFormData(@_) : &getUrlencodedFormData(@_);
}

sub getUrlencodedFormData #(*IN, $tr_tags, $jcode, $multi_keys)
{
  my($r_IN, $tr_tags, $jcode, $multi_keys) = @_;
  my($buffer, @keys, $h2z);

  return if ($ENV{'CONTENT_LENGTH'} > 131072 || $ENV{'CONTENT_TYPE'} =~ /^multipart\/form-data;/i);
  if ($ENV{'REQUEST_METHOD'} eq 'POST') {
    read STDIN, $buffer, $ENV{'CONTENT_LENGTH'};
  } else {
    $buffer = $ENV{'QUERY_STRING'};
  }
  return if ($buffer eq "" || length $buffer > 131072);
  $h2z = $jcode =~ tr/A-Z/a-z/ ? "z" : "";
  foreach (split /[&;]/o, $buffer) {
    my($key, $val) = split /=/, $_, 2;
    &urldecode(\$key);
    &urldecode(\$val);
    if ($jcode && $Jcode::version) {
      Jcode::convert(\$key, $jcode, "", $h2z);
      Jcode::convert(\$val, $jcode, "", $h2z);
    }
    $key =~ s/\x0d\x0a|\x0d|\x0a/\n/g;
    $key =~ tr/\t\a\b\e\f\0//d;
    $val =~ s/\x0d\x0a|\x0d|\x0a/\n/g;
    $val =~ tr/\t\a\b\e\f\0//d;
    if ($tr_tags) {
      &trString(\$key, 1);
      &trString(\$val, 1);
      if ($tr_tags == 2) {
        $key =~ s/\n/<br \/>/g;
        $val =~ s/\n/<br \/>/g;
      }
      elsif($tr_tags == 3) {
        $key =~ s/\n//g;
        $val =~ s/\n//g;
      }
    }
    if ($multi_keys ne "") {
      $r_IN->{$key} .= defined $r_IN->{$key} ? "$multi_keys$val" : $val;
    } else {
      $r_IN->{$key} = $val;
    }
    push @keys, $key;
  }
  return @keys;
}

sub getMultipartFormData #(*IN, $tr_tags, $jcode, $multi_keys, $file_dir)
{
  my($r_IN, $tr_tags, $jcode, $multi_keys, $file_dir) = @_;
  my(@keys, $boundary, $key, $val, $buf1, $buf2, $buf3, $len, $path, $flag, $file, $text, $type, $open, $h2z, $i);

  return if ($ENV{'CONTENT_LENGTH'} > $max_byte || $ENV{'CONTENT_TYPE'} !~ /^multipart\/form-data; *boundary=(.+)/);
  $boundary = $1;
  $file_dir =~ s/^\/\/\//$tmp_dir/;
  $h2z = $jcode =~ tr/A-Z/a-z/ ? "z" : "";
  binmode STDIN;

 out:
  while (read STDIN, $buf1, $buffer_byte) {
    local($offset, $start) = 0;
    $buf1 .= getc STDIN if (substr($buf1, -1, 1) eq "\x0d");
    while (1) {
      my($pos, $buf);
      $pos = index $buf1, "\x0d\x0a", $start;
      if ($pos == -1) {
        last if (length($buf1) == $offset);
        $buf   = !$offset ? $buf1 : substr $buf1, $offset, (length($buf1) - $offset);
        $offset= length $buf1;
      } else {
        $start = $pos + 2;
        $buf   = substr $buf1, $offset, $start - $offset;
        $offset= $start;
      }
      $buf = $buf2 . $buf if ($buf2 ne "");
      undef $buf2;
      if (substr($buf, -2, 2) ne "\x0d\x0a") {
        if ($open && $flag == 2 && length($buf) > length($boundary) + 8) {
          if ($buf3 ne "") {
            print OUT $buf3;
            undef $buf3;
          }
          print OUT $buf;
        } else {
          $buf2 = $buf;
        }
        next;
      }
      if ($flag == 2) {
        if (index($buf, "--$boundary") == 0) {
          Jcode::convert(\$key, $jcode, "", $h2z) if ($jcode && $Jcode::version);
          $key =~ s/\x0d\x0a|\x0d|\x0a/\n/g;
          $key =~ tr/\t\a\b\e\f\0//d;
          if ($tr_tags) {
            &trString(*key, 1);
            if ($tr_tags == 2) {
                $key =~ s/\n/<br \/>/g
              }
            elsif($tr_tags == 3) {
                $key =~ s/\n//g;
              }
          }
          push @keys, $key;
          if ($text) {
            Jcode::convert(\$val, $jcode, "", $h2z) if ($jcode && $Jcode::version);
            $val =~ s/\x0d\x0a$//;
            $val =~ s/\x0d\x0a|\x0d|\x0a/\n/g;
            $val =~ tr/\t\a\b\e\f\0//d;
            if ($tr_tags) {
              &trString(\$val, 1);
              if ($tr_tags == 2) {
                $val =~ s/\n/<br \/>/g ;
              }
              elsif($tr_tags == 3) {
                $val =~ s/\n//g;
              }
            }
            if ($multi_keys ne "") {
              $r_IN->{$key} .= defined $r_IN->{$key} ? "$multi_keys$val" : $val;
            } else {
              $r_IN->{$key} = $val;
            }
          } else {
            if ($open) {
              $buf3 =~ s/\x0d\x0a$//;
              print OUT $buf3;
              close OUT;
              $r_IN->{"$key->size"} = (-s $file);
              $r_IN->{$key} = $file;
            } else {
              $val =~ s/\x0d\x0a$//;
              $r_IN->{$key} = $val;
              $r_IN->{"$key->size"} = length $val;
            }
            Jcode::convert(\$path, $jcode, "", $h2z) if ($jcode && $Jcode::version);
            $r_IN->{"$key->path"} = $path;
            $r_IN->{"$key->name"} = $1 if ($path =~ /([^\\\/]+)$/);
            $r_IN->{"$key->type"} = $type;
          }
          $len += length $key + length $val;
          ($text, $type, $flag, $path, $open, $file, $key, $val, $buf3) = undef;
          last out if ($buf =~ /--\x0d\x0a$/ || $len > 131072);
        } elsif ($open) {
          print OUT $buf3 if ($buf3 ne "");
          $buf3 = $buf;
        } else {
          $val .= $buf;
          last out if (length $val > 131072);
        }
      } elsif ($flag && !$text && $buf =~ /^Content-Type: *([^\s]+)/i) {
        $type = $1;
      } elsif ($flag && $buf eq "\x0d\x0a") {
        $flag = 2;
      } elsif ($buf =~ /^Content-Disposition: *([^;]*); *name="([^"]*)"; *filename="([^"]*)"/i) {
        $key  = $2;
        $path = $3;
        $flag = 1;
        if ($path ne "" && $file_dir ne "") {
          if ($r_IN->{$key} eq "") {
            $i ++;
            $file = sprintf "$file_dir%d-$i.tmp", $$+time;
          } else {
            $file = $r_IN->{$key};
          }
          if (open OUT, ">$file") {
            binmode OUT;
            push @file, $file;
            $open = 1;
          }
        }
      } elsif ($buf =~ /^Content-Disposition: *([^;]*); *name="([^;]*)"/i) {
        $key  = $2;
        $flag = 1;
        $text = 1;
      }
    }
  }
  return @keys;
}



;# ============================
;# Encode / Decode.
;# ============================
sub base64encode #(*data, $ins_lf)
{
  my ($r_data, $ins_lf) = @_;
  $$r_data = encode_base64($$r_data,'');
}

sub base64decode #(*data)
{
  my $r_data = shift;
  $$r_data = decode_base64($$r_data);
}

sub urlencode_ #($data)
{
  my $data = shift;

  &urlencode(\$data);
  return $data;
}

sub urlencode #(*data)
{
  my $r_data = shift;

  $$r_data =~ s/([^\w\-.* ])/sprintf('%%%02x', ord $1)/eg;
  $$r_data =~ tr/ /+/;
}

sub urldecode_ #($data)
{
  my $data = shift;

  &urldecode(\$data);
  return $data;
}

sub urldecode #(*data)
{
  my $r_data = shift;

  $$r_data =~ tr/+/ /;
  $$r_data =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex $1)/eg;
}

;# ============================
;# Encrypt / Decrypt
;# ============================

sub encrypt #($str, $key)
{
  my ($str, $key) = @_;
  my (@key, @code, $base, $check_digit, $data, $length, $table, $i);

  return if ($key eq "" || $str eq "");
  @code = split //, $str;
  for ($i = 0; $i <= $#code; $i++) {
    my ($code1, $code2);
    $code1 = ord($code[$i]);
    $code2 = $i != $#code ? ord($code[$i+1]) : $code[0];
    $check_digit += int(($code1*$code2)*($i+1) / ($code1+$code2)) + int(($code1*$code2)*($i+1) % ($code1+$code2));
  }
  $str .= sprintf "%08X:-p)", $check_digit;
  $str = feistelCipher($str, $key);
  $table = getHashTable($key);
  $str .= "\t\b\0" if (length($str) % 2);
  $str =~ s/[\x00-\xff]/sprintf("%03o", ord($&))/ges;
  $str =~ s/../$$table{$&}/g;
  return $str;
}

sub decrypt #($str, $key)
{

  my ($str, $key) = @_;
  my (@code, $check_digit1, $check_digit2, $data, $length, $table, $i);

  return if ($key eq "" || $str eq "");
  $table = getHashTable($key);
  $str =~ tr/A-Za-z0-9_.//cd;
  $str =~ s/./$$table{$&}/g;
  $str =~ s/.../pack('C*', oct $&)/ge;
  $str =~ s/\t\b\0$//;
  $str = feistelCipher($str, $key, 1);
  $str =~ s/\0$//;
  $check_digit1 = hex(substr $str, -12, 8);
  $str = substr $str, 0, length($str)-12;
  @code = split //, $str;
  for ($i = 0; $i <= $#code; $i++) {
    local($code1, $code2);
    $code1 = ord($code[$i]);
    $code2 = $i != $#code ? ord($code[$i+1]) : $code[0];
    $check_digit2 += int(($code1*$code2)*($i+1) / ($code1+$code2)) + int(($code1*$code2)*($i+1) % ($code1+$code2));
  }
  return if ($check_digit1 != $check_digit2);
  return $str;
}


sub feistelCipher #($str, $key, $rev)
{
  my($str, $key, $rev) = @_;
  my(@sub_keys, @str, $i, $rounds, $salt, $str_len, $str_mod);

  $rounds = 16;
  $str .= "\0" if (!$rev && length($str) % 2);
  $str[0] = substr $str, 0, length($str) / 2;
  $str[1] = substr $str, length($str) / 2;
  $sub_keys[0] =  crypt($key, substr($key, -2));
  $sub_keys[0] =~ s/^(\$1\$..\$|..)//;
  $salt = substr $sub_keys[0], -2;
  $sub_keys[0] = substr $sub_keys[0], 0, 9;
  for ($i = 0; $i < $rounds-1; $i ++) {
    $sub_keys[$i+1] =  crypt($sub_keys[$i], $salt);
    $sub_keys[$i+1] =~ s/^(\$1\$..\$|..)//;
    $salt = substr $sub_keys[$i+1], -2;
    $sub_keys[$i+1] = substr $sub_keys[$i+1], 0, 9;
  }
  $str_len = length $str[0];
  $str_mod = $str_len % 8;
  @sub_keys = reverse @sub_keys if ($rev);
  for ($i = 0; $i < $rounds; $i ++) {
    my($seed, $mod, $ral, $j);
    $ral = $i % 2;
    $seed = $ral == 0 ? $str[1] : $str[0];
    $mod  = $str_len % 9;
    $seed =~ s/[\x00-\xff]{9}/"$&" & substr($sub_keys[$i], $j++*9 % 9, 9) ^ "$&" | $sub_keys[$i]/ges;
    $seed =~ s/[\x00-\xff]{$mod}$/"$&" & substr($sub_keys[$i], 0, $mod) ^ "$&" | $sub_keys[$i]/ges if ($mod);
    $seed = ~$seed;
    $seed = substr $seed, 0, $str_len;
    $j = 0;
    $str[$ral] =~ s/[\x00-\xff]{8}/"$&" ^ substr($seed, $j++*8, 8)/ges;
    if ($str_mod) {
      my $strl = substr($str[$ral], -$str_mod);
      $str[$ral] = substr($str[$ral], 0, $j*8);
      $str[$ral] .= "$strl" ^ substr($seed, $j*8) ;
    }
  }
  return $str[1] . $str[0];
}

sub getHashTable #($key)
{
  my $key = shift;
  my (@list, @seed, %table, $seed, $key_len, $i, $j, $k);

  # You must shuffle following characters randomly before use this encrypt/decrypt function.
  $seed = '7zKxb9jGFhCfIEOkcnLW2B.DwiSHysT8dQo0VJmMR1ltqU5pv6N3YgZ_PXuaer4A';
  $key = crypt($key, substr($seed, 0, 2));
  $key =~ s/^(\$1\$..\$|..)//;
  @seed = split //, $seed;
  $key_len = length $key;
  for ($i = 0; $i < 64; $i ++) {
    my $code = ord(substr($key, $i % $key_len, 1));
    $list[$i] = splice(@seed, (($code + $key_len) % (64 - $i)), 1);
  }

  for ($i = 0; $i < 8; $i ++) {
    for ($j = 0; $j < 8; $j ++){
      $table{"$i$j"} = $list[$k];
      $table{$list[$k++]} = "$i$j";
    }
  }
  return \%table;
}

;# ============================
;# Transfer String.
;# ============================

sub trString_ #($str, $html, $lc, $z2h, $k2h, $rmstr)
{
  my $str = shift;

  &trString(\$str, @_);
  return $str;
}

sub trString #(*str, $html, $lc, $z2h, $k2h, $rmstr)
{
  my ($r_str, $html, $lc, $z2h, $k2h, $rmstr) = @_;

  if ($html) {
    if ($html == 2) {
      $$r_str =~ s/&gt;/>/g;
      $$r_str =~ s/&lt;/</g;
      $$r_str =~ s/&quot;/"/g;
      $$r_str =~ s/&amp;/&/g;
    } else {
      $$r_str =~ s/&/&amp;/g;
      $$r_str =~ s/"/&quot;/g;
      $$r_str =~ s/</&lt;/g;
      $$r_str =~ s/>/&gt;/g;
    }
  }
  if ($Jcode::version) {
    my ($from, $to);
    if ($k2h) {
      $from = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポゐゑァィゥェォャュョッ';
      $to   = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽヰヱぁぃぅぇぉゃゅょっ';
      if ($k2h == 2) {
        my $tmp_var = $to;
        $to = $from;
        $from = $tmp_var;
      }
    }
    if ($z2h) {
      $from .= '０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ＋＝／＾～＿｜＊！？”＃＄￥％＆＠：；　－';
      $to   .= '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+=/^~_|*!?"#$\%&@:; -';
      if ($z2h == 2) {
        my $tmp_var = $to;
        $to = $from;
        $from = $tmp_var;
      }
    }
    if ($rmstr) {
      $from .= $rmstr;
      $to   .= "\a";
    }
    if ($from ne "" && $to ne "") {
      Jcode::tr($r_str, $from, $to);
      $$r_str =~ tr/\a//d if ($rmstr);
    }
  }
  if ($lc) {
    if ($lc == 2) {
      $$r_str =~ tr/a-z/A-Z/;
    } else {
      $$r_str =~ tr/A-Z/a-z/;
    }
  }
}


;# ============================
;# Make Random String.
;# ============================

sub getRandomString #($len, $str)
{
  my ($len, $str) = @_;
  my @str = shuffle($str ? split //, $str : ('A'..'Z','a'..'z','0'..'9'));

  return join '',@str[1 .. $len];
}

;# ============================
;# Set Link.
;# ============================

sub setLink_ #($str, $attribute, $uri_str, $mail_str, $redirect_uri)
{
  my $str = shift;

  &setLink(\$str, @_);
  return $str;
}

sub setLink #(*str, $attribute, $uri_str, $mail_str, $redirect_uri)
{
  my ($r_str, $attribute, $uri_str, $mail_str, $redirect_uri) = @_;
  my ($element, $new_str);

  $attribute = " $attribute" if ($attribute ne "");
  foreach (split /(<[^>]*>)/, $$r_str) {
    if (/^<(a|button|textarea|script|head)/i) {
        $element = $1;
    } elsif ($element && /^<\/$element/) {
        $element = "";
    } elsif (!$element && ! /^</) {
      tr/\a//d;
      s/&amp;/\a/g;
      if ($uri_str ne "") {
        if ($redirect_uri) {
          s/((view-source:)?(https?|ftp|gopher|telnet|news|wais|nntp|rtsp|mms):\/\/[-+:.@\w]{4,64}(\/[-.?+:;!#%=@~^\$\a\w\/\[\]]{0,256})?)/qq|<a href="$redirect_uri| . urlencode_($1) . qq|"$attribute>$uri_str<\/a>|/eg;
        } else {
          s/((view-source:)?(https?|ftp|gopher|telnet|news|wais|nntp|rtsp|mms):\/\/[-+:.@\w]{4,64}(\/[-.?+:;!#%=@~^\$\a\w\/\[\]]{0,256})?)/<a href=\"$1\"$attribute>$uri_str<\/a>/g;
        }
      } else {
        if ($redirect_uri) {
          s/((view-source:)?(https?|ftp|gopher|telnet|news|wais|nntp|rtsp|mms):\/\/[-+:.@\w]{4,64}(\/[-.?+:;!#%=@~^\$\a\w\/\[\]]{0,256})?)/qq|<a href="$redirect_uri| . urlencode_($1) . qq|"$attribute>$1<\/a>|/eg;
        } else {
          s/((view-source:)?(https?|ftp|gopher|telnet|news|wais|nntp|rtsp|mms):\/\/[-+:.@\w]{4,64}(\/[-.?+:;!#%=@~^\$\a\w\/\[\]]{0,256})?)/<a href=\"$1\"$attribute>$1<\/a>/g;
        }
      }
      if ($mail_str ne "") {
        s/(mailto:[-+!#$%&'*\/~^|`{}.\w]{1,32}@[-.\w]*[-A-Za-z0-9]{2,32}\.[A-Za-z]{1,6}(\?[-.?+:;!#%=@~^\$\a\w\/\[\]]{0,256})?)\b/<a href="$1">$mail_str<\/a>/g;
      } else {
        s/(mailto:[-+!#$%&'*\/~^|`{}.\w]{1,32}@[-.\w]*[-A-Za-z0-9]{2,32}\.[A-Za-z]{1,6})(\?[-.?+:;!#%=@~^\$\a\w\/\[\]]{0,256})?\b/<a href="$1$2">$1<\/a>/g;
      }
      s/\a/&amp;/g;
    }
    $new_str .= $_;
  }
  $$r_str = $new_str;
}

;# ============================
;# Set Comma per 3 figures.
;# ============================

sub setComma #($str)
{
  my $str = shift;

  if ($str =~ /^(-?)([\dA-Fa-f]+)(\..*)?$/) {
    my($mns, $str, $dot) = ($1, $2, $3);
    1 while $str =~ s/([\dA-Fa-f]+)([\dA-Fa-f]{3})/$1,$2/;
    return "$mns$str$dot";
  }
  return $str;
}

;# ============================
;# Lock Check / Lock / Unlock
;# ============================

sub lock #($lock_dir, $retry, $sleep)
{
  my ($lock_dir, $retry, $sleep) = @_;
  my ($lock_dir2, $i);

  $lock_dir.= ".lock";
  $lock_dir =~ s/^\/\/\//$tmp_dir/;
  $lock_dir2 = $lock_dir . "2";
  $retry = 3 if (!$retry);
  $sleep = 1 if (!$sleep);
  $i = 0;
  if ((-M $lock_dir) * 86400 > 180) {
    rmdir $lock_dir;
    rmdir $lock_dir2;
  }
  while(!mkdir $lock_dir, 0755) {
    sleep $sleep;
    if (++ $i >= $retry) {
      if (mkdir $lock_dir2, 0755) {
        if ((-M $lock_dir) * 86400 > 60) {
          return 1 if (rename $lock_dir2, $lock_dir);
        }
        rmdir $lock_dir2;
        return 0;
      }
      if ((-M $lock_dir2) * 86400 > 30) {
        if ((-M $lock_dir) * 86400 > 60) {
          return 1 if (rename $lock_dir2, $lock_dir);
        }
        rmdir $lock_dir2;
      }
      return 0;
    }
  }
  return 1;
}

sub unlock #($lock_dir)
{
  my $lock_dir = "$_[0].lock";

  $lock_dir =~ s/^\/\/\//$tmp_dir/;
  return rmdir $lock_dir if (-d $lock_dir);
}

sub lockCheck #($lock_dir, $retry, $sleep)
{
  my ($lock_dir, $retry, $sleep) = @_;
  my ($lock_dir2, $i);

  $lock_dir.= ".lock";
  $lock_dir =~ s/^\/\/\//$tmp_dir/;
  $lock_dir2 = $lock_dir . "2";
  $retry = 3 if (!$retry);
  $sleep = 1 if (!$sleep);
  $i = 0;
  return 1 if ((-M $lock_dir) * 86400 > 60);
  while (-d $lock_dir) {
    sleep $sleep;
    return 0 if (++ $i >= $retry);
  }
  return 1;
}

;# ============================
;# Send Email.
;# ============================

sub sendmail #(*header, $body, $html_body, $mime_encode, @attachments)
{
  my ($r_header, $body, $html_body, $mime_encode, @attachments) = @_;
  local($boundary, $text);

  return 0 if (!open ML, "| $sendmail -t -i");
  while (($key, $val) = each %$r_header) {
    my $val2;
    next if ($val =~ /^\s*$/);
    $val =~ tr/\x0d\x0a//d;
    foreach (split /( +|\")/, $val) {
      if (/[^\x20-\x7e]/) {
        Jcode::convert(\$_, 'jis') if ($Jcode::version);
        &base64encode(\$_);
        $val2 .= "=?ISO-2022-JP?B?$_?=";
      } else {
        $val2 .= $_;
      }
    }
    $val = $val2;
    print ML "$key: $val\n";
  }
  if (@attachments) {
    $boundary = '===' . time . $$ . time . '===';
    print ML "Content-Type: multipart/mixed;\n" . qq(\tboundary="$boundary"\n\n) . "This is a multipart message in MIME format.\n\n" . "--$boundary\n";
  } elsif ($body && $html_body) {
    $boundary = '===' . time . $$ . time . '===';
    print ML "Content-Type: multipart/alternative;\n" . qq(\tboundary="$boundary"\n\n) . "This is a multipart message in MIME format.\n\n" . "--$boundary\n";
  }
  $text = !$body && $html_body ? 'html' : 'plain';
  $body = $html_body if ($text eq "html");
  Jcode::convert(\$body, 'jis') if ($Jcode::version);
  print ML "Content-Type: text/$text" . qq(; charset="ISO-2022-JP"\n) . "Content-Transfer-Encoding: 7bit\n\n" . "$body\n";
  if ($text eq "plain" && $html_body) {
    print ML "--$boundary\n" . qq(Content-Type: text/html; charset="ISO-2022-JP"\n) . "Content-Transfer-Encoding: 7bit\n\n";
    Jcode::convert(\$html_body, 'jis') if ($Jcode::version);
    print ML "$html_body\n";
    print ML "--$boundary--\n" if (!@attachments);
  }
  if (@attachments) {
    foreach $file (@attachments) {
      my($file, $type, $name, $encode) = split / *; */, $file;
      my($cache_file, $command);
      $name = (!$name && $file =~ /([^\/]+$)/) ? $1 : $name;
      $type = &getMimeType($file) if (!$type);
      Jcode::convert(\$name, 'jis') if ($Jcode::version);
      $name = "=?ISO-2022-JP?B?" . encode_base64($name,'') . "?=" if ($name =~ /[^\w\-\[\]\(\).]/);
      $encode = $mime_encode if ($encode eq "");
      ($encode, $command) = split / +/, $encode;
      if ($command eq "cache") {
        my $suffix = $encode =~ /^uu(encode)?$/ ? "uu.cache" : "b64.cache";
        $cache_file = encode_base64($file,'');
        $cache_file =~ tr/+\//-_/;
        $cache_file = "$tmp_dir$cache_file.$suffix";
        if (-r $cache_file) {
          $file = $cache_file;
          $command = "encoded";
        }
      }
      if ($command eq "encoded") {
        if (open IN, $file) {
          my $buffer;
          binmode IN;
          print ML "--$boundary\n" . qq(Content-Type: $type; name="$name"\n);
          if ($encode =~ /^uu(encode)?$/i) {
            print ML "Content-Transfer-Encoding: X-uuencode\n" . qq(Content-Disposition: attachment; filename="$name"\n\n);
          } else {
            print ML "Content-Transfer-Encoding: Base64\n" . qq(Content-Disposition: attachment; filename="$name"\n\n);
          }
          print ML $buffer while (read IN, $buffer, $buffer_byte);
          close IN;
          print ML "\n";
        }
      } elsif (open IN, $file) {
        my $file_size = (-s $file);
        if ($cache_file && open CC, ">$cache_file") {
          binmode CC;
        } else {
          $cache_file = "";
        }
        binmode IN;
        print ML "--$boundary\n" . qq(Content-Type: $type; name="$name"\n);
        if ($encode =~ /^uu(encode)?$/i) {
          my ($read, $buffer);
          print ML "Content-Transfer-Encoding: X-uuencode\n" . qq(Content-Disposition: attachment; filename="$name"\n\n) . "begin 666 $name\n";
          print CC "begin 666 $name\n" if ($cache_file);
          while ($read = read IN, $buffer, 1035) {
            my $data;
            while ($buffer =~ s/^((.|\n|\r){45})//) {
              $data .= pack("u", $&);
            }
            if ($read == 1035) {
              print ML $data;
              print CC $data if ($cache_file);
              next;
            }
            print ML $data;
            print ML pack("u", $buffer) if ($buffer ne "");
            if ($cache_file) {
              print CC $data;
              print CC pack("u", $buffer) if ($buffer ne "");
            }
          }
          print ML "`\n" . "end\n";
          print CC "`\n" . "end\n" if ($cache_file);
        } else {
          my ($base, $read, $buffer, $j);
          $base = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
          $j = 1;
          print ML "Content-Transfer-Encoding: Base64\n" . qq(Content-Disposition: attachment; filename="$name"\n\n);
          while ($read = read IN, $buffer, 1026) {
            my ($data, $length, $i);
            $i = $length = 0;
            $buffer = unpack "B*", $buffer;
            while ($length = substr($buffer, $i, 6)) {
              $data .= substr($base, ord pack("B*", "00".$length), 1);
              if ($read != 1026 || tell(IN) == $file_size) {
                if (length $length == 2) {
                  $data .= "==";
                } elsif (length $length == 4) {
                  $data .= "=";
                }
              }
              $data .= "\n" if ($j++ % 76 == 0);
              $i += 6;
            }
            print ML $data;
            print CC $data if ($cache_file);
          }
        }
        close CC if ($cache_file);
        close IN;
        print ML "\n";
      }
    }
    print ML "--$boundary--\n";
  }
  close ML;
  return 1;
}

sub removeCacheFiles #(@attachments)
{
  my @attachments = @_;

  foreach (@attachments) {
    my $cache_file = encode_base64($_);
    $cache_file =~ tr/+\//-_/;
    unlink "$tmp_dir$cache_file.b64.cache" if (-f "$tmp_dir$cache_file.b64.cache");
    unlink "$tmp_dir$cache_file.uu.cache" if (-f "$tmp_dir$cache_file.uu.cache");
  }
}

;# ============================
;# Get Image Pixel Size.
;# ============================

sub getImageSize #($file_name)
{
  my $file_name = shift;
  my $head;

  return if (!open IN, $file_name);
  binmode IN;
  read IN, $head, 8;
  if ($head eq "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a") {
    my ($width, $height);
    if (read(IN, $head, 4) != 4 || read(IN, $head, 4) != 4 || $head ne 'IHDR') {
      close IN;
      return "PNG", 0;
    }
    read IN, $head, 8;
    close IN;
    $width = unpack "N", substr($head, 0, 4);
    $height = unpack "N", substr($head, 4, 4);
    return "PNG", $width, $height;
  }
  $head = substr $head, 0, 3;
  if ($head eq "\x47\x49\x46") {
    my ($head, $width, $height);
    seek IN, 6, 0;
    read IN, $head, 4;
    close IN;
    ($width, $height) = unpack "vv", $head;
    return "GIF", $width, $height;
  }
  $head = substr $head, 0, 2;
  if ($head eq "\xff\xd8") {
    my ($head, $width, $height, $w1, $w2, $h1, $h2, $l1, $l2, $length);
    seek IN, 2, 0;
    while (read IN, $head, 1) {
      last if ($head eq "");
      if ($head eq "\xff") {
        $head = getc IN;
        if ($head =~ /^[\xc0-\xc3\xc5-\xcf]$/) {
          seek IN, 3, 1;
          last if (read(IN, $head, 4) != 4);
          close IN;
          ($h1, $h2, $w1, $w2) = unpack "C4", $head;
          $height = $h1 * 256 + $h2;
          $width  = $w1 * 256 + $w2;
          return "JPG", $width, $height;
        } elsif ($head eq "\xd9" || $head eq "\xda") {
          last;
        } else {
          last if (read(IN, $head, 2) != 2);
          ($l1, $l2) = unpack "CC", $head;
          $length = $l1 * 256 + $l2;
          seek IN, $length - 2, 1;
        }
      }
    }
    close IN;
    return "JPG", 0;
  }
  close IN;
  return 0;
}

;# ============================
;# Get MIME Type.
;# ============================

sub getMimeType #($file_name)
{
  my $file_name = shift;
  my %mime_type = (
    'asc'   => 'text/plain',    'css'   => 'text/css',      'csv'   => 'text/plain',    'hdml'  => 'text/x-hdml',
    'htm'   => 'text/html',     'html'  => 'text/html',     'mld'   => 'text/plain',    'rtf'   => 'text/rtf',
    'rtx'   => 'text/richtext', 'stm'   => 'text/html',     'shtml' => 'text/html',     'txt'   => 'text/plain',
    'vcf'   => 'text/x-vcard',  'xml'   => 'text/xml',      'xsl'   => 'text/xsl',      'xul'   => 'text/xul',

    'bmp'   => 'image/bmp',     'gif'   => 'image/gif',     'ico'   => 'image/x-icon',  'jpeg'  => 'image/jpeg',
    'jpg'   => 'image/jpeg',    'png'   => 'image/png',     'tif'   => 'image/tiff',    'tiff'  => 'image/tiff',

    'au'    => 'audio/basic',   'es'    => 'audio/echospeech',                          'esl'   => 'audio/echospeech',
    'm3u'   => 'audio/x-mpegurl',                           'midi'  => 'audio/midi',    'mid'   => 'addio/midi',
    'mp2'   => 'audio/mpeg',    'mp3'   => 'audio/mpeg',    'qcp'   => 'audio/vnd.qcelp',
    'rpm'   => 'audio/x-pn-RealAudio-plugin',               'smd'   => 'audio/x-smd',   'wav'   => 'audio/x-wav',
    'wma'   => 'audio/x-ms-wma',

    '3gp'   => 'video/3gpp',    '3gp2'  => 'video/3gpp2',   'asf'   => 'video/x-ms-asf','amc'   => 'application/x-mpeg',
    'avi'   => 'video/msvideo', 'mmf'   => 'application/x-smaf',                        'mov'   => 'video/quicktime',
    'mp4'   => 'video/mp4',     'mpg'   => 'video/mpeg',    'mpeg'  => 'video/mpeg',    'mpg4'  => 'video/mp4',
    'qt'    => 'video/quicktime',                           'vdo'   => 'video/vdo',     'viv'   => 'video/vivo',
    'vivo'  => 'video/vivo',    'wmv'   => 'video/x-ms-wmv','wvx'   => 'video/x-ms-wvx',

    'doc'   => 'application/msword',                        'gz'    => 'application/x-gzip',
    'hlp'   => 'application/winhlp',                        'js'    => 'application/x-javascript',
    'lha'   => 'application/x-lzh',                         'lzh'   => 'application/x-lzh',
    'pdf'   => 'application/pdf',                           'ppt'   => 'application/vnd.ms-powerpoint',
    'pmd'   => 'application/x-pmd',                         'sea'   => 'application/x-stuffit',
    'sh'    => 'application/x-sh',                          'sit'   => 'application/x-stuffit',
    'swf'   => 'application/x-shockwave-flash',             'tar'   => 'application/x-tar',
    'taz'   => 'application/x-tar',                         'tgz'   => 'application/x-tar',
    'xhtml' => 'application/xhtml+xml',                     'wmf'   => 'application/x-msmetafile',
    'xls'   => 'application/vnd.ms-excel',                  'zip'   => 'application/zip',
    'xlsx'  => 'application/vnd.ms-excel',                 'pptx'   => 'application/vnd.ms-powerpoint',
    'docx'  => 'application/msword',                        

    'uu'    => 'x-uuencode',    'uue'   => 'x-uuencode',
    'json'  => 'appliaction/json',
  );

  $file_name =~ tr/A-Z/a-z/;
  $file_name = ($file_name =~ /\.?(\w+)$/) ? $1 : "";
  return defined $mime_type{$file_name} ? $mime_type{$file_name} : 'application/octet-stream';
}

1;

