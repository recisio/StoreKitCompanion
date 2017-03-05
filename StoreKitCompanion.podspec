Pod::Spec.new do |s|

# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.name            	= "StoreKitCompanion"
s.module_name      	= "StoreKitCompanion"
s.version          	= "1.0.1"
s.summary          	= "A lightweight wrapper for Apple's StoreKit, written in Swift."
s.description      	= "A lightweight wrapper for Apple's StoreKit, written in Swift. For iOS and OS X"
s.homepage         	= "https://github.com/recisio/StoreKitCompanion"
s.license      		= { :type => "MIT", :file => "LICENSE" }
s.author           	= { "Recisio" => "vincent@recisio.com" }
s.source           	= { :git => "https://github.com/recisio/StoreKitCompanion.git", :tag => "#{s.version}" }

# ―――  Spec tech  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.ios.deployment_target		= '8.0'
s.osx.deployment_target 	= '10.10'

s.requires_arc 	   			= true
s.source_files				= 'Source/*.swift'

end
