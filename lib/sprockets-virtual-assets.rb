require 'sprockets/hooks/environment'
require 'sprockets/hooks/index'
require 'sprockets/hooks/server'
require 'sprockets/hooks/helper'

require 'sprockets/virtual_asset'
require 'sprockets/virtual_sass_asset'

module SprocketsVirtualAssets

  class << self

    cattr_accessor :virtuals

    #  Registers a virtual asset named <tt>name</tt>
    #
    def virtualize(name, &block)
      self.virtuals ||= {}
      self.virtuals[name] = block
    end

  end

end
