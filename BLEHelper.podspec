Pod::Spec.new do |s|
  s.name         = "BLEHelper"
  s.version      = "1.0.2"
  s.summary      = "An elegant way to deal with your Bluetooth Low Energy device"
  s.homepage     = "https://github.com/HarveyHu/BLEHelper"
  s.license      = "MIT"
  s.authors      = { 'Harvey Hu' => 'spot0206@gmail.com'}
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/HarveyHu/BLEHelper.git", :tag => s.version }
  s.source_files = 'BLEHelper/**/*.swift'
  s.requires_arc = true
end
