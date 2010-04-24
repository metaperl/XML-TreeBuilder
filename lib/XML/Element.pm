
require 5;
package XML::Element;
use warnings;
use strict;
use HTML::Tagset ();
use HTML::Element 3.08 ();

use vars qw(@ISA $VERSION);
$VERSION = '3.09';
@ISA = ('HTML::Element');

# Init:
my %emptyElement = ();
foreach my $e (%HTML::Tagset::emptyElement) {
  $emptyElement{$e} = 1
    if substr($e,0,1) eq '~' and $HTML::Tagset::emptyElement{$e};
}

#--------------------------------------------------------------------------
#Some basic overrides:

sub _empty_element_map { \%emptyElement }

*_fold_case = \&HTML::Element::_fold_case_NOT;
*starttag   = \&HTML::Element::starttag_XML;
*endtag     = \&HTML::Element::endtag_XML;

# TODO: override id with something that looks for xml:id too/instead?

#--------------------------------------------------------------------------

#TODO: test and document this:
# with no tagname set, assumes ALL all-whitespace nodes are ignorable!

sub delete_ignorable_whitespace {
  my $under_hash = $_[1];
  my(@to_do) = ($_[0]);
  
  if($under_hash and ref($under_hash) eq 'ARRAY') {
    $under_hash = { map {; $_ => 1 } @$under_hash };
  }
  
  my $all = !$under_hash;
  my($i,$this,$children);
  while(@to_do) {
    $this = shift @to_do;
    $children = $this->content || next;
    if(
      ($all or $under_hash->{$this->tag})
      and @$children
    ) {
      for($i = $#$children; $i >= 0; --$i) {
        # work backwards thru the list
        next if ref $children->[$i];
        if($children->[$i] =~ m<^\s*$>s) { # all WS
          splice @$children, $i, 1; # delete it.
        }
      }
    }
    unshift @to_do, grep ref($_), @$children; # recurse
  }
  
  return;
}

#--------------------------------------------------------------------------

1;

__END__

=head1 NAME

XML::Element - XML elements with the same interface as HTML::Element

=head1 SYNOPSIS

  [See HTML::Element]

=head1 METHODS AND ATTRIBUTES

=head2 delete_ignorable_whitespace

TODO: test and document this:
with no tagname set, assumes ALL all-whitespace nodes are ignorable!

=head2 endtag

Redirects to HTML::Element::endtag_XML

=head2 starttag

Redirects to HTML::Element::starttag_XML

=head1 DESCRIPTION

This is just a subclass of HTML::Element.  It works basically the same
as HTML::Element, except that tagnames and attribute names aren't
forced to lowercase, as they are in HTML::Element.

L<HTML::Element> describes everything you can do with this class.

=head1 CAVEATS

Has currently no handling of namespaces.

=head1 SEE ALSO

L<XML::TreeBuilder> for a class that actually builds XML::Element
structures.

L<HTML::Element> for all documentation.

L<XML::DOM> and L<XML::Twig> for other XML document tree interfaces.

L<XML::Generator> for more fun.


=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2000,2004 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

