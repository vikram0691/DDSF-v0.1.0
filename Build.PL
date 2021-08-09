use v5.014;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DDSF',
    license             => 'artistic_2',
    dist_author         => [ q{Vikram Singh <vikram.singh7571@gmail.com>}, 'Vikram Singh, PhD' ],
    dist_version_from   => 'lib/DDSF.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
        'Math::Random' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'DDSF-*' ],
);

$builder->create_build_script();
