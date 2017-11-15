package JSON::Infer::Moose;

use strict;
use warnings;

our $VERSION = '0.1';

use Moose;
use File::Slurp;

=head1 NAME

JSON::Infer::Moose - Infer Moose Classes from JSON objects

=head1 SYNOPSIS

  use JSON::Infer::Moose;


=head1 DESCRIPTION

This provides a mechanism for creating some stub Moose classes from
the return of a REST Call.

=head2 METHODS

=over 4


=item infer

This accepts a single path and returns a L<JSON::Infer::Moose::Class>
object, if there is an error retrieving the data or parsing the response
it will throw an exception.

It requires the following named arguments:

=over 4

=item uri

This is the uri that will be used to retrieve the content.  It will need
to be some protocol scheme that is understood by L<LWP::UserAgent>

=item class_name

This is the base class name that will be used for the package, any child classes that are discovered will parsing the
attributes will have a name based on this and the name of the attribute.

=cut

=back


=cut

has uri => (
    is  =>  'ro',
    isa =>  'Str',
    predicate   =>  'has_uri',
);

has file => (
    is  =>  'ro',
    isa =>  'Str',
    predicate   =>  'has_file',
);

has class_name  =>  (
    is  =>  'ro',
    isa =>  'Str',
    default =>  'My::JSON',
);

has dir =>  (
    is  =>  'ro',
    isa =>  'Str',
    default =>  'lib',
);

sub infer {
    my ( $self ) = @_;
    require JSON::Infer::Moose::Class;
    return JSON::Infer::Moose::Class->new_from_data( $self->class_name, $self->get_content );
}

sub get_content {
    my ( $self ) = @_;

    my $json;
    if ( $self->has_uri ) {
        my $resp = $self->get($self->uri);

        if ( $resp->is_success() ) {
            $json = $resp->decoded_content();
        }
        else {
            die "couldn't retrieve json";
        }
    }
    elsif ( $self->has_file ) {
        require File::Slurp;
        File::Slurp->import;
        $json = read_file($self->file);
    }
    else {
        die "need one of 'uri' or 'file'\n";
    }
    return $self->decode_json($json);
}

=item ua

The L<LWP::UserAgent> that will be used.

=cut

has ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    builder => '_get_ua',
    handles => [qw(get)],
);

sub _get_ua {
    my ($self) = @_;
    require LWP::UserAgent;

    my $ua = LWP::UserAgent->new(
        default_headers => $self->headers(),
        agent           => __PACKAGE__ . '/' . $VERSION,
    );

    return $ua;
}

=item headers

Returns the default set of headers that will be applied to the
LWP::UserAgent object.

=cut

has headers => (
    is      => 'rw',
    isa     => 'HTTP::Headers',
    lazy    => 1,
    builder => '_get_headers',
);

sub _get_headers {
    my ($self) = @_;

    require HTTP::Headers;

    my $h = HTTP::Headers->new();
    $h->header( 'Content-Type' => $self->content_type() );
    $h->header( 'Accept'       => $self->content_type() );

    return $h;
}

=item content_type

This is the content type that we want to use.  The default is
"application/json".

=cut

has content_type => (
    is      => 'rw',
    isa     => 'Str',
    default => "application/json",
);

=item json_parser

This returns a JSON parser object.

=cut

has json_parser => (
    is      => 'rw',
    isa     => 'JSON',
    lazy    => 1,
    builder => '_get_json',
    handles => {
        decode_json => 'decode',
        encode_json => 'encode',
    },
);

sub _get_json {
    my ($self) = @_;

    require JSON;

    my $json = JSON->new();

    return $json;
}

has classes =>  (
    is =>   'ro',
    isa =>  'ArrayRef',
    lazy    =>  1,
    auto_deref  =>  1,
    builder =>  '_build_classes',
);

sub _build_classes {
    my ( $self ) = @_;

    my $j = $self->infer;
    my @classes = ( $j, $j->classes );

    return \@classes;
}

sub make_classes {
    my ( $self ) = @_;

    require Path::Class;

    my $dir = Path::Class::dir($self->dir);

    for my $class ( $self->classes ) {
        my $file = $dir->file($class->path);
        $file->dir->mkpath;
        my $h = $file->openw;
        $self->process_template('class.tt', { class => $class }, $h);
        $h->close;
    }

}

use Template;
has template => (
    is      =>  'ro',
    isa     =>  'Template',
    lazy    =>  1,
    builder =>  '_build_template',
    handles =>  {
        process_template    =>  'process',
    }
);

sub _build_template {
    my ( $self ) = @_;

    return Template->new({ INCLUDE_PATH => $self->template_path, TRIM => 1, POST_CHOMP => 1 });
}

has template_path => (
    is  =>  'ro',
    isa => 'Str',
    lazy    =>  1,
    builder =>  '_build_template_path',
);

sub _build_template_path {
    require File::ShareDir;
    require File::HomeDir;

    my $path = join ':', grep { defined $_ } (
        'share',
        File::HomeDir->my_dist_data('JSON-Infer-Moose'),
        eval { File::ShareDir::dist_dir('JSON-Infer-Moose') },
    );

    return $path;

}

=back



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
