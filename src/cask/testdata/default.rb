cask 'default' do
  version '1.1.0'
  sha256 '9065ae8493fa73bfdf5d29ffcd0012cd343475cf3d550ae526407b9910eb35b7'

  url "https://example.com/app_#{version}.dmg"
  appcast "https://example.com/sparkle/#{version.major}/appcast.xml",
          checkpoint: '95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7'
  name 'Example'
  homepage 'https://example.com/'
  license :commercial

  auto_updates true

  app 'Example.app'
end
