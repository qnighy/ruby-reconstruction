# frozen_string_literal: true

require "tmpdir"
require "fileutils"

module RubyReconstruction
  class Patcher
    BUILD_ARTIFACTS = [
      "Makefile",
      "ext/Makefile",
      "ext/extmk.rb",
      "config.cache",
      "config.h",
      "config.log",
      "config.status",
      "ruby",
      /\.o$/,
    ].freeze

    PATCHES = []

    def self.sync_patched(src, dest)
      FileUtils.mkdir_p dest

      Dir.mktmpdir do |tmpdir|
        tmp_dest = "#{tmpdir}/ruby"
        make_patched(src, tmp_dest)
        sync(tmp_dest, dest)
      end
    end

    def self.sync(src, dest)
      ours = Dir.glob("**/*", base: src).select { |path|
        BUILD_ARTIFACTS.none? { |artifact| artifact === path }
      }
      theirs = Dir.glob("**/*", base: dest).select { |path|
        BUILD_ARTIFACTS.none? { |artifact| artifact === path }
      }
      ours.each do |path|
        if File.directory?("#{src}/#{path}")
          $stderr.puts "mkdir #{path}" unless File.exist?("#{dest}/#{path}")
          FileUtils.mkdir_p "#{dest}/#{path}"
        else
          if !File.exist?("#{dest}/#{path}") || File.binread("#{src}/#{path}") != File.binread("#{dest}/#{path}")
            $stderr.puts "update #{path}"
            FileUtils.cp "#{src}/#{path}", "#{dest}/#{path}"
          end
        end
      end
      (theirs - ours).each do |path|
        $stderr.puts "rm#{File.directory?("#{dest}/#{path}") ? "dir" : ""} #{path}"
        FileUtils.rm_rf "#{dest}/#{path}"
      end
    end

    def self.make_patched(src, dest)
      FileUtils.rm_rf(dest)
      FileUtils.cp_r(src, dest)
      patch!(dest)
    end

    def self.patch!(dir)
      new(dir).patch!
    end

    attr_reader :dir

    def initialize(dir)
      @dir = dir
    end

    def patch!
      PATCHES.each do |patch|
        send(patch)
      end
    end

    def self.register(patch)
      PATCHES << patch
    end

    # Utilities

    def rewrite_file(rel_path)
      return unless exist?(rel_path)

      src = -binread(rel_path)
      src2 = yield(src)
      binwrite(rel_path, src2) if src != src2
    end

    def exist?(rel_path)
      File.exist?("#{dir}/#{rel_path}")
    end

    def binread(rel_path)
      File.binread("#{dir}/#{rel_path}")
    end

    def binwrite(rel_path, src)
      File.binwrite("#{dir}/#{rel_path}", src)
    end

    def mkdir_p(rel_path)
      FileUtils.mkdir_p("#{dir}/#{rel_path}")
    end
  end
end
