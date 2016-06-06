#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Karel::UI::Web;
Karel::UI::Web->to_app;
