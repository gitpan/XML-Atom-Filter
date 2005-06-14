package XML::Atom::Filter;

use warnings;
use strict;

=head1 NAME

XML::Atom::Filter - easy creation of command line Atom processing tools

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    package Uppercaser;
    use XML::Atom::Filter;
    use base qw( XML::Atom::Filter );
    
    sub entry {
        my ($class, $e) = @_;
        $e->content(uc $e->content);
    }
    
    package main;
    Uppercaser->filter;

=head1 DESCRIPTION

C<XML::Atom::Filter> supports creation of command line tools to filter and process Atom feeds.

=head1 USAGE

=cut

package XML::Atom::Filter;
use XML::Atom;
use XML::Atom::Feed;

use constant NS => 'http://purl.org/atom/ns#';

=head2 XML::Atom::Filter->new()

Create an instance of the idempotent filter. C<XML::Atom::Filter> can be used as a class or an instance.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 $f->filter([ $fh ])

Read an Atom feed document and apply the filtering process to it. The Atom feed is read from C<$fh>, or C<STDIN> if not given. After the feed is read and parsed, it will be run through the C<pre>, C<entry> (entry by entry), and C<post> methods.

=cut

sub filter {
    my ($self, $fh) = @_;
    my $feed = XML::Atom::Feed->new($fh || \*STDIN) or return;

    $self->pre($feed);

    my @entries = $feed->entries;
    @entries = grep { $_ } map { $self->entry($_) } @entries;

    ## Remove existing entries so we can add back the processed ones without duplication.
    my @entryNodes;
    if(*XML::Atom::LIBXML) {
        @entryNodes = $feed->{doc}->getElementsByTagNameNS(NS, 'entry') or return;
    } else {
        for my $el ($feed->{doc}->getDocumentElement->childNodes) {
            push @entryNodes, $el if $el->getName eq 'entry';
        };
    }
    $_->parentNode->removeChild($_) for @entryNodes;
    
    $feed->add_entry($_) for @entries;

    $self->post($feed);
}

=head2 $f->pre($feed)

Prepares to process the entries of the feed, an C<XML::Atom::Feed> object. By default, no operation is performed.

=cut

sub pre { 1; }

=head2 $f->entry($entry)

Processes an entry of the feed, an C<XML::Atom::Entry> object. Returns the C<XML::Atom::Entry> to include in the resulting feed, or C<undef> to omit the entry. By default, C<$entry> is returned unaltered.

If your filter modifies the content of the entry, you B<must> also modify the entry's C<id>. The Atom feed specification requires entries' C<id> fields to be universally unique.

=cut

sub entry { $_[1]; }

=head2 $f->post($feed)

Postprocesses the feed, an C<XML::Atom::Feed> object, after the entries are individually processed. By default, the feed's XML is printed to C<STDOUT>.

=cut

sub post { print STDOUT $_[1]->as_xml; }

=head1 AUTHOR

Mark Paschal, C<< <markpasc@markpasc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-atom-filter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Atom-Filter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mark Paschal, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;  # End of XML::Atom::Filter

