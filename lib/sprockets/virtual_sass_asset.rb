module VirtualAssets
  #  Implements a virtual sass asset, which @imports rather than //=requires depdencies.
  #  This makes possible to implement white-labeling in an elegant manner.
  #
  class VirtualSassAsset < SprocketsVirtualAssets::VirtualAsset

    #  Initializes the asset.
    #
    def initialize(environment, path, dependencies, pseudo_path)
      super(environment, path, [], "text/css")

      @pseudo_path = pseudo_path

      @environment = environment
      @imports = dependencies.map { |file| file.gsub('.css', '') }

      compute_digest

      compile
    end

    #  Computes the digest of this asset.
    #
    def compute_digest
      @digest = @environment.digest.update(@imports.map do |import|
        asset = @environment.find_asset(import + ".css")
        # source of the processed item would remain the same in case we edit mixins inside - account
        # mtime into digest
        [asset.digest, asset.mtime.to_i.to_s].join("@")
      end.join("+")).hexdigest
    end

    #  Compiles the asset if required.
    #
    def compile
      key = "styles.css/#{@digest}"

      unless @source = @environment.cache_get(key)
        pseudo_path = File.expand_path(@pseudo_path)
        context = @environment.context_class.new(@environment, @logical_path, pseudo_path)

        source = @imports.map { |import| "@import \"#{import}\";" }.join("\n")
        @source = context.evaluate(pseudo_path, data: source)

        @environment.cache_set(key, @source)
      end

      @length = Rack::Utils.bytesize(@source)
    end

    #  The SCSS asset holds the content itself.
    #
    def to_a
      [self]
    end

  end
end
