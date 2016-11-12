package MT::Fluent::Archive;

use strict;
use warnings;

use MT::Util;
use MT::Fluent::Util;

sub on_build_file {
    my ( $cb, %args ) = @_;

    my $entry = $args{Entry};
    post('publish', $entry) if $entry;

    1;
}

sub on_post_delete_archive_file {
    my ( $cb, $file, $at, $entry ) = @_;

    post('delete', $entry) if $entry && $at =~ /^(Individual|Page)$/i;

    1;
}

sub post {
    my ( $action, $entry ) = @_;
    my $blog = $entry->blog;
    my $config = plugin_config($blog->id);

    my $prefix = $entry->is_entry ? 'fluent_entry' : 'fluent_page';
    return unless $config->{$prefix};

    my $tag = $config->{"${prefix}_tag"} || 'mt.archive';
    my $template_id = $config->{"${prefix}_template_id"} || return;
    my $template = MT->model('template')->load({ id => $template_id }) || return;

    require MT::Builder;
    require MT::Template::Context;
    my $builder = MT::Builder->new;
    my $ctx = MT::Template::Context->new;

    $ctx->{__stash}->{blog} = $blog;
    $ctx->{__stash}->{entry} = $entry;
    $ctx->var('fluent_action', $action);

    my $tokens = $builder->compile($ctx, $template->text);
    unless ( $tokens ) {
        mt_log(plugin->translate('Error in Fluent message template compile: [_1]', $builder->errstr), {
            blog => $blog, level => 'error',
        });
        return;
    }

    my $result = $builder->build($ctx, $tokens);
    unless ( defined($result) ) {
        mt_log(plugin->translate('Error in Fluent message building: [_1]', $builder->errstr), {
            blog => $blog, level => 'error',
        });
        return;
    }

    my $json = eval { MT::Util::from_json($result); };
    unless ( $json ) {
        mt_log(plugin->translate('Error to parse Fluent message JSON.'), {
            blog => $blog, level => 'error', metadata => $result,
        });
        return;
    }

    fluent_log($tag, $json);
}

1;
