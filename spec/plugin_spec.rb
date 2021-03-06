require File.dirname(__FILE__) + '/base'

module Heroku
	describe Plugin do
		include SandboxHelper

		it "lives in ~/.heroku/plugins" do
			Plugin.stub!(:home_directory).and_return('/home/user')
			Plugin.directory.should == '/home/user/.heroku/plugins'
		end

		it "extracts the name from git urls" do
			Plugin.new('git://github.com/heroku/plugin.git').name.should == 'plugin'
		end

		describe "management" do
			before(:each) do
				@sandbox = "/tmp/heroku_plugins_spec_#{Process.pid}"
				FileUtils.mkdir_p(@sandbox)
				Dir.stub!(:pwd).and_return(@sandbox)
				Plugin.stub!(:directory).and_return(@sandbox)
			end

			after(:each) do
				FileUtils.rm_rf(@sandbox)
			end

			it "lists installed plugins" do
				FileUtils.mkdir_p(@sandbox + '/plugin1')
				FileUtils.mkdir_p(@sandbox + '/plugin2')
				Plugin.list.should == %w( plugin1 plugin2 )
			end

			it "installs pulling from the plugin url" do
				plugin_folder = "/tmp/heroku_plugin"
				FileUtils.mkdir_p(plugin_folder)
				`cd #{plugin_folder} && git init && echo 'test' > README && git add . && git commit -m 'my plugin'`
				Plugin.new(plugin_folder).install
				File.directory?("#{@sandbox}/heroku_plugin").should be_true
				File.read("#{@sandbox}/heroku_plugin/README").should == "test\n"
			end

			it "uninstalls removing the folder" do
				FileUtils.mkdir_p(@sandbox + '/plugin1')
				Plugin.new('git://github.com/heroku/plugin1.git').uninstall
				Plugin.list.should == []
			end

			it "adds the lib folder in the plugin to the load path, if present" do
				FileUtils.mkdir_p(@sandbox + '/plugin/lib')
				File.open(@sandbox + '/plugin/lib/my_custom_plugin_file.rb', 'w') { |f| f.write "" }
				Plugin.load!
				lambda { require 'my_custom_plugin_file' }.should_not raise_error(LoadError)
			end

			it "loads init.rb, if present" do
				FileUtils.mkdir_p(@sandbox + '/plugin')
				File.open(@sandbox + '/plugin/init.rb', 'w') { |f| f.write "LoadedInit = true" }
				Plugin.load!
				LoadedInit.should be_true
			end
		end
	end
end
