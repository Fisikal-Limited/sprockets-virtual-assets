module Sprockets::Rails::Helper

  #  Internal method to support multifile debugging. Will
  #  eventually be removed w/ Sprockets 3.x.
  #
  #  This method is patched to pass Rack environment down to asset resolver,
  #  so that it is able to compose the component set required to process this request.
  #
  def lookup_asset_for_path(path, options = {})
    return unless env = assets_environment

    path = path.to_s
    if extname = compute_asset_extname(path, options)
      path = "#{path}#{extname}"
    end

    opts = {}
    opts[:env] = request.env if respond_to?(:request) && !request.nil?

    env.find_asset(path, opts)
  end

  # Expand asset path to digested form.
  #
  # path    - String path
  # options - Hash options
  #
  # Returns String path or nil if no asset was found.
  def asset_digest_path(path, options = {})
    if manifest = assets_manifest
      if digest_path = manifest.assets[path]
        return digest_path
      end
    end

    if environment = assets_environment
      opts = {}
      opts[:env] = request.env if respond_to?(:request) && !request.nil?

      if asset = environment.find_asset(path, opts)
        return asset.digest_path
      end
    end
  end

end
