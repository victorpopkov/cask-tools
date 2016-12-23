cask 'global-version-global-appcast' do
  version '1.1.0'

  if Hardware::CPU.is_32_bit? || MacOS.release <= :leopard
    sha256 'cd9d7b8c5d48e2d7f0673e0aa13e82e198f66e958d173d679e38a94abb1b2435'
    url "http://www.fon.hum.uva.nl/praat/praat#{version.no_dots}_mac32.dmg"
  else
    sha256 '9065ae8493fa73bfdf5d29ffcd0012cd343475cf3d550ae526407b9910eb35b7'
    url "http://www.fon.hum.uva.nl/praat/praat#{version.no_dots}_mac64.dmg"
  end

  appcast "https://example.com/sparkle/#{version.major}/appcast.xml",
          checkpoint: '95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7'
  name 'Example'
  homepage 'https://example.com/'
  license :commercial

  auto_updates true

  app 'Example.app'
end
