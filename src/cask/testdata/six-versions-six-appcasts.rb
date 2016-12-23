cask 'six-versions-six-appcasts' do
  if MacOS.release == :snow_leopard
    version '0.1.0'
    sha256 '630fc5236e95d5ec36c0de4b487f8ece76d8f02ecd00ec4b37124ddd0eed0f34'

    url "https://example.com/app_#{version}.dmg"
    appcast "https://example.com/sparkle/#{version.major}/snowleopard.xml",
            checkpoint: '3fb0fdcd252f0d0898076a66c3ad3ef045590a82abc9c9789bc1d7fdd0dc21f0'
  elsif MacOS.release == :lion
    version '0.2.0'
    sha256 '9fa8ff2ade1face0a1a36baf36cfa384535179b261716c18538b0102f281ee60'

    url "https://example.com/app_#{version}.dmg"
    appcast "https://example.com/sparkle/#{version.major}/lion.xml",
            checkpoint: '81397ad4229e65572fb5386f445e7ecfdfc2161c51ce85747d2b4768b419984e'
  elsif MacOS.release == :mountain_lion
    version '0.3.0'
    sha256 '309bac603a6ded301e9cc61b32bb522fc3a5208973cbd6c6f1a09d0e2c78d1e6'

    url "https://example.com/app_#{version}.dmg"
    appcast "https://example.com/sparkle/#{version.major}/mountainlion.xml",
            checkpoint: '916ed186f168a0ce5072beccb6e17f6f1771417ef3769aabff46d348f79b4c66'
  elsif MacOS.release == :mavericks
    version '0.4.0'
    sha256 'b8b5c37df3a2c44406f9fdf1295357d03b8fca6a9112b61401f0cca2b8e37033'

    url "https://example.com/app_#{version}.dmg"
    appcast "https://example.com/sparkle/#{version.major}/mavericks.xml",
            checkpoint: '9a81f957ef6be7894a7ee7bd68ce37c4b5c6062560c9ef6c708c1cb3270793cc'
  elsif MacOS.release == :yosemite
    version '0.5.0'
    sha256 '424df8d4c3834ffa169bbc00138cb007bf6a435fb216dea928a2c05ef54a6d3b'

    url "https://example.com/app_#{version}.dmg"
    appcast "https://example.com/sparkle/#{version.major}/yosemite.xml",
            checkpoint: '3618d6152a3a32bc2793e876f1b89a485b2160cc43ba44e17141497fe7e04301'
  else
    version '1.1.0'
    sha256 '9065ae8493fa73bfdf5d29ffcd0012cd343475cf3d550ae526407b9910eb35b7'

    url "https://example.com/app_#{version}.dmg"
    appcast "https://example.com/sparkle/#{version.major}/elcapitan.xml",
            checkpoint: '95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7'
  end

  name 'Example'
  homepage 'https://example.com/'
  license :commercial

  app 'Example.app'
end
