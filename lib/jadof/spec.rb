# If you want to extend JADOF, you'll probably want to 
# create specs to make sure that your functionality works.
#
# You'll probably also want to run the JADOF specs, as 
# regression tests, so you know if you break any of the 
# core functionality.
#
# For that, we use RSpec shared examples so, in your specs, 
# you can require 'jadof/test' and then add this to your specs:
#
#   it_should_behave_like "JADOF Page"
#
# The shared examples use a few instance variables which you 
# can override.
#
# @root_page_directory
# : the directory to save fake pages in while the 
#   tests run.  these are cleaned up by the tests.
#   default: './jadof_spec_pages/'.  we delete this 
#   directory when running specs do don't use a 
#   directory with things you care about!
#
require 'rubygems'
require 'spec'
require 'fileutils'  # for creating/deleting directories for fake pages
require 'hash-cache' # for testing caching
require 'maruku'     # for testing rendering
require 'erb'        # for testing rendering
require File.dirname(__FILE__) + '/../jadof' unless defined? JADOF
require File.dirname(__FILE__) + '/spec/helpers'
require File.dirname(__FILE__) + '/spec/examples_for_page'
require File.dirname(__FILE__) + '/spec/examples_for_post'
