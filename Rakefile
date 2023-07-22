# frozen_string_literal: true

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
]

directory "archives"

RUBY_ARCHIVES.each do |archive|
  file "archives/#{archive}" => "archives" do
    sh "curl --proto '=https' --tlsv1.2 -sSf -o archives/#{archive} https://cache.ruby-lang.org/pub/ruby/1.0/#{archive}"
  end
end
