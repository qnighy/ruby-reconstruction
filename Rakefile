# frozen_string_literal: true

require_relative "lib/ruby-reconstruction"

directory "archives"

RubyReconstruction::Archives::RUBY_ARCHIVES.each do |archive|
  file "archives/#{archive}" => "archives" do
    sh "curl --proto '=https' --tlsv1.2 -sSf -o archives/#{archive} https://cache.ruby-lang.org/pub/ruby/1.0/#{archive}"
  end
end

RubyReconstruction::Archives::ARCHIVED_VERSIONS.each do |version|
  namespace :checkout do
    deps = RubyReconstruction::Archives.dependencies(version).map { |name| "archives/#{name}" }
    desc "Checkout Ruby #{version}"
    task version => deps do
      RubyReconstruction::Archives.extract(version, "ruby", archive_dir: "archives")
    end
  end
end

task "sync" do
  RubyReconstruction::Patcher.sync_patched("ruby", "build/ruby")
end

task "configure" => "sync" do
  Dir.chdir("build/ruby") do
    sh "CC='gcc -m32 -g -O0' LDSHARED='gcc -m32 -shared' setarch i386 ./configure --prefix=#{Dir.pwd}/build/ruby"
  end
end

task "build" => "sync" do
  Dir.chdir("build/ruby") do
    sh "CC='gcc -m32 -g -O0' LDSHARED='gcc -m32 -shared' setarch i386 make"
  end
end
