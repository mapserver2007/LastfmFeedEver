# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/lib"
require 'lastfmfeedever'
require 'rspec/core/rake_task'
require 'yaml'

task:default => [:spec, :github_push, :heroku_deploy]

Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['-cfs']
end

task :github_push => [:spec] do
  sh 'git push origin master'
end

task :heroku_deploy => [:github_push] do
  sh 'git push heroku master'
end

task :heroku_env do
  config = YAML.load_file(File.dirname(__FILE__) + "/config/evernote.yml")
  config.each do |key, value|
    sh "heroku config:add #{key}=#{value}"
  end
end

