#!/usr/bin/perl -w
#use lib '../blib/lib', '../blib/arch';

use strict;
use AlgorithmMy::DecisionTree;
use DBI;
use DBD::InterBase;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp  qw(fatalsToBrowser);
use POSIX;
require 'common_func.pl';
require 'construct_dt_and_classify_one_sample.pl';
construct_dt();
#файл с входной выборкой