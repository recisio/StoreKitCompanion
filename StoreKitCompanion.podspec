Pod::Spec.new do |s|

# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.name            	= "StoreKitCompanion"
s.module_name      	= "StoreKitCompanion"
s.version          	= "1.0"
s.summary          	= "A lightweight wrapper for Apple's StoreKit, written in Swift."
s.description      	= "A lightweight wrapper for Apple's StoreKit, written in Swift."
s.homepage         	= "https://github.com/recisio/StoreKitCompanion"
s.license      		= { :type => "MIT", :file => "LICENSE" }
s.author           	= { "Recisio" => "vincent@recisio.com" }
s.source           	= { :git => "https://github.com/recisio/StoreKitCompanion.git", :tag => "#{s.version}" }

# ―――  Spec tech  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.dependency                  'Alamofire'
s.ios.deployment_target		= '8.0'
s.tvos.deployment_target 	= '9.0'
s.osx.deployment_target 	= '10.10'

s.requires_arc 	   			= true
s.source_files				= 'Source/*.swift'

end
