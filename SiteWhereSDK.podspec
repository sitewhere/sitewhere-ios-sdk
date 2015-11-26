Pod::Spec.new do |s|

# Root specification

s.name                  = "SiteWhereSDK"
s.version               = "1.0"
s.summary               = "iOS SDK for the SiteWhere API"
s.homepage              = "https://github.com/sitewhere"
s.license               = { :type => "Apache 2.0", :file => "LICENSE" }
s.author                = "SiteWhere"
s.source                = { :git => "", :tag => "v#{s.version}" }
s.dependency            'MQTTKit'
s.dependency            'Protobuf', "3.0.0-alpha-4.1"

s.subspec 'no-arc' do |sp|
    sp.source_files = 'SiteWhereSDK/SiteWhereSDK/Sitewhere.pbobjc.m'
    sp.requires_arc = false
  end
# Platform

s.ios.deployment_target = "8.0"

# File patterns

s.ios.source_files        = "SiteWhereSDK/SiteWhereSDK/*.{h,m}" 
s.ios.public_header_files = "SiteWhereSDK/SiteWhereSDK/*.h" 

# Build settings

#s.ios.frameworks        = "Security", "QuartzCore", "AssetsLibrary"
s.requires_arc          = true
#s.xcconfig              = { "OTHER_LDFLAGS" => "-ObjC -all_load" }
s.ios.header_dir        = "SiteWhereSDK"
s.module_name           = "SiteWhereSDK"

# Subspecs

end
