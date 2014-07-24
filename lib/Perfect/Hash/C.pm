package Perfect::Hash::C;
our $VERSION = '0.01';
our @ISA = qw(Perfect::Hash);

=head1 NAME

Perfect::Hash::C - generate C code for perfect hashes

=head1 SYNOPSIS

    use Perfect::Hash;

    $hash->{chr($_)} = int rand(2) for 48..90;
    my $ph = new Perfect:Hash $hash, -for-c;
    $ph->save_c("ph"); # => ph.c, ph.h

    my @dict = split/\n/,`cat /usr/share.dict/words`;
    my $ph2 = Perfect::Hash->new(\@dict, -minimal, -for-c);
    $ph2->save_c("ph2"); # => ph2.c, ph2.h

=head1 DESCRIPTION

There exist various C or python libraries to generate code to access
perfect hashes and minimal versions thereof, but none are satisfying.
The various libraries need to be hand-picked to special input data and
to special output needs. E.g. for fast lookup vs small memory footprint,
static vs shared C library, optimized for PIC. Size of the hash, 
type of the hash: only indexed (not storing the values), with C values
or with typed values. (Perl XS, C++, strings vs numbers, ...)

=head1 METHODS

=over

=item save_c filename, options

Generates pure C code. Either indexed or with the values saved as C types,
strings or numbers only.

=cut

sub save_c {
  die 'nyi';
}