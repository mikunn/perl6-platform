use v6;
use Text::Wrap;

class Platform::Container {

    has Str $.name is rw;
    has Str $.hostname is rw;
    has Str $.domain = 'local';
    has Str $.data-path is rw;
    has Str $.projectdir;
    has Hash $.config-data;
    has Proc $.last-proc is rw;
    has %.last-result;

    method result-as-hash($proc) {
        my $out = $proc.out.slurp-rest;
        my $err = $proc.err.slurp-rest;
        my %result =
            ret => $err.chars == 0,
            out => $out,
            err => $err
        ;
    }

    method last-command($proc?) {
        my $curr-proc = $proc ?? $proc !! $.last-proc;
        %.last-result = self.result-as-hash($curr-proc);
        $.last-proc = $curr-proc;
        self;
    }

    method as-string {
        my @lines;
        @lines.push: sprintf("├─ Container: %-8s     [%s]",
            $.name,
            %.last-result<err>.chars == 0 ?? "\c[heavy check mark]" !! "\c[heavy multiplication x]"
            );
        @lines.push: "│  └─ " ~ join("\n│     ", wrap-text(%.last-result<err>).lines) if %.last-result<err>.chars > 0;
        @lines.join("\n");
    }

}
