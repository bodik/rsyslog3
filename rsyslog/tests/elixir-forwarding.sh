#!/bin/sh

NOW=$(date +%s)

logger -p auth.info "autotest elixir-forwarding auth.info $NOW"

logger -p local2.info "autotest elixir-forwarding ERROR local3.info $NOW"
logger -p local5.info "autotest elixir-forwarding local5.info $NOW"

logger -t svc123 "autotest elixir-forwarding srv123 $NOW"
logger -t svc456 "autotest elixir-forwarding ERROR srv456 $NOW"


