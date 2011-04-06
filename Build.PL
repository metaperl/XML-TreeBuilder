use strict;
use warnings;
use Module::Build;
use 5.004;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
        sub ACTION_authortest {
            my ($self) = @_;
            $self->depends_on('build');
            $self->depends_on('manifest');
            $self->depends_on('distmeta');
            $self->test_files( qw< t xt/author > );
            $self->recursive_test_files(1);
            $self->depends_on('test');
            return;
        }
        sub ACTION_distdir {
            my ($self) = @_;
            $self->depends_on('authortest');
            return $self->SUPER::ACTION_distdir();
        }
    }
);

my $builder = $class->new(
    module_name        => 'XML::TreeBuilder',
    license            => 'perl',
    dist_author        => 'Jeff Fearn <jfearn@cpan.org>',
    dist_version_from  => 'lib/XML/Element.pm',
    create_makefile_pl => 'traditional',
    build_requires     => {
        'Devel::Cover'        => 0,
        'Module::Build'       => 0,
        'Test::Exception'     => 0,
        'Test::More'          => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Perl::Critic'  => 0,
        'XML::Parser'         => 0,
        'HTML::Element'       => 4.1,
        'HTML::Tagset'        => 3.02,
    },
    requires => {
        'XML::Parser'   => 0,
        'HTML::Element' => 4.1,
        'HTML::Tagset'  => 3.02,
        'perl'          => '5.4.0',
    },
    add_to_cleanup =>
        [ 'XML-TreeBuilder-*', 'tmp', 'blib', 'MANIFEST.bak', 'META.yml' ],
    script_files => [],
);

$builder->create_build_script();
