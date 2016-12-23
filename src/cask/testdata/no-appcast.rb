cask 'no-appcast' do
  version '1.1.0'
  sha256 '9065ae8493fa73bfdf5d29ffcd0012cd343475cf3d550ae526407b9910eb35b7'

  url "https://example.com/app_#{version}.dmg"
  name 'Example'
  homepage 'https://example.com/'
  license :commercial

  app 'Example.app'
end
