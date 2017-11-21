require 'open-uri'
require 'uri'
require 'rubygems'
require 'httparty'
require 'fileutils'
require 'mp3info'
require 'pry'

## Multipy by 86400 for each day

class PodcastDownloader
	def initialize
# 		 @show_date=Time.now-86400
# 		 @show_date=@show_date.strftime("%m-%d-%y")
		today = Time.now
		@show_date = today.strftime("%m-%d-%y")
		@download_date = today.strftime("%Y/%m/%Y%m%d")
		@file_path = "/Users/annwatts/Documents/PodcastGetter/ATC"
		# @file_path = "/Users/mberkow/Documents/Develop/podcast_getter/ATC"
	end

	def get_file_names
		# Get list of files
		base_page = open("http://www.npr.org/programs/all-things-considered/").read
		rows = base_page.lines.select { |line| line =~ /https:\/\/ondemand.npr.org\/anon.npr-mp3\/npr\/atc\/#{@download_date}_atc/ }
		files = []
		rows.each do |row|
			files << row[/https(.*?)\.mp3/]
		end
		# Reject bumper music
		files.reject! { |a| a =~ /atc_\d\dm\d.mp3/ }
		files.uniq!
	end

	def get_files
		podcasts = get_file_names
		# base_page = open("http://www.npr.org/programs/all-things-considered/").read
		# podcasts = base_page.lines.reject { |line| line !~ /download/ }
		podcasts.each.with_index do |podcast, i|
			i=sprintf '%02d', i
			address = URI.extract(podcast).first
			Dir.mkdir(@show_date) unless File.exists?(@show_date)

			File.open("#{@show_date}/#{i}_#{@show_date}_podcast.mp3", "wb") do |f|
				begin
					f.write HTTParty.get(address).parsed_response
				rescue => e
					puts e
				end
			end
		end
	end

def combine_files
	file_name = Dir.glob("#{@show_date}/*.mp3")

	Dir.mkdir(@file_path) unless File.exists?(@file_path)

	file_name.each do |file|
		`cat "#{file}" >> "#{@file_path}/#{@show_date}_podcast.mp3"`
	end
end

def add_podcast_tags
	Mp3Info.open("#{@file_path}/#{@show_date}_podcast.mp3") do |mp3info|
		mp3info.tag.title = ''
		mp3info.tag.artist = ''
		mp3info.tag.album = ''
		mp3info.tag.year = nil
		mp3info.tag.genre = nil
		mp3info.tag.TCO = 'Podcast'
		mp3info.tag2.TIT2 = "#{@show_date}_podcast"
		mp3info.tag2.TALB = 'All Things Considered'
		mp3info.tag.genre_s = 'Podcast'
		mp3info.tag2.TDRC = Time.now.year
		mp3info.tag2.TDRL = Time.now.utc#-86400
		mp3info.tag2.COMM = "0"
		mp3info.tag2.PCST = "\x00\x00\x00\x00"
		mp3info.tag2.TGID = "http://127.0.0.1/#{@show_date}_podcast"
		mp3info.tag2.WFED = "\x00All Things Considered\x00"
		mp3info.tag2.TCOP = Time.now.utc#-86400
		mp3info.tag2.TYER = Time.now.year
	end
end

def move_file_to_import_folder
	FileUtils.mv("#{@file_path}/#{@show_date}_podcast.mp3", "/Users/annwatts/Music/iTunes/iTunes\ Music/Automatically\ Add\ to\ iTunes/#{@show_date}_podcast.mp3")
end

	def clean_up
		FileUtils.rm_rf(@show_date)
	end

	def download_and_concatenate
		get_file_names
		get_files
		combine_files
		sleep(1)
		add_podcast_tags
		move_file_to_import_folder
		sleep(1)
		clean_up
	end
end

	run_it = PodcastDownloader.new
	run_it.download_and_concatenate