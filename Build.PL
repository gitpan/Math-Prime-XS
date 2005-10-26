# Note: this file has been initially created by Make::Build::Convert 0.20_05

use 5.008007;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Math::Prime::XS',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Math/Prime/XS.pm',
   requires => {},
   recommends => {},
   build_requires => {},
   conflicts => {},
   include_dirs => '-I.',
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'passthrough',
  );
  
$build->create_build_script;
