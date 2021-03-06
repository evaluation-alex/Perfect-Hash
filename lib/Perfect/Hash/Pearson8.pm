package Perfect::Hash::Pearson8;
#use coretypes;
use strict;
#use warnings;
use Perfect::Hash;
use Perfect::Hash::Pearson;
use integer;
use bytes;
our @ISA = qw(Perfect::Hash::Pearson Perfect::Hash Perfect::Hash::C);
our $VERSION = '0.01';

=head1 DESCRIPTION

A Pearson hash is generally not perfect, but generates one of the
fastest lookups.  This version is limited to max. 255 keys and thus
creates a perfect hash.

Optimal for 5-250 keys.

From: Communications of the ACM
Volume 33, Number 6, June, 1990
Peter K. Pearson
"Fast hashing of variable-length text strings"

=head1 METHODS

=head2 new $dict, @options

Computes a brute-force 8-bit Pearson hash table using the given
dictionary, given as hashref or arrayref, with fast lookup.  This
generator might fail, returning undef.

Honored options are:

I<-false-positives>

I<-max-time seconds> stops generating a pperf at seconds and uses a
non-perfect, but still fast hash then. Default: 60 seconds.

It returns an object with \@H containing the randomized
pearson lookup table or undef if none was found.

=cut

sub new {
  my $class = shift or die;
  my $dict = shift; #hashref or arrayref, file later
  my $options = Perfect::Hash::_handle_opts(@_);
  $options->{'-max-time'} = 60 unless exists $options->{'-max-time'};
  my $max_time = $options->{'-max-time'};
  my ($keys, $values) = _dict_init($dict);
  my $size = scalar @$keys;
  my $last = $size-1;
  if ($last > 255) {
    warn "cannot create perfect 8-bit pearson hash for $size entries > 255\n";
    # would need a 16-bit pearson or any-size pearson (see -pearson)
    return;
  }

  # Step 1: Generate @H
  # round up to ending 1111's
  my $hsize = 256;
  #print "size=$size hsize=$hsize\n";
  my @H; $#H = $hsize-1;
  my $i = 0;
  $H[$_] = $i++ for 0 .. $hsize-1; # init with ordered sequence
  my $H = \@H;
  my $ph = bless [$size, $H], $class;

  my $maxcount = 3 * $last; # when to stop the search. could be n!
  # Step 2: shuffle @H until we get a good maxbucket, only 0 or 1
  # https://stackoverflow.com/questions/1396697/determining-perfect-hash-lookup-table-for-pearson-hash
  my ($max, $counter);
  my $t0 = [gettimeofday];
  do {
    # this is not good. we should non-randomly iterate over all permutations
    $ph->shuffle();
    (undef, $max) = $ph->cost($keys);
    $counter++;
  } while ($max > 1 and $counter < $maxcount and tv_interval($t0) < $max_time); # $n!
  return if $max != 1;

  if (!exists $options->{'-false-positives'}) {
    return bless [$size, $H, $options, $keys], $class;
  } else {
    return bless [$size, $H, $options], $class;
  }
}

=head2 perfecthash $ph, $key

Look up a $key in the pearson hash table
and return the associated index into the initially 
given $dict.

Without C<-false-positives> it checks if the index is correct,
otherwise it will return undef.
With C<-false-positives>, the key must have existed in
the given dictionary. If not, a wrong index will be returned.

=cut

sub perfecthash {
  my ($ph, $key ) = @_;
  my $v = hash($ph->[1], $key, $ph->[0]);
  # -false-positives. no other options yet which would add a 3rd entry here,
  # so we can skip the !exists $ph->[2]->{-false-positives} check for now
  if ($ph->[3]) {
    return ($ph->[3]->[$v] eq $key) ? $v : undef;
  } else {
    return $v;
  }
}

=head2 false_positives

Returns 1 if the hash might return false positives, i.e. will return
the index of an existing key when you searched for a non-existing key.

The default is undef, unless you created the hash with the option
C<-false-positives>.

=cut

sub false_positives {
  return exists $_[0]->[2]->{'-false-positives'};
}

=head2 save_c fileprefix, options

Generates a $fileprefix.c and $fileprefix.h file.

=cut

#sub _old_save_c {
#  my $ph = shift;
#  require Perfect::Hash::C;
#  my ($fileprefix, $base) = Perfect::Hash::C::_save_c_header($ph, @_);
#  my $H;
#  open $H, ">>", $fileprefix.".h" or die "> $fileprefix.h @!";
#  print $H "
#static unsigned char $base\[] = {
#";
#  Perfect::Hash::C::_save_c_array(4, $H, $ph->[1]);
#  print $H "};\n";
#  close $H;
#
#  my $FH = Perfect::Hash::C::_save_c_funcdecl($ph, $fileprefix, $base);
#  # non-binary only so far:
#  print $FH "
#    unsigned h = 0;
#    for (int c = *s++; c; c = *s++) {
#        h = $base\[h ^ c];
#    }
#    return h;
#}
#";
#  close $FH;
#}

# local testing: pb -d lib/Perfect/Hash/Pearson8.pm examples/words20
# or just: pb -d -MPerfect::Hash -e'new Perfect::Hash([split/\n/,`cat "examples/words20"`], "-pearson8")'
unless (caller) {
  &Perfect::Hash::_test(shift @ARGV, "-pearson8", @ARGV)
}

1;
