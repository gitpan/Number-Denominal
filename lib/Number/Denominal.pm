package Number::Denominal;

use strict;
use warnings;
use List::ToHumanString;
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(denominal  denominal_hashref  denominal_list);

our $VERSION = '1.004';

my %Unit_Shortcuts = (
    time    => [
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    ],
    weight  => [
        gram => 1000 => kilogram => 1000 => 'tonne',
    ],
    weight_imperial => [
       ounce => 16 => pound => 14 => stone => 160 => 'ton',
    ],
    length  => [
       meter => 1000 => kilometer => 9_460_730_472.5808 => 'light year',
    ],
    length_mm  => [
       millimeter => 10 => centimeter => 100 => meter => 1000
            => kilometer => 9_460_730_472.5808 => 'light year',
    ],
    length_imperial => [
        [qw/inch  inches/] => 12 =>
            [qw/foot  feet/] => 3 => yard => 1760
                => [qw/mile  miles/],
    ],
    volume => [
       milliliter => 1000 => 'Liter',
    ],
    volume_imperial => [
       'fluid ounce' => 20 => pint => 2 => quart => 4 => 'gallon',
    ],
    info => [
        bit => 8 => byte => 1000 => kilobyte => 1000 => megabyte => 1000
            => gigabyte => 1000 => terabyte => 1000 => petabyte => 1000
                => exabyte => 1000 => zettabyte => 1000 => 'yottabyte',
    ],
    info_1024  => [
        bit => 8 => byte => 1024 => kibibyte => 1024 => mebibyte => 1024
            => gibibyte => 1024 => tebibyte => 1024 => pebibyte => 1024
                => exbibyte => 1024 => zebibyte => 1024 => 'yobibyte',
    ],
);

sub denominal {
    my ( $num, @denomination ) = @_;
    return _denominal( $num, \@denomination, 'string' );
}

sub denominal_list {
    my ( $num, @denomination ) = @_;
    return _denominal( $num, \@denomination, 'list' );
}

sub denominal_hashref {
    my ( $num, @denomination ) = @_;
    return _denominal( $num, \@denomination, 'hashref' );
}

sub _denominal {
    my ( $num, $denomination, $mode ) = @_;

    $num = abs($num);

    if ( @$denomination == 1 and ref $denomination->[0] eq 'ARRAY' ) {
        @$denomination = map +( $_ => $_ ), @{ $denomination->[0] };
        push @$denomination, 'last';
        $mode = 'list';
    }
    elsif ( @$denomination == 1 and ref $denomination->[0] eq 'SCALAR' ) {

        my $unit_shortcut = ${ $denomination->[0] };
        croak qq{Unknown unit shortcut ``$unit_shortcut''}
            unless $Unit_Shortcuts{ $unit_shortcut };
        $denomination = $Unit_Shortcuts{ $unit_shortcut };
    }

    my @result;
    for ( _get_bits( $num, @$denomination ) ) {
        my $bit_num = sprintf '%d', $num / $_->{divisor};
        $num = $num - $bit_num * $_->{divisor};
        $bit_num or next;

        push @result, $mode eq 'hashref'
            ? ( $_->{name}[0] => $bit_num )
                : $mode eq 'list'
                    ? $bit_num
                    : $bit_num . ' ' . $_->{name}[ $bit_num == 1 ? 0 : 1 ];
    }

    return $mode eq 'hashref'
        ? +{@result} :
            $mode eq 'list'
                ? @result : to_human_string '|list|', @result;
}

sub _get_bits {
    my ( $num, @denomination ) = @_;

    my @bits;
    my $divisor = 1;
    for ( grep !($_%2), 0..$#denomination ) {
        if ( not ref $denomination[ $_ ] ) {
            $denomination[ $_ ] = [
                $denomination[ $_ ],
                $denomination[ $_ ] . 's',
            ];
        }

        push @bits, {
            name    => $denomination[ $_ ],
            divisor => $divisor,
        };

        $divisor *= $denomination[ $_+1 ] || 1;
    }

    return reverse @bits;
}

q|
  Q: how many programmers does it take to change a light bulb?
  A: none, that's a hardware problem
|;

__END__

=encoding utf8

=head1 NAME

Number::Denominal - break up numbers into arbitrary denominations

=head1 SYNOPSIS


    use Number::Denominal;

    my $seconds = (localtime)[2]*3600 + (localtime)[1]*60 + (localtime)[2];

    say 'So far today you lived for ',
        denominal($seconds,
            [ qw/second seconds/ ] =>
                60 => [ qw/minute minutes/ ] =>
                    60 => [ qw/hour hours/ ]
        );
    ## Prints: So far today you lived for 23 hours,
    ## 48 minutes, and 23 seconds

    # Same thing but with a 'time' unit set shortcut:
    say 'So far today you lived for ', denominal($seconds, \'time');

    say 'If there were 100 seconds in a minute, and 100 minutes in an hour,',
        ' then you would have lived today for ',
        denominal(
            # This is a shortcut for units that pluralize by adding "s"
            $seconds, second => 100 => minute => 100 => 'hour',
        );
    ## Prints: If there were 100 seconds in a minute, and 100 minutes
    ## in an hour, then you would have lived today for 8 hours, 57 minutes,
    ## and 3 seconds

    say 'And if we called seconds "foos," minutes "bars," and hours "bers"',
        ' then you would have lived today for ',
        denominal(
            $seconds, foo => 100 => bar => 100 => 'ber',
        );
    ## Prints: And if we called seconds "foos," minutes "bars," and hours
    ## "bers" then you would have lived today for 8 bers, 57 bars, and 3 foos

    ## You can get the denominalized data as a list:
    my @data = denominal_list(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

    ## Or same thing as a shorthand:
    my @data = denominal_list(  $seconds, [ 100, 100 ], );

    ## Or get the data as a hashref:
    my $data = denominal_hashref(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

=head1 DESCRIPTION

Define arbitrary set of units and split up a number into those units.

This module arose from a discussion in IRC, regarding splitting
a number of seconds into minutes, hours, days...
L<Paul 'LeoNerd' Evans|https://metacpan.org/author/PEVANS> brought up
the idea for L<Number::Denominal> that would split up a number into any
arbitrarily defined arbitrary units and I am the code monkey that
released it.

=head1 EXPORTS

=head2 C<denominal>

    ## All these are equivalent:

    my $string = denominal( $number, \'time' );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/hour hours/ ] =>
                    24 => day => 7 => 'week',
    );

Breaks up the number into given denominations and B<returns> it as a
human-readable string (e.g. C<"5 hours, 22 minutes, and 4 seconds">.
If the value for any unit ends up being zero, that unit will be omitted
(an empty string will be returned if the given number is zero).

B<The first argument> is the number that needs to be broken up into units.
Negative numbers will be C<abs()'ed>.

B<The other arguments> are given as a list and
define unit denominations. The list of denominations should start
with a unit name and end with a unit name, and each unit name must be
separated by a number that represents how many left-side units fit into the
right-side unit. B<Unit name> can be an arrayref, a simple string,
or a scalarref. The meaning is as follows:

=head3 an arrayref

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/foo bar/ ]
    );

The arrayref must have two elements. The first element is a string
that is the singular name of the unit. The second element is a string
that is the plural name of the unit Arrayref unit names can be mixed
with simple-string unit names.

=head3 a simple string

    # These are the same:

    my $string = denominal( $number, second => 60 => 'minute' );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] => 60 => [ qw/minute minutes/ ]
    );

When a unit name is a simple string, it's taken as a shortcut for
an arrayref unit name with this simple string as the first element
in that arrayref and the string with letter "s" added at the end as the
second element. (Basically a shortcut for typing units that pluralize
by adding "s" to the end).

=head3 a scalarref

    ## All these are the same:

    my $string = denominal( $number, \'time' );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

Instead of giving a list of unit names and their denominations, you
can pass a scalarref as the second argument to C<denominal()>. The
value of the scalar that scalarref references is the name of a unit
set shortcut. Currently available unit sets and their definitions are as
follows:

=head4 C<time>

    time    => [
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    ],

=head4 C<weight>

    weight  => [
        gram => 1000 => kilogram => 1000 => 'tonne',
    ],

=head4 C<weight_imperial>

    weight_imperial => [
       ounce => 16 => pound => 14 => stone => 160 => 'ton',
    ],

=head4 C<length>

    length  => [
       meter => 1000 => kilometer => 9_460_730_472.5808 => 'light year',
    ],

=head4 C<length_mm>

    length_mm  => [
       millimeter => 10 => centimeter => 100 => meter => 1000
            => kilometer => 9_460_730_472.5808 => 'light year',
    ],

=head4 C<length_imperial>

    length_imperial => [
        [qw/inch  inches/] => 12 =>
            [qw/foot  feet/] => 3 => yard => 1760
                => [qw/mile  miles/],
    ],

=head4 C<volume>

    volume => [
       milliliter => 1000 => 'Liter',
    ],

=head4 C<volume_imperial>

    volume_imperial => [
       'fluid ounce' => 20 => pint => 2 => quart => 4 => 'gallon',
    ],

=head4 C<info>

    info => [
        bit => 8 => byte => 1000 => kilobyte => 1000 => megabyte => 1000
            => gigabyte => 1000 => terabyte => 1000 => petabyte => 1000
                => exabyte => 1000 => zettabyte => 1000 => 'yottabyte',
    ],

=head4 C<info_1024>

    info_1024  => [
        bit => 8 => byte => 1024 => kibibyte => 1024 => mebibyte => 1024
            => gibibyte => 1024 => tebibyte => 1024 => pebibyte => 1024
                => exbibyte => 1024 => zebibyte => 1024 => 'yobibyte',
    ],

=head2 C<denominal_list>

    ## These two are equivalent

    my @bits = denominal_list(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    my @bits = denominal_list(
        $number,
        [ qw/60  60  24  7/ ],
    );

Functions the same as C<denominal()>, except it B<returns> a list of unit
values, instead of a string. (e.g. when C<denominal()> would return
"8 hours, 23 minutes, and 5 seconds", C<denominal_list()> would return
a list of three numbers: C<8, 23, 5>).

Another shortcut is possible with C<denominal_list()>. Instead of giving
each unit a name, you can call C<denominal_list()> with just
B<two arguments> and pass an arrayref as the second
argument, containing a list of numbers defining unit denominations.

=head2 C<denominal_hashref>

    ## These two are equivalent

    my $data = denominal_hashref(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    say "The number has $data->{second} seconds and $data->{week} weeks!";

Functions the same as C<denominal()>, except it B<returns> a hashref
where the keys are the B<singular> names of the units and values are
the numerical values of each unit. If a unit's value is zero, its key
will be absent from the hashref.

=head1 AUTHORS

=over 4

=item * B<Idea:> Paul Evans, C<< <pevans at cpan.org> >>

=item * B<Code:> Zoffix Znet, C<< <zoffix at cpan.org> >>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-denominal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Denominal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Denominal

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Denominal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Number-Denominal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number-Denominal>

=item * Search CPAN

L<http://search.cpan.org/dist/Number-Denominal/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Zoffix Znet.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
