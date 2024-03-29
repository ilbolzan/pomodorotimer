require 'rake/clean'
require 'rake/packagetask'
require 'yaml'
require File.expand_path('../tools/Rake/msbuild')
require File.expand_path('../tools/Rake/xunit')
require File.expand_path('../tools/Rake/string')
require File.expand_path('../tools/Rake/assemblyinfo')
require File.expand_path('../tools/Rake/task')
require File.expand_path('../tools/Rake/ilmerge')
require File.expand_path('../tools/Rake/teamcity') if ENV['TEAMCITY_PROJECT_NAME']
require File.expand_path('bootstrap')

Rake.application.options.trace = $config['trace']

CLEAN.exclude('**/core')
CLEAN.include('**/obj'.in($config['source_dir']))
CLOBBER.include($config['build_dir_root'])
CLOBBER.include('**/bin'.in($config['source_dir']))

task :default => [:settings, :'compile:all', :'test:all', :package]

desc 'Displays the build configuration'
task :settings do
	$config.keys.sort.each do |key|
		puts "#{key}: #{$config[key]}\n"
	end
end

namespace :generate do
	Rake::AssemblyInfo.new(:versioninfo ) do |t|
		t.file = 'VersionInfo.cs'.in($config['source_dir'])
		t.attributes = {
			:AssemblyFileVersion => $config['build_number'],
			:AssemblyVersion => $config['build_number']
		}
	end
end

namespace :compile do
	desc 'Compiles everything'
	task :all => [:app, :tests]
	
	Rake::MsBuild.new(:app) do |t|
		t.dependsUpon = :'generate:versioninfo'
		t.project = 'PomodoroTimer/**/*.csproj'.in($config['source_dir'])
		t.configuration = $config['build_configuration']
		t.out_dir = 'PomodoroTimer'.in($config['build_dir'])
		t.out_dir = $config['build_dir']
	end
	
	Rake::MsBuild.new(:tests) do |t|
		t.dependsUpon = :'generate:versioninfo'
		t.project = 'PomodoroTimer.Tests/**/*.csproj'.in($config['source_dir'])
		t.configuration = $config['build_configuration']
		t.out_dir = 'Tests'.in($config['build_dir'])
	end
end

namespace :merge do
    desc "Merges the assemblies"
    task :all => [:'compile:app', :run]
    
    Rake::ILMerge.new(:run) do |t|
        t.toolpath = 'ILMerge/ILMerge.exe'.in($config['tools_dir'])
        t.output_file = 'PomodoroTimerMerged.exe'
        t.allow_wildcards = true
        t.target_kind = 'winexe'
        t.version = $config['build_number']
        t.input_directories = [$config['build_dir']]
        t.input_assemblies = ['PomodoroTimer.exe'.in($config['build_dir']), '*.dll'.in($config['build_dir'])]
    end
end
namespace :test do
	desc "Runs the application's unit tests"
	task :all => [:'compile:tests', :run]
	
	Rake::XUnit.new(:run) do |t|
		t.toolpath = 'xUnit/xunit.console.exe'.in($config['tools_dir'])
		t.assembly = 'Tests/*.Tests.dll'.in($config['build_dir'])
	end
end

Rake::PackageTask.new('PomodoroTimer', $config['build_number']) do |t|
	t.need_zip = true
	t.zip_command = '7-Zip/7za.exe'.in($config['tools_dir']).escape() + ' a '
	t.package_files.include('build/**/*.*')
	t.package_files.exclude('build/**/Tests')
end