#!/usr/bin/perl -w
use Test::More;
use Perfect::Hash;

use Config;
use ExtUtils::Embed qw(ccflags ldopts);

my @methods = sort keys %Perfect::Hash::algo_methods;
if (@ARGV and grep /^-/, @ARGV) {
  @methods = grep { $_ = $1 if /^-(.*)/ } @ARGV;
}

plan tests => 4*scalar(@methods);

my $dict = "examples/words20";
open my $d, $dict or die; {
  local $/;
  @dict = split /\n/, <$d>;
}
close $d;

sub cmd {
  my $m = shift;
  # TODO: Win32 /Of
  my $cmd = $Config{cc}." -I. ".ccflags." -ophash main.c phash.c ".ldopts;
  chomp $cmd; # oh yes! ldopts contains an ending \n
  $cmd .= " -lz" if $m eq '-urban';
  return $cmd;
}

sub wmain {
  my ($i, $aol) = @_;
  $aol = 0 unless $aol;
  my $i1 = $i +1;
  # and then we need a main also
  open my $FH, ">", "main.c";
  print $FH '
#include <stdio.h>
#include "phash.h"

int main () {
  int err = 0;
  long h = phash_lookup("AOL", 3);
  if (h == '.$aol.') {
    printf("ok %d - c lookup exists %d\n", '.$i.', h);
  } else {
    printf("not ok %d - c lookup exists %d\n", '.$i.', h); err++;
  }
  return err;
}
';
  close $FH;
}

my $i = 0;
for my $m (map {"-$_"} @methods) {
  my $ph = new Perfect::Hash \@dict, $m, '-nul';
  unless ($ph) {
    ok(1, "SKIP empty phash $m");
    ok(1) for 1..3;
    $i++;
    next;
  }
  wmain((4*$i)+3, $ph->perfecthash('AOL'));
  $i++;
  $ph->save_c("phash");
  ok(-f "phash.c" && -f "phash.h", "$m generated phash.c/.h");
  my $cmd = cmd($m);
  diag($cmd);
  my $retval = system($cmd);
  if (ok(!($retval>>8), "could compile $m")) {
    my $retstr = `./phash`;
    $retval = $?;
    like($retstr, qr/^ok \d+ - c lookup exists/m, "c lookup exists");
  } else {
    ok(1);
  }
  ok(!($retval>>8), "could run $m");
  #unlink("phash","phash.c","phash.h","main.c");
}