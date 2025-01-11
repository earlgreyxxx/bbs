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
use File::Copy;
use IO::Dir;

our ($DIR,$FDIR,$DIR_DATA,$LOG_NAME,$HTML_TITLE);

initialize();

$DIR = '' unless FORMVALUE('dir');

session_start($DIR);

#モード分岐
{
  no strict 'refs';
  my $hform = FORM();
  &{*{'on'.ucfirst(exists $hform->{mode} && $hform->{mode} ? $hform->{mode} : 'show')}{CODE}} ();
}
session_end();

#######################################################################
#デフォルト
#######################################################################
sub onShow
{
  our (@ORDER_DIR,$DIR_DEFAULT,$DIR_PASSWORD);
  require 'sign.inc.pl';

  my $str = shift;
  my @options;
  my %dd = getDataNames($DIR_DATA);
  my $hform = FORM();

  cgiOut(text('data directory is empty')) unless(%dd);

  if($hform->{'dir'})
    {
      push @options,qq(<input type="hidden" name="dir" value="$hform->{'dir'}">);
    }
  else
    {
      push @options,sprintf(qq(<p>%s</p>),text('Select data directory'));
      push @options,qq(<p>);
      push @options,qq(<select class="form-control" name="dir">);

      @ORDER_DIR = sort { $dd{$a} cmp $dd{$b} } keys %dd unless(@ORDER_DIR);

      foreach(@ORDER_DIR)
        {
          my $selected = $_ eq $DIR_DEFAULT ? ' selected' : '';
          push @options,qq(<option value="$_"$selected>$dd{$_}</option>);
        }

      push @options,qq(</select>);
      push @options,qq(</p>);

      delete $hform->{'done'};
    }

  http_header();
  html_login(\@options,
             $str,
             $hform->{'dir'} ? sprintf('<p class="text-left input-password"><strong>%s</strong>'.text('input password for').'</p>',$HTML_TITLE) : '');
}

#######################################################################
# 照合
#######################################################################
sub onVerify
{
  our ($DIR_PASSWORD,$CGI_ADMIN);
  my $hform = FORM();
  my $done = $hform->{'done'};
  my $phrase = $hform->{'phrase'};

  $done =~ s/&amp;/&/g if($done);

  if($phrase eq $DIR_PASSWORD)
    {
      regenerate_session();
      certified_session($DIR_PASSWORD);

      clear_tokens();
    }
  else
    {
      onShow(text('password does not match'));
      return;
    }

  redirect($done || "$CGI_ADMIN?dir=$DIR");
}

#######################################################################
# ログアウト
#######################################################################
sub onLogout
{
  our $CGI_SELF;
  uncertified_session();
  redirect("$CGI_SELF?dir=$DIR");
}
