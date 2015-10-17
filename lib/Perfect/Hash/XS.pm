package Perfect::Hash::XS;
use strict;
our $VERSION = '0.01';
use Perfect::Hash::C;
our @ISA = qw(Perfect::Hash::C Perfect::Hash);

use XSLoader;
XSLoader::load('Perfect::Hash', $VERSION);

=head1 NAME

Perfect::Hash::XS - Perfect Hash output formatter for XS - compiled perl extensions

=head1 SYNOPSIS

    pperf keyfile --for-xs --prefix=ph

    use Perfect::Hash;
    $hash->{chr($_)} = int rand(2) for 48..90;
    my $ph = new Perfect:Hash $hash;
    $ph->save_xs("ph.inc");

    my @dict = split/\n/,`cat /usr/share.dict/words`;
    my $ph2 = Perfect::Hash->new(\@dict, -minimal, -for-xs);
    $ph2->save_xs("ph1.inc");

=head1 DESCRIPTION

Optimized for sharedlib and PIC, and it can hold more and mixed value
types, not just strings and integers. With the help of Data::Compile
(planned) even any perl values, like code refs, magic, ...

This is a replacement for cdb databases or write-once or only daily
Storable containers.

=head1 METHODS

=over

=item save_xs filename, options

Generate XS code, with the perl values saved as perl types.

=back

=cut

sub save_h_header { }

sub save_c_header {
  my ($ph, $filename) = @_;
  my $FH;
  open $FH, ">", $filename or die "$filename: @!";
  print $FH "#include <string.h>\n"; # for memcmp/strlen
  return $FH;
}

sub c_funcdecl {
  my ($ph, $base) = @_;
  if ($ph->option('-nul')) {
    "
long $base\_lookup(const char* s, int l)";
  } else {
    "
long $base\_lookup(const char* s)";
  }
}

sub save_xs {
  my $ph = shift;
  my $file = shift;
  my @options = @_;
  die 'save_xs nyi';
}
