require 5;

package XML::TreeBuilder;

use warnings;
use strict;
use XML::Element ();
use XML::Parser  ();
use Carp;
use vars qw(@ISA $VERSION);

$VERSION = 4.1;
@ISA     = ('XML::Element');

#==========================================================================
sub new {
    my ( $this, $arg ) = @_;
    my $class = ref($this) || $this;

    my $NoExpand     = ( delete $arg->{'NoExpand'}     || undef );
    my $ErrorContext = ( delete $arg->{'ErrorContext'} || undef );

    if ( %{$arg} ) {
        croak "unknown args: " . join( ", ", keys %{$arg} );
    }

    my $self = XML::Element->new('NIL');
    bless $self, $class;    # and rebless
    $self->{'_element_class'}      = 'XML::Element';
    $self->{'_store_comments'}     = 0;
    $self->{'_store_pis'}          = 0;
    $self->{'_store_declarations'} = 0;
    $self->{'NoExpand'}            = $NoExpand if ($NoExpand);
    $self->{'ErrorContext'}        = $ErrorContext if ($ErrorContext);

    # have to let HTML::Element know there are encoded entities
    $XML::Element::encoded_content = $NoExpand if ($NoExpand);

    my @stack;

 # Compare the simplicity of this to the sheer nastiness of HTML::TreeBuilder!

    $self->{'_xml_parser'} = XML::Parser->new(
        'Handlers' => {
            'Default' => sub {

                # Stuff unexpanded entities back on to the stack as is.
                if ( ( $self->{'NoExpand'} ) && ( $_[1] =~ /&[^\;]+\;/ ) ) {
                    $stack[-1]->push_content( $_[1] );
                }
                return;
            },
            'Start' => sub {
                shift;
                if (@stack) {
                    push @stack, $self->{'_element_class'}->new(@_);
                    $stack[-2]->push_content( $stack[-1] );
                }
                else {
                    $self->tag(shift);
                    while (@_) { $self->attr( splice( @_, 0, 2 ) ) }
                    push @stack, $self;
                }
            },

            'End' => sub { pop @stack; return },

            'Char' => sub {

       # have to escape '&' if we have entities to catch things like &amp;foo;
                if ( $_[1] eq '&' and $self->{'NoExpand'} ) {
                    $stack[-1]->push_content('&amp;');
                }
                else {
                    $stack[-1]->push_content( $_[1] );
                }
            },

            'Comment' => sub {
                return unless $self->{'_store_comments'};
                ( @stack ? $stack[-1] : $self )
                    ->push_content( $self->{'_element_class'}
                        ->new( '~comment', 'text' => $_[1] ) );
                return;
            },

            'Proc' => sub {
                return unless $self->{'_store_pis'};
                ( @stack ? $stack[-1] : $self )
                    ->push_content( $self->{'_element_class'}
                        ->new( '~pi', 'text' => "$_[1] $_[2]" ) );
                return;
            },

            'Final' => sub {

                # clean up the internal attributes
                $self->root()->traverse(
                    sub {
                        my ( $node, $start ) = @_;
                        if ( ref $node ) {    # it's an element
                            $node->attr( 'NoExpand',     undef );
                            $node->attr( 'ErrorContext', undef );
                        }
                    }
                );
            },

            # And now, declarations:

            'Attlist' => sub {
                return unless $self->{'_store_declarations'};
                shift;
                ( @stack ? $stack[-1] : $self )->push_content(
                    $self->{'_element_class'}->new(
                        '~declaration',
                        'text' => join ' ',
                        'ATTLIST', @_
                    )
                );
                return;
            },

            'Element' => sub {
                return unless $self->{'_store_declarations'};
                shift;
                ( @stack ? $stack[-1] : $self )->push_content(
                    $self->{'_element_class'}->new(
                        '~declaration',
                        'text' => join ' ',
                        'ELEMENT', @_
                    )
                );
                return;
            },

            'Doctype' => sub {
                return unless $self->{'_store_declarations'};
                shift;
                ( @stack ? $stack[-1] : $self )->push_content(
                    $self->{'_element_class'}->new(
                        '~declaration',
                        'text' => join ' ',
                        'DOCTYPE', @_
                    )
                );
                return;
            },

            'Entity' => sub {
                return unless $self->{'_store_declarations'};
                shift;
                ( @stack ? $stack[-1] : $self )->push_content(
                    $self->{'_element_class'}->new(
                        '~declaration',
                        'text' => join ' ',
                        'ENTITY', @_
                    )
                );
                return;
            },
        },
        'NoExpand'     => $self->{'NoExpand'},
        'ErrorContext' => $self->{'ErrorContext'},
    );

    return $self;
}

#==========================================================================
sub _elem    # universal accessor...
{
    my ( $self, $elem, $val ) = @_;
    my $old = $self->{$elem};
    $self->{$elem} = $val if defined $val;
    return $old;
}

sub store_comments     { shift->_elem( '_store_comments',     @_ ); }
sub store_declarations { shift->_elem( '_store_declarations', @_ ); }
sub store_pis          { shift->_elem( '_store_pis',          @_ ); }

#==========================================================================

sub parse {
    shift->{'_xml_parser'}->parse(@_);
}

sub parse_file { shift->parsefile(@_) }    # alias

sub parsefile {
    shift->{'_xml_parser'}->parsefile(@_);
}

sub eof {
    delete shift->{'_xml_parser'};         # sure, why not?
}

#==========================================================================
1;

__END__


=head1 NAME

XML::TreeBuilder - Parser that builds a tree of XML::Element objects

=head1 SYNOPSIS

  foreach my $file_name (@ARGV) {
    my $tree = XML::TreeBuilder->new({ 'NoExpand' => 0, 'ErrorContext' => 0 }); # empty tree
    $tree->parse_file($file_name);
    print "Hey, here's a dump of the parse tree of $file_name:\n";
    $tree->dump; # a method we inherit from XML::Element
    print "And here it is, bizarrely rerendered as XML:\n",
      $tree->as_XML, "\n";
    
    # Now that we're done with it, we must destroy it.
    $tree = $tree->delete;
  }

=head1 DESCRIPTION

This module uses XML::Parser to make XML document trees constructed of
XML::Element objects (and XML::Element is a subclass of HTML::Element
adapted for XML).  XML::TreeBuilder is meant particularly for people
who are used to the HTML::TreeBuilder / HTML::Element interface to
document trees, and who don't want to learn some other document
interface like XML::Twig or XML::DOM.

The way to use this class is to:

1. start a new (empty) XML::TreeBuilder object.

2. set any of the "store" options you want.

3. then parse the document from a source by calling
C<$x-E<gt>parsefile(...)>
or
C<$x-E<gt>parse(...)> (See L<XML::Parser> docs for the options
that these two methods take)

4. do whatever you need to do with the syntax tree, presumably
involving traversing it looking for some bit of information in it,

5. and finally, when you're done with the tree, call $tree->delete to
erase the contents of the tree from memory.  This kind of thing
usually isn't necessary with most Perl objects, but it's necessary for
TreeBuilder objects.  See L<HTML::Element> for a more verbose
explanation of why this is the case.

=head1 METHODS AND ATTRIBUTES

XML::TreeBuilder is a subclass of XML::Element, which in turn is a subclass
of HTML:Element.  You should read and understand the documentation for
those two modules.

An XML::TreeBuilder object is just a special XML::Element object that
allows you to call these additional methods:

=over

=item $root = XML::TreeBuilder->new()

Construct a new XML::TreeBuilder object.

Parameters:

=over

=item NoExpand

    Passed to XML::Parser. Do not Expand external entities.
    Default: undef

=item ErrorContext

    Passed to XML::Parser. Number of context lines to generate on errors.
    Default: undef

=back

=item $root->eof

Deletes parser object.

=item $root->parse(...options...)

Uses XML::Parser's C<parse> method to parse XML from the source(s?)
specified by the options.  See L<XML::Parse>

=item $root->parsefile(...options...)

Uses XML::Parser's C<parsefile> method to parse XML from the source(s?)
specified by the options.  See L<XML::Parse>

=item $root->parse_file(...options...)

Simply an alias for C<parsefile>.

=item $root->store_comments(value)

This determines whether TreeBuilder will normally store comments found
while parsing content into C<$root>.  Currently, this is off by default.

=item $root->store_declarations(value)

This determines whether TreeBuilder will normally store markup
declarations found while parsing content into C<$root>.  Currently,
this is off by default.

=item $root->store_pis(value)

This determines whether TreeBuilder will normally store processing
instructions found while parsing content into C<$root>.
Currently, this is off (false) by default.

=back

=head1 SEE ALSO

L<XML::Parser>, L<XML::Element>, L<HTML::TreeBuilder>, L<HTML::DOMbo>.

And for alternate XML document interfaces, L<XML::DOM> and L<XML::Twig>.


=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2000,2004 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Current Author:
	Jeff Fearn C<< <jfearn@cpan.org> >>.

Former Authors:
	Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

