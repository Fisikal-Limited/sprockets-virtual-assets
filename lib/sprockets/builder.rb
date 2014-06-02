module SprocketsVirtualAssets

    #  Represents a builder object responsible for providing
    #  meta information about a virtual asset as well as
    #  resolving it down to a an Sprockets::Asset subclass.
    #
    class Builder

      #  Represents virtual stat sturcture.
      #
      class Stat < Struct.new(:mtime, :directory?, :file?)
      end

      #  Holds raw options of the asset.
      attr_accessor :options

      #  Initializes the builder object.
      #  The source code assumed to be result of the yield.
      #
      def initialize(options = {})
        self.options = options
      end

      #  Represents a virtual source code for this asset.
      #
      def virtual_source
        @virtual_source ||= begin
          dependencies.inject("") do |source, dep|
            source + options[:require_term].gsub("__FILE__", dep) + "\n"
          end
        end
      end

      #  Mocks #stat'ting the virtual asset.
      #
      def stat
        mtime = dependencies.map { |path| environment.find_asset(path, bundle: false).mtime }.max
        Stat.new( mtime, false, true )
      end

      #  Returns digest of the asset.
      #
      def digest
        environment.digest.update(virtual_source)
      end

      #  Returns an array of files to be included.
      #
      def dependencies
        options[:dependencies]
      end

      #  Returns virtual path to be used.
      #
      def virtual_path
        options[:virtual_path]
      end

      #  Returns original path this asset is handled via.
      #
      def path
        options[:path]
      end

      #  Returns content type of the asset.
      #
      def content_type
        options[:content_type]
      end

      #  Returns Sprocket environment.
      #
      def environment
        options[:environment]
      end

      #  Creates an Asset object.
      #
      def asset
        key = "virtual-asset/#{ digest }-#{ path }-#{ stat.mtime.to_i }-#{ options[:bundle] }"

        asset = if data = environment.cache_get(key)
          ::SprocketsVirtualAssets::VirtualAsset.load(data, environment)
        else
          nil
        end

        asset = nil unless asset.try(:fresh?, environment)
        asset ||= ::SprocketsVirtualAssets::VirtualAsset.new(virtual_source, environment, path, virtual_path, options)

        environment.cache_set key, asset.dump

        asset
      end

    end

end