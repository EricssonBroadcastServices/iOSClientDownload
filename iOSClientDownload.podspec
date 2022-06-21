Pod::Spec.new do |spec|
spec.name         = "iOSClientDownload"
spec.version      = "3.0.200"
spec.summary      = "RedBeeMedia iOS SDK Download Module"
spec.homepage     = "https://github.com/EricssonBroadcastServices"
spec.license      = { :type => "Apache", :file => "https://github.com/EricssonBroadcastServices/iOSClientDownload/blob/master/LICENSE" }
spec.author             = { "EMP" => "jenkinsredbee@gmail.com" }
spec.documentation_url = "https://github.com/EricssonBroadcastServices/iOSClientDownload/blob/master/README.md"
spec.platforms = { :ios => "11.0" }
spec.source       = { :git => "https://github.com/EricssonBroadcastServices/iOSClientDownload.git", :tag => "v#{spec.version}" }
spec.source_files  = "Sources/iOSClientDownload/**/*.swift"
end
