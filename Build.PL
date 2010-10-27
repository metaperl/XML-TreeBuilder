use strict;
use warnings;
use Module::Build;
use 5.004;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
    }
);

my $builder = $class->new(
    module_name       => 'XML::TreeBuilder',
    license           => 'perl',
    dist_author       => 'Jeff Fearn <Jeff.Fearn@gmail.com>',
    dist_version_from => 'lib/XML/Element.pm',
	create_makefile_pl => 'traditional',
    build_requires    => {
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
