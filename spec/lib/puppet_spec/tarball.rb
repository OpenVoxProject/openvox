# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

module PuppetSpec
  # Build gzipped tarballs for tests at runtime, so no binary tarball
  # fixtures (with contents that rot and trip security scanners) need to
  # be checked in.
  module Tarball
    module_function

    # Create a gzipped tarball at +path+ from a hash mapping entry names to
    # file contents. Entries with nil content are created as directories.
    #
    # @return [String] the path to the created tarball
    def create(path, entries)
      File.open(path, 'wb') do |io|
        Zlib::GzipWriter.wrap(io) do |gz|
          Gem::Package::TarWriter.new(gz) do |tar|
            entries.each do |name, content|
              if content.nil?
                tar.mkdir(name, 0o755)
              else
                tar.add_file_simple(name, 0o644, content.bytesize) do |file|
                  file.write(content)
                end
              end
            end
          end
        end
      end
      path
    end
  end
end
