cask 'three-versions-one-appcast' do
  if MacOS.release <= :tiger
    version '0.9.0'
    sha256 '82adf42ce6031ab59a3072e607788e73f594ad5f21c7118aabc6c5dafe3d0b47'
  elsif MacOS.release <= :leopard
    version '1.1.0'
    sha256 '9065ae8493fa73bfdf5d29ffcd0012cd343475cf3d550ae526407b9910eb35b7'
  else
    version '1.9.0'
    sha256 '08ec271c56e5fda2fe3eee73289f0994084ecc3ce0ebffbc8dac3444f00ad41c'

    appcast "https://example.com/sparkle/#{version.major}/appcast.xml",
            checkpoint: '95ffe5b581434db6284ed8dfe0cddead69a5d3f7269ca488baba3bd1218e43f7'
  end

  url "https://example.com/app_#{version}.dmg"
  name 'Example'
  homepage 'https://example.com/'
  license :commercial

  app 'Example.app'
end
