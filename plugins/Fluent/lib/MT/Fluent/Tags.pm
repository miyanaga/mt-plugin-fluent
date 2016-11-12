package MT::Fluent::Tags;

use strict;
use warnings;

sub function_FluentAction {
    my ( $ctx, $args ) = @_;
    $ctx->var('fluent_action');
}

1;
