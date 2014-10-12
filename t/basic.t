use strict;
use warnings;

use Test::More;
use Dist::Zilla::App::Tester;
use Dist::Zilla::Util::Test::KENTNL 1.003001 qw( dztest );
use Dist::Zilla::Plugin::GatherDir;
use Test::DZil qw( simple_ini );

my $test = dztest();
$test->add_file( 'dist.ini' => simple_ini( ['GatherDir'] ) );
$test->add_file( 'perlcritic.rc' => <<'EOF' );

EOF
$test->add_file( 'lib/Example.pm' => <<'EOF' );
use strict;
use warnings;

package Example;

1;
EOF

my $result = test_dzil( $test->tempdir, ['critic'] );
ok( ref $result, 'self-test executed' );
is( $result->error,     undef, 'no errors' );
is( $result->exit_code, 0,     'exit == 0' );
note( $result->stdout );

done_testing;

