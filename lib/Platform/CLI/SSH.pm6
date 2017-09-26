unit module Platform::CLI::SSH;

our $data-path;
our $network;
our $domain;

use Platform::Output;
use Terminal::ANSIColor;
use CommandLine::Usage;
use Platform;

#| Wrapper to ssh* commandds
multi cli(
    'ssh',
    'keygen'        #= Generation of authentication keys
    ) is export {
    try {
        CATCH {
            default {
                #.Str.say;
                # say .^name, do given .backtrace[0] { .file, .line, .subname }
                put color('red') ~ "ERROR: $_" ~ color('reset');
                exit;
            }
        }
        Platform.new(:$domain, :$network,:$data-path).ssh('keygen');
    }
}

multi cli(
    'ssh',
    'keygen',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( $*PROGRAM-NAME.IO.basename ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<ssh keygen>
        ).parse.say;
}

multi cli('ssh',
    :h( :help($help) )  #= Print usage
    ) is export {
    CommandLine::Usage.new(
        :name( $*PROGRAM-NAME.IO.basename ),
        :func( &cli ),
        :desc( &cli.candidates[0].WHY.Str ),
        :filter<ssh>
        ).parse.say;
}
