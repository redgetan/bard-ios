# Uncomment this line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'Bard' do
  use_frameworks!

  pod 'Player', :git => "https://github.com/redgetan/Player", :branch => "layer_background"
  pod 'RealmSwift', "~> 1.1.0"
  pod 'Alamofire', '~> 3.5'
  pod 'SwiftyDrop', '~> 2.5'
  pod 'KeychainAccess', "~> 2.4.0"
  pod 'HanekeSwift', :git => 'https://github.com/cannyboy/HanekeSwift.git'
  pod 'DZNEmptyDataSet'
  pod 'UICollectionViewLeftAlignedLayout'
  pod 'MBProgressHUD', '~> 1.0.0'
  pod 'TTTAttributedLabel'

  # crash reporting
  pod 'Instabug'

  # analytics
  pod 'Firebase/Core'
  pod 'Firebase/Database'


  # services
  pod 'AWSS3'
  pod 'AWSCognito'

  pod 'SCLAlertView'






end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
