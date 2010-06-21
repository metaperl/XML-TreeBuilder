#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 4;

BEGIN {
    use_ok('XML::TreeBuilder');
}

my $x = XML::TreeBuilder->new;
$x->store_comments(1);
$x->store_pis(1);
$x->store_declarations(1);
$x->parse(qq{<!-- myorp --><Gee><foo Id="me" xml:foo="lal">Hello World</foo>}
        . qq{<lor/><!-- foo --></Gee><!-- glarg -->} );

my $y = XML::Element->new_from_lol(
    [   'Gee',
        [ '~comment', { 'text' => ' myorp ' } ],
        [ 'foo', { 'Id' => 'me', 'xml:foo' => 'lal' }, 'Hello World' ],
        ['lor'],
        [ '~comment', { 'text' => ' foo ' } ],
        [ '~comment', { 'text' => ' glarg ' } ],
    ]
);

ok( $x->same_as($y) );

unless ( $ENV{'HARNESS_ACTIVE'} ) {
    $x->dump;
    $y->dump;
}

#print "\n", $x->as_Lisp_form, "\n";
#print "\n", $x->as_XML, "\n\n";
#print "\n", $y->as_XML, "\n\n";
$x->delete;
$y->delete;

$x = XML::TreeBuilder->new( { NoExpand => 1, ErrorContext => 2 } );
$x->store_comments(1);
$x->store_pis(1);
$x->store_declarations(1);
$x->parse(qq{<!-- myorp --><Gee><foo Id="me" xml:foo="lal">Hello World</foo>}
        . qq{<lor/><!-- foo --></Gee><!-- glarg -->} );

$y = XML::Element->new_from_lol(
    [   'Gee',
        [ '~comment', { 'text' => ' myorp ' } ],
        [ 'foo', { 'Id' => 'me', 'xml:foo' => 'lal' }, 'Hello World' ],
        ['lor'],
        [ '~comment', { 'text' => ' foo ' } ],
        [ '~comment', { 'text' => ' glarg ' } ],
    ]
);

ok( $x->same_as($y) );

my $z = XML::TreeBuilder->new( { NoExpand => 1, ErrorContext => 2 } );
$z->parsefile("t/parse_test.xml");
like( $z->as_XML(), qr{<p>Here &amp;foo; There</p>}, 'Decoded ampersand' );

__END__
