use v6.c;
use lib 't/lib';
use Test;
use Template;
use Docker::Platform::Service::DNS;

my $tmpdir = $*TMPDIR ~ '/test-docker-platform-10-setup';
mkdir $tmpdir;

ok $tmpdir.IO.e, "got $tmpdir";

{ # Setup project files for project-butterfly
    my %project-butterfly =
        title => "Project \c[BUTTERFLY]",
        name => "project-butterfly"
    ;
    mkdir "$tmpdir/project-butterfly/docker";
    spurt "$tmpdir/project-butterfly/docker/Dockerfile", docker-dockerfile(%project-butterfly);
    my $project-yml = q:heredoc/END/;
    command: nginx -g 'daemon off;'
    volumes:
        - html:/usr/share/nginx/html:ro
    END
    spurt "$tmpdir/project-butterfly/docker/project.yml", $project-yml;
    mkdir "$tmpdir/project-butterfly/html";
    spurt "$tmpdir/project-butterfly/html/index.html", html-welcome(%project-butterfly);
}

subtest 'platform start', {
    plan 2;
    my $proc = run <bin/platform>, "--data-path=$tmpdir/.platform", <start>, :out;
    my $out = $proc.out.slurp-rest;
    ok $out ~~ / DNS \s+ \[ \✔ \] /, 'service dns is up';
    ok $out ~~ / Proxy \s+ \[ \✔ \] /, 'service proxy is up';
}

subtest 'platform ssl genrsa', {
    plan 4;
    my $proc = run <bin/platform>, "--data-path=$tmpdir/.platform", <ssl genrsa>, :out, :err;
    my $out = $proc.out.slurp-rest;
    my $err = $proc.err.slurp-rest;

    ok "$tmpdir/.platform/local".IO.e, '<data>/local exists';
    ok "$tmpdir/.platform/local/ssl".IO.e, '<data>/local/ssl exists';
    for <server-key.key server-key.crt> -> $file {
        ok "$tmpdir/.platform/local/ssl/$file".IO.e, "<data>/local/ssl/$file exists";
    }
}

subtest 'platform ssh keygen', {
    plan 3;
    run <bin/platform>, "--data-path=$tmpdir/.platform", <ssh keygen>;
    ok "$tmpdir/.platform/local/ssh".IO.e, '<data>/local/ssh exists';
    for <id_rsa id_rsa.pub> -> $file {
        ok "$tmpdir/.platform/local/ssh/$file".IO.e, "<data>/local/ssh/$file exists";
    }
}

subtest 'platform start project-butterfly', {
    plan 1;
    run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <start>;

    sleep 3; # project to start

    my $proc = run <host project-butterfly.local localhost>, :out;
    my $out = $proc.out.slurp-rest;
    my $found = $out.lines[*-1] ~~ / address \s $<ip-address> = [ \d+\.\d+\.\d+\.\d+ ] $$ /;
    ok $found, 'got ip-address ' ~ ($found ?? $/.hash<ip-address> !! '');
}

subtest 'platform stop project-butterfly', {
    plan 1;
    run <bin/platform>, "--project=$tmpdir/project-butterfly", "--data-path=$tmpdir/.platform", <stop>;
    # TODO: get result from <docker ps>
    ok True, 'project stopped';
}

# $proc.out.close;
#say $proc.out.slurp-rest;

# TODO: docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy

# Start project
# TODO: run <bin/platform start>, $tmpdir/project-butterfly
# TODO: run <bin/platform start>, $tmpdir/*

# Platform project-snail
#mkdir "$tmpdir/project-snail/docker";
#spurt "$tmpdir/project-snail/docker/Makefile", docker-makefile("Project \c[SNAIL]");

run <bin/platform stop>, :out;
run <rm -rf>, $tmpdir;
# say $tmpdir;
