#!/usr/bin/env ruby

require 'pp'

A = -> {|x| x + 1 }.freeze

pp A[2]
