#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <phk@FreeBSD.ORG> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Buras Arkadiusz
# ----------------------------------------------------------------------------
#

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
