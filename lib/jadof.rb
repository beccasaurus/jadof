$LOAD_PATH.unshift File.dirname(__FILE__)

require 'indifferent-variable-hash'

# Just A Directory Of Files
#
# See {JADOF::Page} and {JADOF::Post}
#
module JADOF
end

require 'jadof/page'
require 'jadof/post'
