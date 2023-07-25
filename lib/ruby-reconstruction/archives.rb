# frozen_string_literal: true

module RubyReconstruction
  module Archives
    RUBY_ARCHIVES = [
      "ruby-0.49.tar.gz",
      "ruby-0.50.tar.gz",
      "ruby-0.51-0.52.diff.gz",
      "ruby-0.51.tar.gz",
      "ruby-0.54.tar.gz",
      "ruby-0.55-0.56.diff.gz",
      "ruby-0.55.tar.gz",
      "ruby-0.60.tar.gz",
      "ruby-0.62.tar.gz",
      "ruby-0.62.tar.gz.broken",
      "ruby-0.63.tar.gz",
      "ruby-0.63.tar.gz.broken",
      "ruby-0.64.tar.gz",
      "ruby-0.65-0.66.diff.gz",
      "ruby-0.65.tar.gz",
      "ruby-0.66-0.67.diff.gz",
      "ruby-0.67-0.68.diff.gz",
      "ruby-0.69.tar.gz",
      "ruby-0.70-patch",
      "ruby-0.71-0.72.diff.gz",
      "ruby-0.71.tar.gz",
      "ruby-0.73-950413.tar.gz",
      "ruby-0.73.tar.gz",
      "ruby-0.76.tar.gz",
      "ruby-0.95.tar.gz",
      "ruby-0.99.4-961224.tar.gz",
      "ruby-1.0-961225.tar.gz",
      "ruby-1.0-971002.tar.gz",
      "ruby-1.0-971003.tar.gz",
      "ruby-1.0-971015.tar.gz",
      "ruby-1.0-971021.tar.gz",
      "ruby-1.0-971118.tar.gz",
      "ruby-1.0-971125.tar.gz",
      "ruby-1.0-971204.tar.gz",
      "ruby-1.0-971209.tar.gz",
      "ruby-1.0-971225.tar.gz",
    ].freeze

    ARCHIVED_VERSIONS = [
      "0.49",
      "0.50",
      "0.51",
      "0.52", # diff from 0.51
      "0.54",
      "0.55",
      "0.56", # diff from 0.55
      "0.60",
      "0.62",
      "0.63",
      "0.64",
      "0.65",
      "0.66", # diff from 0.65
      "0.67", # diff from 0.66
      "0.68", # diff from 0.67
      "0.69",
      "0.70", # diff from 0.69
      "0.71",
      "0.72", # diff from 0.71
      "0.73-950413",
      "0.73",
      "0.76",
      "0.95",
      "0.99.4-961224",
      "1.0-961225",
      "1.0-971002",
      "1.0-971003",
      "1.0-971015",
      "1.0-971021",
      "1.0-971118",
      "1.0-971125",
      "1.0-971204",
      "1.0-971209",
      "1.0-971225",
    ].freeze

    DIRECT_ARCHIVED_VERSIONS = \
      ARCHIVED_VERSIONS.select { |version| RUBY_ARCHIVES.include?("ruby-#{version}.tar.gz") }.freeze

    def self.dependencies(version)
      case version
      when *DIRECT_ARCHIVED_VERSIONS
        ["ruby-#{version}.tar.gz"]
      when "0.52"
        [*dependencies("0.51"), "ruby-0.51-0.52.diff.gz"]
      when "0.56"
        [*dependencies("0.55"), "ruby-0.55-0.56.diff.gz"]
      when "0.66"
        [*dependencies("0.65"), "ruby-0.65-0.66.diff.gz"]
      when "0.67"
        [*dependencies("0.66"), "ruby-0.66-0.67.diff.gz"]
      when "0.68"
        [*dependencies("0.67"), "ruby-0.67-0.68.diff.gz"]
      when "0.70"
        [*dependencies("0.69"), "ruby-0.70-patch"]
      when "0.72"
        [*dependencies("0.71"), "ruby-0.71-0.72.diff.gz"]
      else
        raise "Unknown version: #{version}"
      end
    end

    def self.extract(version, dest, archive_dir:)
      case version
      when *DIRECT_ARCHIVED_VERSIONS
        FileUtils.rm_rf dest
        FileUtils.mkdir_p dest
        components = \
          if `tar -tzf #{archive_dir}/ruby-#{version}.tar.gz`.include?("./ruby")
            # "." is also part of the components
            2
          else
            1
          end
        system "tar -xzf #{archive_dir}/ruby-#{version}.tar.gz -C #{dest} --strip-components #{components}", exception: true
      when "0.52"
        extract("0.51", dest, archive_dir: archive_dir)
        system "gzip -dc #{archive_dir}/ruby-0.51-0.52.diff.gz | patch -p1 -d #{dest} -s", exception: true
      when "0.56"
        extract("0.55", dest, archive_dir: archive_dir)
        system "gzip -dc #{archive_dir}/ruby-0.55-0.56.diff.gz | patch -p1 -d #{dest} -s", exception: true
      when "0.66"
        extract("0.65", dest, archive_dir: archive_dir)
        system "gzip -dc #{archive_dir}/ruby-0.65-0.66.diff.gz | patch -p1 -d #{dest} -s", exception: true
      when "0.67"
        extract("0.66", dest, archive_dir: archive_dir)
        system "gzip -dc #{archive_dir}/ruby-0.66-0.67.diff.gz | patch -p1 -d #{dest} -s", exception: true
      when "0.68"
        extract("0.67", dest, archive_dir: archive_dir)
        system "gzip -dc #{archive_dir}/ruby-0.67-0.68.diff.gz | patch -p1 -d #{dest} -s", exception: true
      when "0.70"
        extract("0.69", dest, archive_dir: archive_dir)
        system "patch -p1 -d #{dest} < #{archive_dir}/ruby-0.70-patch", exception: true
      when "0.72"
        extract("0.71", dest, archive_dir: archive_dir)
        system "gzip -dc #{archive_dir}/ruby-0.71-0.72.diff.gz | patch -p1 -d #{dest} -s", exception: true
      else
        raise "Unknown version: #{version}"
      end
    end
  end
end
