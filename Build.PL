use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Number::Denominal',
    license             => 'Artistic_2_0',
    dist_author         => q{Zoffix Znet <zoffix@cpan.org>},
    dist_version_from   => 'lib/Number/Denominal.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                => 1.26,
        'List::ToHumanString' => 1.002,
        'Exporter'            => 0,
        'perl'                => '5.006',
    },
    add_to_cleanup     => [ 'Number-Denominal-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/Number/Denominal.pm > README');
}

$builder->create_build_script();
