require "rubygems"
require 'nokogiri'
require 'open-uri'
require "active_model"
require 'digest/md5'
require "logger"
require 'active_record'
require "./mpk_scrapper"
require './sqlite_dumper'
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

DEBUG = true

scrapper = MPKScrapper.new(logger)
scrapper.run
