#!/bin/bash
gvim -p test_scatwrap.pl test_parameters.yaml ScatWrap/DDSCAT.pm ScatWrap/IO.pm ScatWrap/Math.pm ScatWrap/Shape.pm create_tables.pl database_schema.yaml Changelog

