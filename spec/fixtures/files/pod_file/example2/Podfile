platform :osx, '10.7'

pod 'AFNetworking'
pod 'FormatterKit'
pod 'ISO8601DateFormatter'
#pod 'CorePlot', '1.0'

pod do |spec|
  spec.name         = 'NoodleKit'
  spec.version      = '0.0.1'
  spec.source       = { :git => 'https://github.com/Induction/NoodleKit.git',
                        :commit => '85a3ddbb5b0f7bf117e120a8febb3c1b62192a4e'
                      }
  spec.source_files = '*.{h,m}'
  spec.clean_paths  = %w{English.lproj Examples NoodleKit.xcodeproj Info.plist README.md version.plist}
end

pod do |spec|
  spec.name         = "DMInspectorPalette"
  spec.version      = '0.0.1'
  spec.source       = {
                        :git => 'https://github.com/malcommac/DMInspectorPalette.git'
                      }
  spec.source_files = 'DMInspectorPalette/core'
  spec.requires_arc = true
end

pod do |spec|
  spec.name         = "InspectorTabBar"
  spec.version      = '0.0.1'
  spec.source       = {
                        :git => 'https://github.com/smic/InspectorTabBar.git'
                      }
  spec.source_files = ['InspectorTabBar/SMBar.{h,m}', 'InspectorTabBar/SMTabBar.{h,m}', 'InspectorTabBar/SMTabBarItem.{h,m}', 'InspectorTabBar/SMTabBarButtonCell.{h,m}', 'InspectorTabBar/NSDictionary+SMKeyValueObserving.{h,m}']
  spec.requires_arc = true
end
